#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

BASE_DIR="/srv/gml"
VERSION=""

# Parse arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --version)
            VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Validate version
if [ -z "$VERSION" ]; then
    echo "Error: --version argument is required."
    exit 1
fi

# Ensure the base directory exists
mkdir -p "$BASE_DIR"

# Function to display a spinner with support for nested tasks
show_spinner() {
    local pid=$1
    local text=$2
    local level=${3:-0} # Default level is 0 if not provided
    local spinstr='/-\|'
    local delay=0.1
    local indent=$(printf "%*s" $((level * 2)) "") # Indentation based on level

    while kill -0 $pid 2>/dev/null; do
        for char in $spinstr; do
            printf "\r%s%s %c" "$indent" "$text" "$char"
            sleep $delay
        done
    done

    wait $pid
    local result=$?

    if [ $result -eq 0 ]; then
        printf "\r%s%s \033[32m✓\033[0m\n" "$indent" "$text"
    else
        printf "\r%s%s \033[31m✗\033[0m\n" "$indent" "$text"
    fi

    return $result
}

# Disable additional notifications
disable_additional_notify() {
    if [ -f /etc/needrestart/needrestart.conf ]; then
        sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
    fi
}

# Detect operating system
detect_os() {
    step=$1
    (
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        fi
    ) &
    show_spinner $! "[Gml] Определение операционной системы $step"
    return $?
}

# Prepare operating system
prepare_os() {
    step=$1
    (
        disable_additional_notify
    ) &
    show_spinner $! "[Gml] Подготовка операционной системы $step"
    return $?
}

# Install a package
install_package() {
    package=$1
    (
        if command -v apt-get >/dev/null; then
            apt-get update >/dev/null 2>&1 && apt-get install -y "$package" >/dev/null 2>&1
        elif command -v dnf >/dev/null; then
            dnf install -y "$package" >/dev/null 2>&1
        elif command -v yum >/dev/null; then
            yum install -y "$package" >/dev/null 2>&1
        elif command -v zypper >/dev/null; then
            zypper install -y "$package" >/dev/null 2>&1
        elif command -v pacman >/dev/null; then
            pacman -Sy --noconfirm "$package" >/dev/null 2>&1
        else
            return 1
        fi
    ) &
    show_spinner $! "[System] Установка $package" 1
    return $?
}

# Install Docker
install_docker() {
    (
        if ! command -v docker >/dev/null; then
            # Install Docker using the official convenience script
            sh -c "$(curl -fsSL https://get.docker.com)" >/dev/null 2>&1

            # Start and enable Docker service if available
            if command -v systemctl >/dev/null; then
                systemctl enable --now docker >/dev/null 2>&1 || true
            else
                service docker start >/dev/null 2>&1 || true
            fi
        fi
    ) &
    show_spinner $! "[Gml] Установка Docker" 1
    return $?
}

# Install Git
install_git() {
    (
        if ! command -v git >/dev/null; then
            install_package git || {
                echo "[Gml] Ошибка установки Git"
                exit 1
            }
        fi
    ) &
    show_spinner $! "[Gml] Установка Git" 1
    return $?
}

# Install Curl
install_curl() {
    (
        if ! command -v curl >/dev/null; then
            install_package curl || {
                echo "[Gml] Ошибка установки Curl"
                exit 1
            }
        fi
    ) &
    show_spinner $! "[Gml] Установка Curl" 1
    return $?
}

# Download and configure the project
download_project() {
    (
        mkdir -p "$BASE_DIR"
        cd "$BASE_DIR" || exit

        # Download docker-compose file
        wget "https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/tags/$VERSION/docker-compose-prod.yml" -O docker-compose.yml >/dev/null 2>&1

        # Replace :master with :$VERSION in docker-compose.yml
        sed -i "s/:master/:$VERSION/g" docker-compose.yml
    ) &
    show_spinner $! "[Gml] Загрузка и настройка проекта" 1
    return $?
}

# Install all required packages
install_packages() {
    step=$1
    (
        install_docker
        install_git
    ) &
    show_spinner $! "[Gml] Установка пакетов $step"
    return $?
}

# Startup function to run docker compose
startup() {
    (
        cd "$BASE_DIR" || exit
        docker compose down
        docker compose down --rmi all
        docker compose up -d
    ) &
    show_spinner $! "[Gml] Запуск docker compose"
    return $?
}

write_message() {
    local server_ip=$(echo $SSH_CONNECTION | awk '{print $3}') # Извлекаем IP сервера
    echo
    echo
    printf "\033[32m==================================================\033[0m\n"
    printf "\033[32mПроект успешно установлен:\033[0m\n"
    printf "\033[32m==================================================\033[0m\n"
    echo "Админпанель: http://$server_ip:5003/"
}

# Main script execution
detect_os
prepare_os
install_packages
download_project
startup
write_message

