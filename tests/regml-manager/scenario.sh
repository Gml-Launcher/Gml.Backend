#!/bin/sh

set -eu

REPO_DIR="${REPO_DIR:-$(pwd)}"
INSTALL_DIR="${INSTALL_DIR:-/tmp/regml-manager-ci}"
INSTALL_VERSION="${INSTALL_VERSION:-v2025.3.1}"
UPDATE_VERSION="${UPDATE_VERSION:-v2025.3.2}"

as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

collect_diagnostics() {
    set +e

    echo
    echo "===== ReGml manager diagnostics ====="
    id
    uname -a

    if [ -f /etc/os-release ]; then
        cat /etc/os-release
    fi

    command -v docker
    docker version
    docker compose version
    docker ps -a

    if [ -d "$INSTALL_DIR" ]; then
        as_root sh -c '
            cd "$1" || exit 0
            docker compose ps
            docker compose images
            docker compose logs --tail=200
        ' sh "$INSTALL_DIR"
    fi

    parent_dir=$(dirname "$INSTALL_DIR")
    base_name=$(basename "$INSTALL_DIR")
    as_root find "$parent_dir" -maxdepth 1 -type d -name "${base_name}*" -print

    echo "===== End diagnostics ====="
}

finish() {
    result="$?"

    if [ "$result" -ne 0 ]; then
        collect_diagnostics
    fi

    exit "$result"
}

trap finish EXIT

wait_for_compose() {
    label="$1"

    as_root sh -c '
        set -eu

        install_dir="$1"
        label="$2"

        cd "$install_dir"

        for attempt in $(seq 1 60); do
            services="$(docker compose ps --services)"
            total_services=0
            running_services=0
            bad_services=""

            echo "[$label] Compose state attempt $attempt"

            for service in $services; do
                total_services=$((total_services + 1))
                container_id="$(docker compose ps -q "$service" | head -n 1)"

                if [ -z "$container_id" ]; then
                    echo "$service: container is not created yet"
                    continue
                fi

                state="$(docker inspect -f "{{.State.Status}} {{.State.Restarting}} {{.State.ExitCode}}" "$container_id" 2>/dev/null || echo "missing false 0")"
                set -- $state
                status="$1"
                restarting="$2"
                exit_code="$3"

                echo "$service: status=$status restarting=$restarting exit_code=$exit_code"

                if [ "$restarting" = "true" ] || [ "$status" = "exited" ] || [ "$status" = "dead" ] || [ "$status" = "missing" ]; then
                    bad_services="$bad_services $service"
                    continue
                fi

                if [ "$status" = "running" ]; then
                    running_services=$((running_services + 1))
                fi
            done

            if [ -n "$bad_services" ]; then
                echo "Failed services detected:$bad_services"
                docker compose ps
                docker compose logs --tail=200 $bad_services
                exit 1
            fi

            if [ "$total_services" -gt 0 ] && [ "$running_services" -eq "$total_services" ]; then
                docker compose ps
                exit 0
            fi

            docker compose ps
            sleep 5
        done

        echo "Timed out waiting for all services to run"
        docker compose ps
        docker compose logs --tail=200
        exit 1
    ' sh "$INSTALL_DIR" "$label"
}

echo "Running ReGml manager scenario"
echo "Repository: $REPO_DIR"
echo "Install directory: $INSTALL_DIR"
echo "Install version: $INSTALL_VERSION"
echo "Update version: $UPDATE_VERSION"

as_root rm -rf "$INSTALL_DIR" "$INSTALL_DIR"_backup_*

as_root sh "$REPO_DIR/installer/regml-manager.sh" install --version "$INSTALL_VERSION" --dir "$INSTALL_DIR"

as_root test -f "$INSTALL_DIR/.env"
as_root test -f "$INSTALL_DIR/docker-compose.yml"
as_root grep -qx "GML_VERSION=$INSTALL_VERSION" "$INSTALL_DIR/.env"
wait_for_compose "install"

as_root sh "$REPO_DIR/installer/regml-manager.sh" update --version "$UPDATE_VERSION" --dir "$INSTALL_DIR"
as_root grep -qx "GML_VERSION=$UPDATE_VERSION" "$INSTALL_DIR/.env"
wait_for_compose "update"

as_root sh "$REPO_DIR/installer/regml-manager.sh" delete --dir "$INSTALL_DIR"
as_root test ! -d "$INSTALL_DIR"

backup_name="$(basename "$INSTALL_DIR")_backup_*"
backup_dir="$(as_root find "$(dirname "$INSTALL_DIR")" -maxdepth 1 -type d -name "$backup_name" | head -n 1)"
test -n "$backup_dir"

echo "Backup directory: $backup_dir"
echo "ReGml manager scenario completed successfully"
