# Docker Compose wrappers keep each operation as an isolated run_step target.
docker_compose_up() {
    cd "$BASE_DIR"
    docker compose up -d
}

docker_compose_up_with_pull() {
    cd "$BASE_DIR"
    docker compose up -d --pull always
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

validate_compose() {
    cd "$BASE_DIR"
    docker compose config >/dev/null
}

# The local connection validates both successful ACME issuance and the served
# certificate without depending on local DNS routing back through the internet.
wait_for_global_certificate() {
    [ "$PROXY_MODE" = "global" ] || return 0

    attempt=1
    while [ "$attempt" -le 60 ]; do
        if curl --noproxy '*' --silent --show-error --output /dev/null \
            --connect-timeout 3 --max-time 8 \
            --resolve "$PROXY_DOMAIN:443:127.0.0.1" \
            "https://$PROXY_DOMAIN/" 2>/dev/null; then
            return 0
        fi
        sleep 3
        attempt=$((attempt + 1))
    done

    echo "Timed out waiting for a valid Let’s Encrypt certificate for $PROXY_DOMAIN" >&2
    cd "$BASE_DIR"
    docker compose logs --tail 80 gml-web-proxy >&2 || true
    return 1
}

start_install_stack() {
    validate_compose || return 1
    docker_compose_up_with_pull || return 1

    if ! wait_for_global_certificate; then
        docker_compose_down || true
        return 1
    fi
}

# Update compose and installer-managed environment keys atomically. If the new
# proxy cannot start or obtain its certificate, restore the previous stack.
update_stack_transaction() {
    transaction_compose="$BASE_DIR/docker-compose.yml"
    transaction_env="$BASE_DIR/.env"
    transaction_staged_compose="$BASE_DIR/.docker-compose.yml.new.$$"
    transaction_staged_env="$BASE_DIR/.env.new.$$"
    transaction_backup_compose="$BASE_DIR/.docker-compose.yml.backup.$$"
    transaction_backup_env="$BASE_DIR/.env.backup.$$"

    [ -f "$transaction_compose" ] || {
        echo "Missing $transaction_compose" >&2
        return 1
    }
    [ -f "$transaction_env" ] || {
        echo "Missing $transaction_env" >&2
        return 1
    }

    curl -fsSL "$COMPOSE_URL" -o "$transaction_staged_compose" || return 1
    cp "$transaction_env" "$transaction_staged_env" || return 1
    upsert_env_value "$transaction_staged_env" "GML_VERSION" "$VERSION"
    upsert_env_value "$transaction_staged_env" "GML_PROXY_MODE" "$PROXY_MODE"
    upsert_env_value "$transaction_staged_env" "GML_PROXY_DOMAIN" "$PROXY_DOMAIN"
    upsert_env_value "$transaction_staged_env" "GML_PROXY_HTTPS_PORT" "$PROXY_HTTPS_PORT"
    upsert_env_value "$transaction_staged_env" "PORT_GML_FRONTEND" "$TARGET_FRONTEND_PORT"

    (
        cd "$BASE_DIR" &&
        docker compose --env-file "$transaction_staged_env" -f "$transaction_staged_compose" config >/dev/null
    ) || {
        rm -f "$transaction_staged_compose" "$transaction_staged_env"
        return 1
    }

    # Pull while the current stack is still serving traffic. The activation and
    # rollback paths can then start entirely from local images.
    (
        cd "$BASE_DIR" &&
        docker compose --env-file "$transaction_staged_env" -f "$transaction_staged_compose" pull
    ) || {
        rm -f "$transaction_staged_compose" "$transaction_staged_env"
        return 1
    }

    cp "$transaction_compose" "$transaction_backup_compose" || {
        rm -f "$transaction_staged_compose" "$transaction_staged_env"
        return 1
    }
    cp "$transaction_env" "$transaction_backup_env" || {
        rm -f "$transaction_staged_compose" "$transaction_staged_env" "$transaction_backup_compose"
        return 1
    }

    if ! docker_compose_down; then
        rm -f "$transaction_staged_compose" "$transaction_staged_env" "$transaction_backup_compose" "$transaction_backup_env"
        return 1
    fi

    mv "$transaction_staged_compose" "$transaction_compose"
    mv "$transaction_staged_env" "$transaction_env"

    if docker_compose_up && wait_for_global_certificate; then
        rm -f "$transaction_backup_compose" "$transaction_backup_env"
        return 0
    fi

    echo "New proxy mode failed; restoring the previous installation" >&2
    docker_compose_down || true
    mv "$transaction_backup_compose" "$transaction_compose"
    mv "$transaction_backup_env" "$transaction_env"

    if ! docker_compose_up; then
        echo "Rollback files were restored, but the previous stack could not be started" >&2
        return 1
    fi

    return 1
}


