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
            --proxy-mode)
                require_value "$1" "${2:-}"
                PROXY_MODE="$2"
                shift 2
                ;;
            --domain)
                require_value "$1" "${2:-}"
                PROXY_DOMAIN="$2"
                shift 2
                ;;
            --accept-acme-terms)
                ACCEPT_ACME_TERMS=1
                shift
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

    # Also accept redirected stdin for CI and other explicitly scripted input.
    IFS= read -r PROMPT_ANSWER || PROMPT_ANSWER=""
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

# Let interactive users confirm or override the language inferred from locale.
prompt_language() {
    message language_menu >&2
    prompt_with_default "$(message language_prompt)" "$GML_MANAGER_LANGUAGE"

    case "$PROMPT_ANSWER" in
        1|ru) set_language "ru" ;;
        2|en) set_language "en" ;;
        *) error "$(message unsupported_language "$PROMPT_ANSWER")" ;;
    esac
}

# Keep an explicit --lang value; otherwise ask only in the interactive workflow.
resolve_language_input() {
    if [ "$INTERACTIVE_MODE" -eq 1 ] && [ "$GML_MANAGER_LANGUAGE_EXPLICIT" -eq 0 ]; then
        prompt_language
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

# Updating replaces the managed Compose template. Require an explicit answer so
# manual edits are never discarded merely because an update command was run.
confirm_compose_overwrite() {
    message compose_overwrite_warning >&2
    read_prompt_answer

    case "$PROMPT_ANSWER" in
        y|Y|yes|YES|Yes|д|Д|да|ДА|Да)
            return 0
            ;;
        *)
            message update_cancelled >&2
            return 1
            ;;
    esac
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


# Ask proxy mode
prompt_proxy_settings() {
    message proxy_mode_menu >&2
    prompt_with_default "$(message proxy_mode_prompt)" "$CURRENT_PROXY_MODE"

    case "$PROMPT_ANSWER" in
        1|external) PROXY_MODE="external" ;;
        2|global) PROXY_MODE="global" ;;
        *) error "$(message invalid_proxy_mode "$PROMPT_ANSWER")" ;;
    esac

    if [ "$PROXY_MODE" = "global" ]; then
        default_domain=$(get_env_value "$BASE_DIR/.env" "GML_PROXY_DOMAIN")
        prompt_with_default "$(message proxy_domain_prompt)" "${default_domain:-gml.example.com}"
        PROXY_DOMAIN="$PROMPT_ANSWER"

        if [ "$CURRENT_PROXY_MODE" != "global" ]; then
            message acme_terms_prompt >&2
            read_prompt_answer
            case "$PROMPT_ANSWER" in
                y|Y|yes|YES|Yes|д|Д|да|ДА|Да) ACCEPT_ACME_TERMS=1 ;;
                *) error "$(message acme_terms_required)" ;;
            esac
        fi
    fi
}

resolve_proxy_inputs() {
    if [ "$ACTION" = "delete" ]; then
        return 0
    fi

    installed_mode=$(get_env_value "$BASE_DIR/.env" "GML_PROXY_MODE")
    case "$installed_mode" in
        global) CURRENT_PROXY_MODE="global" ;;
        *) CURRENT_PROXY_MODE="external" ;;
    esac

    if [ "$ACTION" = "install" ]; then
        CURRENT_PROXY_MODE="external"
    fi

    if [ "$INTERACTIVE_MODE" -eq 1 ]; then
        prompt_proxy_settings
    elif [ -z "$PROXY_MODE" ]; then
        if [ "$ACTION" = "update" ]; then
            PROXY_MODE="$CURRENT_PROXY_MODE"
        else
            PROXY_MODE="external"
        fi
    fi

    case "$PROXY_MODE" in
        external)
            PROXY_DOMAIN=""
            PROXY_HTTPS_PORT="0"
            if [ "$CURRENT_PROXY_MODE" = "external" ]; then
                TARGET_FRONTEND_PORT=$(get_env_value "$BASE_DIR/.env" "PORT_GML_FRONTEND")
                TARGET_FRONTEND_PORT=${TARGET_FRONTEND_PORT:-5003}
            else
                TARGET_FRONTEND_PORT="5003"
            fi
            is_valid_port "$TARGET_FRONTEND_PORT" || error "$(message invalid_port "$TARGET_FRONTEND_PORT")"
            ;;
        global)
            if [ -z "$PROXY_DOMAIN" ]; then
                PROXY_DOMAIN=$(get_env_value "$BASE_DIR/.env" "GML_PROXY_DOMAIN")
            fi
            PROXY_DOMAIN=$(printf '%s' "$PROXY_DOMAIN" | tr '[:upper:]' '[:lower:]')
            [ -n "$PROXY_DOMAIN" ] || error "$(message domain_required)"
            validate_proxy_domain "$PROXY_DOMAIN" || error "$(message invalid_domain "$PROXY_DOMAIN")"

            if [ "$CURRENT_PROXY_MODE" != "global" ] && [ "$ACCEPT_ACME_TERMS" -ne 1 ]; then
                error "$(message acme_terms_required)"
            fi
            TARGET_FRONTEND_PORT="80"
            PROXY_HTTPS_PORT="443"
            ;;
        *)
            error "$(message invalid_proxy_mode "$PROXY_MODE")"
            ;;
    esac

    COMPOSE_URL=${COMPOSE_URL_OVERRIDE:-$DEFAULT_COMPOSE_URL}
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
