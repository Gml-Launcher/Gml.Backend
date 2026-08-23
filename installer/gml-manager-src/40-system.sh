# Root is required because the script installs packages and controls Docker.
require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "$(message root_required)"
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
    log_file=$(mktemp "${TMPDIR:-/tmp}/gml-manager.XXXXXX") || exit 1

    (
        "$@"
    ) >"$log_file" 2>&1 &

    show_spinner "$!" "$text"
    result="$?"

    if [ "$result" -ne 0 ]; then
        message step_failed "$text" "$result" >&2
        if [ -s "$log_file" ]; then
            message last_log_lines >&2
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
        message no_package_manager >&2
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

# Install the package that provides ss on the detected distribution.
ensure_socket_tools() {
    command -v ss >/dev/null 2>&1 && return 0

    if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
        install_package iproute
    else
        install_package iproute2
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


