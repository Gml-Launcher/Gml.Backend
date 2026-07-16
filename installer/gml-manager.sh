#!/bin/sh

DEFAULT_BASE_DIR="/srv/gml"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-Gml-Launcher/Gml.Backend}"
COMPOSE_URL="${COMPOSE_URL:-https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/master/docker-compose-installer.yml}"
ENV_URL="${ENV_URL:-https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/master/installer/installer.env}"
DEFAULT_TAGS_URL="https://api.github.com/repos/$GITHUB_REPOSITORY/tags?per_page=100"

SCRIPT_DIR=""
if [ -f "$0" ]; then
    SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
fi

ACTION=""
BASE_DIR=""
VERSION=""
PROMPT_ANSWER=""
INTERACTIVE_MODE=0
SHOW_HELP=0
GML_MANAGER_LANGUAGE="en"

# Return a localized message format. English is the fallback for missing keys.
message_format() {
    language="$1"
    key="$2"

    if [ "$language" = "ru" ]; then
        case "$key" in
            usage_heading) printf '%s' 'Использование:\n' ;;
            usage_install) printf '%s' '  %s install [--version <версия>] [--dir <путь>] [--lang <ru|en>]\n' ;;
            usage_update) printf '%s' '  %s update [--version <версия>] [--dir <путь>] [--lang <ru|en>]\n' ;;
            usage_delete) printf '%s' '  %s delete [--dir <путь>] [--lang <ru|en>]\n' ;;
            usage_interactive) printf '%s' '  %s [--lang <ru|en>]\n' ;;
            commands_heading) printf '%s' 'Команды:\n' ;;
            command_install) printf '%s' '  install    Установить Gml.Backend\n' ;;
            command_update) printf '%s' '  update     Обновить Gml.Backend\n' ;;
            command_delete) printf '%s' '  delete     Остановить контейнеры и переместить каталог установки в резервную копию\n' ;;
            options_heading) printf '%s' 'Параметры:\n' ;;
            option_version) printf '%s' '  --version  Переопределить тег версии Docker-образа. Используется для install и update.\n' ;;
            option_dir) printf '%s' '  --dir      Каталог установки. По умолчанию: %s.\n' ;;
            option_lang) printf '%s' '  --lang     Язык интерфейса: ru или en. По умолчанию определяется по локали системы.\n' ;;
            option_help) printf '%s' '  -h, --help Показать эту справку.\n' ;;
            error_prefix) printf '%s' '[Gml] Ошибка: %s\n' ;;
            option_requires_value) printf '%s' 'Для параметра %s требуется значение' ;;
            unsupported_language) printf '%s' 'Неподдерживаемый язык: %s. Доступные языки: ru, en' ;;
            unknown_command) printf '%s' 'Неизвестная команда: %s' ;;
            unknown_argument) printf '%s' 'Неизвестный аргумент: %s' ;;
            unknown_action) printf '%s' 'Неизвестное действие: %s' ;;
            no_stable_tags) printf '%s' 'По адресу %s не найдены теги стабильных версий\n' ;;
            action_menu) printf '%b' 'Выберите действие:\n  1) установить\n  2) обновить\n  3) удалить\n' ;;
            action_prompt) printf '%s' 'Действие [1]: ' ;;
            installation_directory) printf '%s' 'Каталог установки' ;;
            gml_version) printf '%s' 'Версия Gml' ;;
            latest_version_error) printf '%s' 'Не удалось определить последнюю стабильную версию на GitHub. Передайте --version, чтобы использовать конкретную версию.' ;;
            using_latest_version) printf '%s' '[Gml] Используется последняя стабильная версия: %s\n' ;;
            root_required) printf '%s' 'Этот скрипт необходимо запустить от имени root' ;;
            step_failed) printf '%s' '[Gml] Шаг завершился с ошибкой: %s (код выхода %s)\n' ;;
            last_log_lines) printf '%s' '[Gml] Последние строки журнала:\n' ;;
            no_package_manager) printf '%s' 'Не найден поддерживаемый менеджер пакетов\n' ;;
            directory_not_empty) printf '%s' 'Каталог установки не пуст: %s\n' ;;
            choose_empty_directory) printf '%s' 'Выберите пустой каталог или удалите существующее содержимое перед установкой.\n' ;;
            directory_missing) printf '%s' 'Каталог установки не существует: %s\n' ;;
            openssl_required) printf '%s' 'Для создания SECURITY_KEY требуется openssl\n' ;;
            backend_ready) printf '%s' 'Gml.Backend готов к работе' ;;
            admin_panel) printf '%s' 'Панель администратора:' ;;
            backend_removed) printf '%s' 'Gml.Backend удалён, каталог сохранён в резервной копии' ;;
            step_detect_os) printf '%s' '[Gml] Определение операционной системы' ;;
            step_prepare_os) printf '%s' '[Gml] Подготовка операционной системы' ;;
            step_install_curl) printf '%s' '[Gml] Установка curl' ;;
            step_install_openssl) printf '%s' '[Gml] Установка openssl' ;;
            step_install_docker) printf '%s' '[Gml] Установка Docker' ;;
            step_check_empty_directory) printf '%s' '[Gml] Проверка, что каталог установки пуст' ;;
            step_check_directory) printf '%s' '[Gml] Проверка каталога установки' ;;
            step_create_directory) printf '%s' '[Gml] Создание каталога установки' ;;
            step_download_compose) printf '%s' '[Gml] Загрузка docker-compose.yml' ;;
            step_update_env) printf '%s' '[Gml] Создание или обновление .env' ;;
            step_start_compose) printf '%s' '[Gml] Запуск docker compose' ;;
            step_stop_compose) printf '%s' '[Gml] Остановка docker compose' ;;
            step_stop_compose_volumes) printf '%s' '[Gml] Остановка docker compose и удаление томов' ;;
            step_remove_images) printf '%s' '[Gml] Удаление Docker-образов' ;;
            step_backup_directory) printf '%s' '[Gml] Создание резервной копии каталога установки' ;;
            *) message_format "en" "$key" ;;
        esac
        return
    fi

    case "$key" in
        usage_heading) printf '%s' 'Usage:\n' ;;
        usage_install) printf '%s' '  %s install [--version <version>] [--dir <path>] [--lang <ru|en>]\n' ;;
        usage_update) printf '%s' '  %s update [--version <version>] [--dir <path>] [--lang <ru|en>]\n' ;;
        usage_delete) printf '%s' '  %s delete [--dir <path>] [--lang <ru|en>]\n' ;;
        usage_interactive) printf '%s' '  %s [--lang <ru|en>]\n' ;;
        commands_heading) printf '%s' 'Commands:\n' ;;
        command_install) printf '%s' '  install    Install Gml.Backend\n' ;;
        command_update) printf '%s' '  update     Update Gml.Backend\n' ;;
        command_delete) printf '%s' '  delete     Stop containers and move the install directory to a backup\n' ;;
        options_heading) printf '%s' 'Options:\n' ;;
        option_version) printf '%s' '  --version  Override Docker image version tag. Used by install and update.\n' ;;
        option_dir) printf '%s' '  --dir      Installation directory. Defaults to %s.\n' ;;
        option_lang) printf '%s' '  --lang     Interface language: ru or en. Defaults to the system locale.\n' ;;
        option_help) printf '%s' '  -h, --help Show this help.\n' ;;
        error_prefix) printf '%s' '[Gml] Error: %s\n' ;;
        option_requires_value) printf '%s' '%s requires a value' ;;
        unsupported_language) printf '%s' 'Unsupported language: %s. Available languages: ru, en' ;;
        unknown_command) printf '%s' 'Unknown command: %s' ;;
        unknown_argument) printf '%s' 'Unknown argument: %s' ;;
        unknown_action) printf '%s' 'Unknown action: %s' ;;
        no_stable_tags) printf '%s' 'No stable version tags found at %s\n' ;;
        action_menu) printf '%b' 'Select action:\n  1) install\n  2) update\n  3) delete\n' ;;
        action_prompt) printf '%s' 'Action [1]: ' ;;
        installation_directory) printf '%s' 'Installation directory' ;;
        gml_version) printf '%s' 'Gml version' ;;
        latest_version_error) printf '%s' 'Unable to resolve the latest stable version from GitHub. Pass --version to use a specific version.' ;;
        using_latest_version) printf '%s' '[Gml] Using latest stable version: %s\n' ;;
        root_required) printf '%s' 'This script must be run as root' ;;
        step_failed) printf '%s' '[Gml] Step failed: %s (exit code %s)\n' ;;
        last_log_lines) printf '%s' '[Gml] Last log lines:\n' ;;
        no_package_manager) printf '%s' 'No supported package manager found\n' ;;
        directory_not_empty) printf '%s' 'Installation directory is not empty: %s\n' ;;
        choose_empty_directory) printf '%s' 'Choose an empty directory or remove the existing contents before installing.\n' ;;
        directory_missing) printf '%s' 'Installation directory does not exist: %s\n' ;;
        openssl_required) printf '%s' 'openssl is required to generate SECURITY_KEY\n' ;;
        backend_ready) printf '%s' 'Gml.Backend is ready' ;;
        admin_panel) printf '%s' 'Admin panel:' ;;
        backend_removed) printf '%s' 'Gml.Backend was removed and backed up' ;;
        step_detect_os) printf '%s' '[Gml] Detecting operating system' ;;
        step_prepare_os) printf '%s' '[Gml] Preparing operating system' ;;
        step_install_curl) printf '%s' '[Gml] Installing curl' ;;
        step_install_openssl) printf '%s' '[Gml] Installing openssl' ;;
        step_install_docker) printf '%s' '[Gml] Installing Docker' ;;
        step_check_empty_directory) printf '%s' '[Gml] Checking installation directory is empty' ;;
        step_check_directory) printf '%s' '[Gml] Checking installation directory' ;;
        step_create_directory) printf '%s' '[Gml] Creating installation directory' ;;
        step_download_compose) printf '%s' '[Gml] Downloading docker-compose.yml' ;;
        step_update_env) printf '%s' '[Gml] Creating or updating .env' ;;
        step_start_compose) printf '%s' '[Gml] Starting docker compose' ;;
        step_stop_compose) printf '%s' '[Gml] Stopping docker compose' ;;
        step_stop_compose_volumes) printf '%s' '[Gml] Stopping docker compose and volumes' ;;
        step_remove_images) printf '%s' '[Gml] Removing Docker images' ;;
        step_backup_directory) printf '%s' '[Gml] Backing up installation directory' ;;
        *) printf '%s' "$key" ;;
    esac
}

# Print a translated message using the selected language and optional arguments.
message() {
    key="$1"
    shift
    # The sentinel preserves trailing newlines that command substitution removes.
    format=$(message_format "$GML_MANAGER_LANGUAGE" "$key"; printf '_')
    format=${format%_}
    # shellcheck disable=SC2059 -- the format comes from the built-in dictionary.
    printf "$format" "$@"
}

# Set one of the explicitly supported interface languages.
set_language() {
    case "$1" in
        ru|en)
            GML_MANAGER_LANGUAGE="$1"
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Pick a language from the highest-priority locale environment variable.
set_language_from_environment() {
    locale_name=${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}

    case "$locale_name" in
        ru|ru_*|ru.*|ru-*) GML_MANAGER_LANGUAGE="ru" ;;
        *) GML_MANAGER_LANGUAGE="en" ;;
    esac
}

# Pre-scan arguments so --lang affects help and argument parsing errors.
detect_language() {
    requested_language=""

    while [ "$#" -gt 0 ]; do
        if [ "$1" = "--lang" ] && [ "$#" -gt 1 ]; then
            requested_language="$2"
            shift 2
        else
            shift
        fi
    done

    if [ -n "$requested_language" ] && set_language "$requested_language"; then
        return 0
    fi

    set_language_from_environment
}

# Print the GML Manager banner when the script starts.
print_banner() {
    cat <<'EOF'

 ██████╗ ███╗   ███╗██╗         ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗ 
██╔════╝ ████╗ ████║██║         ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
██║  ███╗██╔████╔██║██║         ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
██║   ██║██║╚██╔╝██║██║         ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
╚██████╔╝██║ ╚═╝ ██║███████╗    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
 ╚═════╝ ╚═╝     ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                                                               
EOF
}

# Print command-line usage for both scripted and interactive workflows.
print_usage() {
    message usage_heading
    message usage_install "$0"
    message usage_update "$0"
    message usage_delete "$0"
    message usage_interactive "$0"
    printf '\n'
    message commands_heading
    message command_install
    message command_update
    message command_delete
    printf '\n'
    message options_heading
    message option_version
    message option_dir "$DEFAULT_BASE_DIR"
    message option_lang
    message option_help
}

# Stop immediately with a consistent error prefix.
error() {
    message error_prefix "$*" >&2
    exit 1
}

# Validate that an option expecting a value actually received one.
require_value() {
    option="$1"
    value="${2:-}"

    if [ -z "$value" ]; then
        error "$(message option_requires_value "$option")"
    fi
}

# Parse the optional command and flags before any privileged work starts.
parse_args() {
    if [ "$#" -eq 0 ]; then
        INTERACTIVE_MODE=1
        return 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            install)
                if [ -n "$ACTION" ]; then
                    error "$(message unknown_argument "$1")"
                fi
                ACTION="install"
                shift
                ;;
            update)
                if [ -n "$ACTION" ]; then
                    error "$(message unknown_argument "$1")"
                fi
                ACTION="update"
                shift
                ;;
            delete)
                if [ -n "$ACTION" ]; then
                    error "$(message unknown_argument "$1")"
                fi
                ACTION="delete"
                shift
                ;;
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
            --lang)
                require_value "$1" "${2:-}"
                if ! set_language "$2"; then
                    error "$(message unsupported_language "$2")"
                fi
                shift 2
                ;;
            -h|--help)
                SHOW_HELP=1
                shift
                ;;
            *)
                if [ -z "$ACTION" ]; then
                    error "$(message unknown_command "$1")"
                fi
                error "$(message unknown_argument "$1")"
                ;;
        esac
    done

    if [ "$SHOW_HELP" -eq 1 ]; then
        print_usage
        exit 0
    fi

    if [ -z "$ACTION" ]; then
        INTERACTIVE_MODE=1
    fi
}

# Extract the greatest stable numeric tag (vN.N[.N...]) from GitHub tags JSON.
extract_latest_stable_tag() {
    sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | awk '
        {
            tag = $0

            if (tag !~ /^v/) {
                next
            }

            version = tag
            sub(/^v/, "", version)
            part_count = split(version, parts, ".")

            if (part_count < 2) {
                next
            }

            valid = 1
            for (i = 1; i <= part_count; i++) {
                if (parts[i] !~ /^[0-9][0-9]*$/) {
                    valid = 0
                }
            }

            if (valid == 0) {
                next
            }

            is_better = 0

            if (found == 0) {
                is_better = 1
            } else {
                max_part_count = part_count > best_part_count ? part_count : best_part_count

                for (i = 1; i <= max_part_count; i++) {
                    current_part = i <= part_count ? parts[i] + 0 : 0
                    best_part = i <= best_part_count ? best_parts[i] : 0

                    if (current_part > best_part) {
                        is_better = 1
                        break
                    }

                    if (current_part < best_part) {
                        break
                    }

                    if (i == max_part_count && part_count > best_part_count) {
                        is_better = 1
                    }
                }
            }

            if (is_better == 1) {
                found = 1
                best_tag = tag
                best_part_count = part_count

                for (i = 1; i <= best_part_count; i++) {
                    delete best_parts[i]
                }
                for (i = 1; i <= part_count; i++) {
                    best_parts[i] = parts[i] + 0
                }
            }
        }
        END {
            if (found == 1) {
                print best_tag
            } else {
                exit 1
            }
        }
    '
}

# Fetch the latest stable release tag from GitHub, or from an override URL in tests.
fetch_latest_stable_version() {
    tags_url="${GML_MANAGER_TAGS_URL:-$DEFAULT_TAGS_URL}"
    latest_version=$(curl -fsSL "$tags_url" | extract_latest_stable_tag)

    if [ -z "$latest_version" ]; then
        message no_stable_tags "$tags_url" >&2
        return 1
    fi

    printf "%s\n" "$latest_version"
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
    message action_menu >&2
    message action_prompt >&2
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
            error "$(message unknown_action "$PROMPT_ANSWER")"
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

# Resolve missing action and directory inputs through interactive prompts.
resolve_action_and_base_dir() {
    if [ -z "$ACTION" ]; then
        prompt_action
    fi

    if [ -z "$BASE_DIR" ]; then
        prompt_with_default "$(message installation_directory)" "$DEFAULT_BASE_DIR"
        BASE_DIR="$PROMPT_ANSWER"
    fi
}

# Resolve the version through GitHub unless the user provided an explicit override.
resolve_version_input() {
    case "$ACTION" in
        install|update)
            if [ -z "$VERSION" ]; then
                latest_version=$(fetch_latest_stable_version) || error "$(message latest_version_error)"

                if [ "$INTERACTIVE_MODE" -eq 1 ]; then
                    prompt_with_default "$(message gml_version)" "$latest_version"
                    VERSION="$PROMPT_ANSWER"
                else
                    VERSION="$latest_version"
                    message using_latest_version "$VERSION" >&2
                fi
            fi
            ;;
        delete)
            ;;
        *)
            error "$(message unknown_action "$ACTION")"
            ;;
    esac
}

# Resolve missing command-line inputs.
resolve_inputs() {
    resolve_action_and_base_dir
    resolve_version_input
}

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
        message directory_not_empty "$BASE_DIR" >&2
        message choose_empty_directory >&2
        return 1
    fi
}

# Updates and removals must target an existing installation directory.
ensure_install_directory_exists() {
    if [ ! -d "$BASE_DIR" ]; then
        message directory_missing "$BASE_DIR" >&2
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

    message openssl_required >&2
    return 1
}

# Copy the bundled .env template, or download it when this script is piped to sh.
copy_env_template() {
    env_file="$1"

    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/installer.env" ]; then
        cp "$SCRIPT_DIR/installer.env" "$env_file"
        return 0
    fi

    curl -fsSL "$ENV_URL" -o "$env_file"
}

# Create the initial .env file without overwriting future user changes.
write_default_env() {
    env_file="$BASE_DIR/.env"
    security_key=$(generate_security_key) || return 1

    copy_env_template "$env_file" || return 1
    upsert_env_value "$env_file" "GML_VERSION" "$VERSION"
    upsert_env_value "$env_file" "SECURITY_KEY" "$security_key"
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
    port=$(get_env_value "$BASE_DIR/.env" "PORT_GML_FRONTEND")
    port=${port:-5003}
    ip_list=""

    if command -v ip >/dev/null 2>&1; then
        ip_list=$(ip -4 -o addr show up | awk '!/ lo / && !/docker|br-|veth/ {print $4}' | cut -d/ -f1 | sort -u)
    fi

    # Some containers expose `ip`, but it returns no matching addresses.
    if [ -z "$ip_list" ] && command -v hostname >/dev/null 2>&1; then
        ip_list=$(hostname -I 2>/dev/null)
    fi

    if [ -z "$ip_list" ] && [ -n "${SSH_CONNECTION:-}" ]; then
        ip_list=$(echo "$SSH_CONNECTION" | awk '{print $3}')
    fi

    # Always print at least an address that is reachable from the host itself.
    ip_list=${ip_list:-127.0.0.1}

    echo
    printf "\033[32m==================================================\033[0m\n"
    printf "\033[32m%s\033[0m\n" "$(message backend_ready)"
    printf "\033[32m==================================================\033[0m\n"
    message admin_panel
    printf "\n"

    for ip in $ip_list; do
        [ -n "$ip" ] && echo " - http://$ip:$port/"
    done
}

# Confirm that delete finished and the directory was backed up.
write_delete_message() {
    echo
    printf "\033[32m==================================================\033[0m\n"
    printf "\033[32m%s\033[0m\n" "$(message backend_removed)"
    printf "\033[32m==================================================\033[0m\n"
}

# Full installation flow. Every step must succeed before the next starts.
run_install() {
    run_step "$(message step_detect_os)" detect_os
    run_step "$(message step_prepare_os)" disable_additional_notify
    run_step "$(message step_install_curl)" ensure_command curl curl
    run_step "$(message step_install_openssl)" ensure_command openssl openssl
    run_step "$(message step_install_docker)" install_docker
    run_step "$(message step_check_empty_directory)" ensure_install_directory_empty
    run_step "$(message step_create_directory)" prepare_directory
    run_step "$(message step_download_compose)" download_compose
    run_step "$(message step_update_env)" ensure_env
    run_step "$(message step_start_compose)" docker_compose_up
    write_success_message
}

# Update the compose file, version variable, images, and running containers.
run_update() {
    run_step "$(message step_check_directory)" ensure_install_directory_exists
    run_step "$(message step_install_curl)" ensure_command curl curl
    run_step "$(message step_download_compose)" download_compose
    run_step "$(message step_update_env)" ensure_env
    run_step "$(message step_stop_compose)" docker_compose_down
    run_step "$(message step_remove_images)" docker_compose_down_images
    run_step "$(message step_start_compose)" docker_compose_up
    write_success_message
}

# Stop the stack, remove compose-managed resources, and back up the directory.
run_delete() {
    run_step "$(message step_check_directory)" ensure_install_directory_exists
    run_step "$(message step_stop_compose_volumes)" docker_compose_down_volumes
    run_step "$(message step_remove_images)" docker_compose_down_images
    run_step "$(message step_backup_directory)" backup_install_directory
    write_delete_message
}

# Entrypoint: parse, validate privileges, resolve prompts, then dispatch.
main() {
    detect_language "$@"
    print_banner
    parse_args "$@"
    require_root
    resolve_action_and_base_dir

    case "$ACTION" in
        install|update)
            if [ -z "$VERSION" ]; then
                run_step "$(message step_install_curl)" ensure_command curl curl
            fi
            ;;
    esac

    resolve_version_input

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
            error "$(message unknown_action "$ACTION")"
            ;;
    esac
}

if [ "${GML_MANAGER_SKIP_MAIN:-0}" != "1" ]; then
    main "$@"
fi
