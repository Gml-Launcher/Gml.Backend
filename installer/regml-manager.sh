#!/bin/sh

DEFAULT_BASE_DIR="/srv/gml"
DEFAULT_VERSION="v2025.3.2"
COMPOSE_URL="https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/docker-compose-prod.yml"

ACTION=""
BASE_DIR=""
VERSION=""
PROMPT_ANSWER=""

# Print command-line usage for both scripted and interactive workflows.
print_usage() {
    cat <<EOF
Usage:
  $0 install --version <version> [--dir <path>]
  $0 update --version <version> [--dir <path>]
  $0 delete [--dir <path>]
  $0

Commands:
  install    Install Gml.Backend
  update     Update Gml.Backend
  delete     Stop containers and move the install directory to a backup

Options:
  --version  Docker image version tag. Used by install and update.
  --dir      Installation directory. Defaults to $DEFAULT_BASE_DIR.
  -h, --help Show this help.
EOF
}

# Stop immediately with a consistent error prefix.
error() {
    echo "[Gml] Error: $*" >&2
    exit 1
}

# Validate that an option expecting a value actually received one.
require_value() {
    option="$1"
    value="${2:-}"

    if [ -z "$value" ]; then
        error "$option requires a value"
    fi
}

# Parse the optional command and flags before any privileged work starts.
parse_args() {
    if [ "$#" -eq 0 ]; then
        return 0
    fi

    case "$1" in
        install|update|delete)
            ACTION="$1"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            error "Unknown command: $1"
            ;;
    esac

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --version)
                require_value "$1" "${2:-}"
                VERSION="$2"
                shift 2
                ;;
            --dir)
                require_value "$1" "${2:-}"
                BASE_DIR="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                error "Unknown argument: $1"
                ;;
        esac
    done
}

# Read an answer from the terminal even when the script body is piped through stdin.
read_prompt_answer() {
    PROMPT_ANSWER=""

    if [ -e /dev/tty ] && { IFS= read -r PROMPT_ANSWER < /dev/tty; } 2>/dev/null; then
        return 0
    fi

    if [ -t 0 ]; then
        IFS= read -r PROMPT_ANSWER || PROMPT_ANSWER=""
    fi
}

# Read a value while keeping a safe default for empty input.
prompt_with_default() {
    prompt="$1"
    default="$2"

    printf "%s [%s]: " "$prompt" "$default" >&2
    read_prompt_answer

    if [ -z "$PROMPT_ANSWER" ]; then
        PROMPT_ANSWER="$default"
    fi
}

# Interactive action selector used when the script is launched without a command.
prompt_action() {
    echo "Select action:" >&2
    echo "  1) install" >&2
    echo "  2) update" >&2
    echo "  3) delete" >&2
    printf "Action [1]: " >&2
    read_prompt_answer

    case "${PROMPT_ANSWER:-1}" in
        1|install)
            ACTION="install"
            ;;
        2|update)
            ACTION="update"
            ;;
        3|delete)
            ACTION="delete"
            ;;
        *)
            error "Unknown action: $PROMPT_ANSWER"
            ;;
    esac
}

# Read a simple KEY=value entry from an existing .env file.
get_env_value() {
    env_file="$1"
    key="$2"

    if [ ! -f "$env_file" ]; then
        return 0
    fi

    sed -n "s/^${key}=//p" "$env_file" | tail -n 1
}

# Resolve missing command-line inputs through interactive prompts.
resolve_inputs() {
    if [ -z "$ACTION" ]; then
        prompt_action
    fi

    if [ -z "$BASE_DIR" ]; then
        prompt_with_default "Installation directory" "$DEFAULT_BASE_DIR"
        BASE_DIR="$PROMPT_ANSWER"
    fi

    case "$ACTION" in
        install|update)
            if [ -z "$VERSION" ]; then
                current_version=$(get_env_value "$BASE_DIR/.env" "GML_VERSION")
                prompt_with_default "Gml version" "${current_version:-$DEFAULT_VERSION}"
                VERSION="$PROMPT_ANSWER"
            fi
            ;;
        delete)
            ;;
        *)
            error "Unknown action: $ACTION"
            ;;
    esac
}

# Root is required because the script installs packages and controls Docker.
require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root"
    fi
}

# Display a lightweight spinner while a background step is running.
show_spinner() {
    pid="$1"
    text="$2"
    delay=0.1

    while kill -0 "$pid" 2>/dev/null; do
        for char in "/" "-" "\\" "|"; do
            printf "\r%s %s" "$text" "$char"
            sleep "$delay"
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
        done
    done

    wait "$pid"
    result="$?"

    if [ "$result" -eq 0 ]; then
        printf "\r%s \033[32m✓\033[0m\n" "$text"
    else
        printf "\r%s \033[31m✗\033[0m\n" "$text"
    fi

    return "$result"
}

# Run one step, capture its log, and abort the whole flow on failure.
run_step() {
    text="$1"
    shift
    log_file=$(mktemp "${TMPDIR:-/tmp}/regml-manager.XXXXXX") || exit 1

    (
        "$@"
    ) >"$log_file" 2>&1 &

    show_spinner "$!" "$text"
    result="$?"

    if [ "$result" -ne 0 ]; then
        echo "[Gml] Step failed: $text (exit code $result)" >&2
        if [ -s "$log_file" ]; then
            echo "[Gml] Last log lines:" >&2
            tail -n 40 "$log_file" >&2
        fi
        rm -f "$log_file"
        exit "$result"
    fi

    rm -f "$log_file"
}

# Avoid interactive package restart prompts on systems with needrestart.
disable_additional_notify() {
    if [ -f /etc/needrestart/needrestart.conf ]; then
        sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
    fi
}

# Record OS information in the step log for easier troubleshooting.
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "OS: ${NAME:-unknown} ${VERSION_ID:-unknown}"
    else
        echo "OS: unknown"
    fi
}

# Detect Alpine because Docker is installed from Alpine packages there.
is_alpine() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        [ "${ID:-}" = "alpine" ]
        return "$?"
    fi

    return 1
}

# Install a package through the first supported package manager found.
install_package() {
    package="$1"

    if command -v apk >/dev/null 2>&1; then
        apk add --no-cache "$package"
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y "$package"
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "$package"
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$package"
    elif command -v zypper >/dev/null 2>&1; then
        zypper install -y "$package"
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm "$package"
    else
        echo "No supported package manager found" >&2
        return 1
    fi
}

# Confirm the Docker Compose plugin exists.
docker_compose_available() {
    docker compose version >/dev/null 2>&1
}

# Ensure a command exists, installing its package when needed.
ensure_command() {
    command_name="$1"
    package_name="$2"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        install_package "$package_name"
    fi
}

# Start Docker across common Linux init systems.
start_docker_service() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl enable --now docker
    elif command -v rc-update >/dev/null 2>&1 && command -v rc-service >/dev/null 2>&1; then
        rc-update add docker default
        rc-service docker start
    elif command -v service >/dev/null 2>&1; then
        service docker start
    fi
}

# Install Docker from Alpine packages, including the Compose plugin.
install_alpine_docker() {
    apk add --no-cache docker docker-cli-compose || return 1
    start_docker_service
}

# Install Docker through the official convenience script and start the service.
install_docker() {
    if command -v docker >/dev/null 2>&1 && docker_compose_available; then
        return 0
    fi

    if is_alpine; then
        install_alpine_docker
    else
        sh -c "$(curl -fsSL https://get.docker.com)"
        start_docker_service
    fi

    docker_compose_available
}

# Create the selected installation directory.
prepare_directory() {
    mkdir -p "$BASE_DIR"
}

# New installations must start from an empty or missing directory.
ensure_install_directory_empty() {
    if [ ! -d "$BASE_DIR" ]; then
        return 0
    fi

    if find "$BASE_DIR" -mindepth 1 -maxdepth 1 | grep -q .; then
        echo "Installation directory is not empty: $BASE_DIR" >&2
        echo "Choose an empty directory or remove the existing contents before installing." >&2
        return 1
    fi
}

# Updates and removals must target an existing installation directory.
ensure_install_directory_exists() {
    if [ ! -d "$BASE_DIR" ]; then
        echo "Installation directory does not exist: $BASE_DIR" >&2
        return 1
    fi
}

# Download the production compose template into the installation directory.
download_compose() {
    mkdir -p "$BASE_DIR"
    cd "$BASE_DIR"
    curl -fsSL "$COMPOSE_URL" -o docker-compose.yml
}

# Generate the SECURITY_KEY value for a new installation.
generate_security_key() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex 32
        return 0
    fi

    echo "openssl is required to generate SECURITY_KEY" >&2
    return 1
}

# Create the initial .env file without overwriting future user changes.
write_default_env() {
    env_file="$BASE_DIR/.env"
    security_key=$(generate_security_key) || return 1

    cat > "$env_file" <<EOF
UID=0
GID=0

GML_VERSION=$VERSION
SECURITY_KEY=$security_key
PROJECT_NAME=GmlBackend
PROJECT_DESCRIPTION=GmlBackend
PROJECT_POLICYNAME=GmlBackendPolicy
PROJECT_PATH=

SWAGGER_ENABLED=false

PORT_GML_BACKEND=5000
PORT_GML_FRONTEND=5003
PORT_GML_FILES=5005
PORT_GML_SKINS=5006

SERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085
MARKET_ENDPOINT=https://gml-market.recloud.tech
EOF
}

# Insert or update one KEY=value entry while preserving all other .env lines.
upsert_env_value() {
    env_file="$1"
    key="$2"
    value="$3"
    tmp_file="${env_file}.tmp.$$"

    if [ ! -f "$env_file" ]; then
        printf "%s=%s\n" "$key" "$value" > "$env_file"
        return 0
    fi

    awk -v key="$key" -v value="$value" '
        BEGIN { found = 0 }
        $0 ~ "^" key "=" {
            print key "=" value
            found = 1
            next
        }
        { print }
        END {
            if (found == 0) {
                print key "=" value
            }
        }
    ' "$env_file" > "$tmp_file"

    mv "$tmp_file" "$env_file"
}

# Create .env on first install or only update GML_VERSION afterwards.
ensure_env() {
    if [ ! -f "$BASE_DIR/.env" ]; then
        write_default_env
        return 0
    fi

    upsert_env_value "$BASE_DIR/.env" "GML_VERSION" "$VERSION"
}

# Docker Compose wrappers keep each operation as an isolated run_step target.
docker_compose_up() {
    cd "$BASE_DIR"
    docker compose up -d
}

docker_compose_down() {
    cd "$BASE_DIR"
    docker compose down
}

docker_compose_down_images() {
    cd "$BASE_DIR"
    docker compose down --rmi all
}

docker_compose_down_volumes() {
    cd "$BASE_DIR"
    docker compose down -v
}

# Keep removed installations recoverable by moving the directory aside.
backup_install_directory() {
    timestamp=$(date +%Y%m%d_%H%M%S)
    parent_dir=$(dirname "$BASE_DIR")
    base_name=$(basename "$BASE_DIR")

    mv "$BASE_DIR" "$parent_dir/${base_name}_backup_$timestamp"
}

# Show reachable admin panel URLs after install or update.
write_success_message() {
    port=5003
    ip_list=""

    if command -v ip >/dev/null 2>&1; then
        ip_list=$(ip -4 -o addr show up | awk '!/ lo / && !/docker|br-|veth/ {print $4}' | cut -d/ -f1 | sort -u)
    else
        ip_list=$(hostname -I 2>/dev/null)
    fi

    if [ -z "$ip_list" ] && [ -n "${SSH_CONNECTION:-}" ]; then
        ip_list=$(echo "$SSH_CONNECTION" | awk '{print $3}')
    fi

    echo
    printf "\033[32m==================================================\033[0m\n"
    printf "\033[32mGml.Backend is ready\033[0m\n"
    printf "\033[32m==================================================\033[0m\n"
    echo "Admin panel:"

    for ip in $ip_list; do
        [ -n "$ip" ] && echo " - http://$ip:$port/"
    done
}

# Confirm that delete finished and the directory was backed up.
write_delete_message() {
    echo
    printf "\033[32m==================================================\033[0m\n"
    printf "\033[32mGml.Backend was removed and backed up\033[0m\n"
    printf "\033[32m==================================================\033[0m\n"
}

# Full installation flow. Every step must succeed before the next starts.
run_install() {
    run_step "[Gml] Detecting operating system" detect_os
    run_step "[Gml] Preparing operating system" disable_additional_notify
    run_step "[Gml] Installing curl" ensure_command curl curl
    run_step "[Gml] Installing openssl" ensure_command openssl openssl
    run_step "[Gml] Installing Docker" install_docker
    run_step "[Gml] Checking installation directory is empty" ensure_install_directory_empty
    run_step "[Gml] Creating installation directory" prepare_directory
    run_step "[Gml] Downloading docker-compose.yml" download_compose
    run_step "[Gml] Creating or updating .env" ensure_env
    run_step "[Gml] Starting docker compose" docker_compose_up
    write_success_message
}

# Update the compose file, version variable, images, and running containers.
run_update() {
    run_step "[Gml] Checking installation directory" ensure_install_directory_exists
    run_step "[Gml] Installing curl" ensure_command curl curl
    run_step "[Gml] Downloading docker-compose.yml" download_compose
    run_step "[Gml] Creating or updating .env" ensure_env
    run_step "[Gml] Stopping docker compose" docker_compose_down
    run_step "[Gml] Removing Docker images" docker_compose_down_images
    run_step "[Gml] Starting docker compose" docker_compose_up
    write_success_message
}

# Stop the stack, remove compose-managed resources, and back up the directory.
run_delete() {
    run_step "[Gml] Checking installation directory" ensure_install_directory_exists
    run_step "[Gml] Stopping docker compose and volumes" docker_compose_down_volumes
    run_step "[Gml] Removing Docker images" docker_compose_down_images
    run_step "[Gml] Backing up installation directory" backup_install_directory
    write_delete_message
}

# Entrypoint: parse, validate privileges, resolve prompts, then dispatch.
main() {
    parse_args "$@"
    require_root
    resolve_inputs

    case "$ACTION" in
        install)
            run_install
            ;;
        update)
            run_update
            ;;
        delete)
            run_delete
            ;;
        *)
            error "Unknown action: $ACTION"
            ;;
    esac
}

if [ "${GML_MANAGER_SKIP_MAIN:-0}" != "1" ]; then
    main "$@"
fi
