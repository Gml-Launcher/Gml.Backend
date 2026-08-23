# Return a localized message format. English is the fallback for missing keys.
message_format() {
    language="$1"
    key="$2"

    if [ "$language" = "ru" ]; then
        case "$key" in
            usage_heading) printf '%s' 'Использование:\n' ;;
            usage_install) printf '%s' '  %s install [--version <версия>] [--dir <путь>] [--proxy-mode <external|global>] [--domain <домен>] [--accept-acme-terms] [--lang <ru|en>]\n' ;;
            usage_update) printf '%s' '  %s update [--version <версия>] [--dir <путь>] [--proxy-mode <external|global>] [--domain <домен>] [--accept-acme-terms] [--lang <ru|en>]\n' ;;
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
            option_proxy_mode) printf '%s' '  --proxy-mode Режим прокси: external (за другим прокси) или global (публичные 80/443 и Let’s Encrypt).\n' ;;
            option_domain) printf '%s' '  --domain   Публичный домен для прокси режима global.\n' ;;
            option_acme_terms) printf '%s' '  --accept-acme-terms Подтвердить условия Let’s Encrypt для прокси режима global.\n' ;;
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
            proxy_mode_menu) printf '%b' 'Режим прокси:\n  1) external - за существующим прокси\n  2) global - GML будет единственным сервисом на этом сервере и займёт порты 80/443, но автоматически настроит HTTPS и сертификаты\n' ;;
            proxy_mode_prompt) printf '%s' 'Режим прокси' ;;
            proxy_domain_prompt) printf '%s' 'Публичный домен для панели' ;;
            acme_terms_prompt) printf '%s' 'Вы принимаете условия Let’s Encrypt? [y/N]: ' ;;
            invalid_proxy_mode) printf '%s' 'Неподдерживаемый режим прокси: %s. Допустимы external и global' ;;
            invalid_domain) printf '%s' 'Некорректный домен: %s. Укажите один FQDN без схемы (http[s]://), пути и порта' ;;
            invalid_port) printf '%s' 'Некорректный HTTP-порт прокси: %s. Допустимы значения от 1 до 65535' ;;
            domain_required) printf '%s' 'Для режима global требуется --domain' ;;
            acme_terms_required) printf '%s' 'Для включения режима global подтвердите условия Let’s Encrypt через --accept-acme-terms' ;;
            latest_version_error) printf '%s' 'Не удалось определить последнюю стабильную версию на GitHub. Передайте --version, чтобы использовать конкретную версию.' ;;
            using_latest_version) printf '%s' '[Gml] Используется последняя стабильная версия: %s\n' ;;
            root_required) printf '%s' 'Этот скрипт необходимо запустить от имени root' ;;
            step_failed) printf '%s' '[Gml] Шаг завершился с ошибкой: %s (код выхода %s)\n' ;;
            last_log_lines) printf '%s' '[Gml] Последние строки журнала:\n' ;;
            no_package_manager) printf '%s' 'Не найден поддерживаемый менеджер пакетов\n' ;;
            directory_not_empty) printf '%s' 'Каталог установки не пуст: %s\n' ;;
            choose_empty_directory) printf '%s' 'Выберите пустой каталог или удалите существующее содержимое перед установкой.\n' ;;
            directory_missing) printf '%s' 'Каталог установки не существует: %s\n' ;;
            compose_overwrite_warning) printf '%s' '[Gml] Внимание: docker-compose.yml будет заменён актуальным шаблоном, а ручные изменения в этом файле будут потеряны. Вы готовы продолжить обновление? [y/N]: ' ;;
            update_cancelled) printf '%s' '[Gml] Обновление отменено. Файлы не изменены.\n' ;;
            openssl_required) printf '%s' 'Для создания SECURITY_KEY требуется openssl\n' ;;
            backend_ready) printf '%s' 'Gml.Backend готов к работе' ;;
            admin_panel) printf '%s' 'Панель администратора:' ;;
            backend_removed) printf '%s' 'Gml.Backend удалён, каталог сохранён в резервной копии' ;;
            step_detect_os) printf '%s' '[Gml] Определение операционной системы' ;;
            step_prepare_os) printf '%s' '[Gml] Подготовка операционной системы' ;;
            step_install_curl) printf '%s' '[Gml] Установка curl' ;;
            step_install_openssl) printf '%s' '[Gml] Установка openssl' ;;
            step_install_docker) printf '%s' '[Gml] Установка Docker' ;;
            step_install_network_tools) printf '%s' '[Gml] Установка сетевых инструментов' ;;
            step_check_proxy) printf '%s' '[Gml] Проверка домена и портов прокси' ;;
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
        usage_install) printf '%s' '  %s install [--version <version>] [--dir <path>] [--proxy-mode <external|global>] [--domain <domain>] [--accept-acme-terms] [--lang <ru|en>]\n' ;;
        usage_update) printf '%s' '  %s update [--version <version>] [--dir <path>] [--proxy-mode <external|global>] [--domain <domain>] [--accept-acme-terms] [--lang <ru|en>]\n' ;;
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
        option_proxy_mode) printf '%s' '  --proxy-mode Proxy mode: external (behind another proxy) or global (public ports 80/443 and Let’s Encrypt).\n' ;;
        option_domain) printf '%s' '  --domain   Public domain for global mode.\n' ;;
        option_acme_terms) printf '%s' '  --accept-acme-terms Accept the Let’s Encrypt terms when enabling global non-interactively.\n' ;;
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
        proxy_mode_menu) printf '%b' 'Proxy mode:\n  1) external - behind an existing proxy\n  2) global - GML will be the sole service on this server, utilizing ports 80/443, but it will set up HTTPS and certificates automatically\n' ;;
        proxy_mode_prompt) printf '%s' 'Proxy mode' ;;
        proxy_domain_prompt) printf '%s' 'Public domain for panel' ;;
        acme_terms_prompt) printf '%s' 'Do you accept the Let’s Encrypt terms? [y/N]: ' ;;
        invalid_proxy_mode) printf '%s' 'Unsupported proxy mode: %s. Use external or global' ;;
        invalid_domain) printf '%s' 'Invalid domain: %s. Specify one regular FQDN without a scheme (http[s]://), path or port' ;;
        invalid_port) printf '%s' 'Invalid proxy HTTP port: %s. Use a value from 1 to 65535' ;;
        domain_required) printf '%s' 'Global mode requires --domain' ;;
        acme_terms_required) printf '%s' 'To enable global mode, accept the Let’s Encrypt terms with --accept-acme-terms' ;;
        latest_version_error) printf '%s' 'Unable to resolve the latest stable version from GitHub. Pass --version to use a specific version.' ;;
        using_latest_version) printf '%s' '[Gml] Using latest stable version: %s\n' ;;
        root_required) printf '%s' 'This script must be run as root' ;;
        step_failed) printf '%s' '[Gml] Step failed: %s (exit code %s)\n' ;;
        last_log_lines) printf '%s' '[Gml] Last log lines:\n' ;;
        no_package_manager) printf '%s' 'No supported package manager found\n' ;;
        directory_not_empty) printf '%s' 'Installation directory is not empty: %s\n' ;;
        choose_empty_directory) printf '%s' 'Choose an empty directory or remove the existing contents before installing.\n' ;;
        directory_missing) printf '%s' 'Installation directory does not exist: %s\n' ;;
        compose_overwrite_warning) printf '%s' '[Gml] Warning: docker-compose.yml will be replaced with the current template, and manual changes in this file will be lost. Are you ready to continue with the update? [y/N]: ' ;;
        update_cancelled) printf '%s' '[Gml] Update cancelled. No files were changed.\n' ;;
        openssl_required) printf '%s' 'openssl is required to generate SECURITY_KEY\n' ;;
        backend_ready) printf '%s' 'Gml.Backend is ready' ;;
        admin_panel) printf '%s' 'Admin panel:' ;;
        backend_removed) printf '%s' 'Gml.Backend was removed and backed up' ;;
        step_detect_os) printf '%s' '[Gml] Detecting operating system' ;;
        step_prepare_os) printf '%s' '[Gml] Preparing operating system' ;;
        step_install_curl) printf '%s' '[Gml] Installing curl' ;;
        step_install_openssl) printf '%s' '[Gml] Installing openssl' ;;
        step_install_docker) printf '%s' '[Gml] Installing Docker' ;;
        step_install_network_tools) printf '%s' '[Gml] Installing network tools' ;;
        step_check_proxy) printf '%s' '[Gml] Checking proxy domain and ports' ;;
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
    message option_proxy_mode
    message option_domain
    message option_acme_terms
    message option_lang
    message option_help
}

# Stop immediately with a consistent error prefix.
error() {
    message error_prefix "$*" >&2
    exit 1
}


