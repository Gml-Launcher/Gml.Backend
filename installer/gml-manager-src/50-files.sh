# Read a simple KEY=value entry from an existing .env file.
get_env_value() {
    env_file="$1"
    key="$2"

    if [ ! -f "$env_file" ]; then
        return 0
    fi

    sed -n "s/^${key}=//p" "$env_file" | tail -n 1
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

# Refuse downgrades before any update files or running containers are touched.
ensure_no_version_downgrade() {
    [ "$BREAK_VERSION" -eq 1 ] && return 0

    installed_version=$(get_env_value "$BASE_DIR/.env" "GML_VERSION" | sed \
        -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
        -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/")

    if ! version_order=$(compare_release_versions "$installed_version" "$VERSION"); then
        message version_comparison_failed "$installed_version" "$VERSION" >&2
        return 1
    fi

    if [ "$version_order" = "-1" ]; then
        message version_downgrade_blocked "$installed_version" "$VERSION" >&2
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
    upsert_env_value "$env_file" "GML_PROXY_MODE" "$PROXY_MODE"
    upsert_env_value "$env_file" "GML_PROXY_DOMAIN" "$PROXY_DOMAIN"
    upsert_env_value "$env_file" "GML_PROXY_HTTPS_PORT" "$PROXY_HTTPS_PORT"
    upsert_env_value "$env_file" "PORT_GML_FRONTEND" "$TARGET_FRONTEND_PORT"
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

# Create .env on first install or update installer-managed values afterwards.
ensure_env() {
    if [ ! -f "$BASE_DIR/.env" ]; then
        write_default_env
        return 0
    fi

    upsert_env_value "$BASE_DIR/.env" "GML_VERSION" "$VERSION"
    upsert_env_value "$BASE_DIR/.env" "GML_PROXY_MODE" "$PROXY_MODE"
    upsert_env_value "$BASE_DIR/.env" "GML_PROXY_DOMAIN" "$PROXY_DOMAIN"
    upsert_env_value "$BASE_DIR/.env" "GML_PROXY_HTTPS_PORT" "$PROXY_HTTPS_PORT"
    upsert_env_value "$BASE_DIR/.env" "PORT_GML_FRONTEND" "$TARGET_FRONTEND_PORT"
}


