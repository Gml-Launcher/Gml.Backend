#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
frontend_dir="$project_dir/src/Gml.Web.Client"
api_dir="$project_dir/src/Gml.Web.Api/src/Gml.Web.Api"
skins_dir="$project_dir/src/Gml.Web.Skin.Service/src/Gml.Web.Skin.Service"

for tool in dotnet node npm; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Required tool is missing: %s\n' "$tool" >&2
        exit 1
    fi
done

if [[ ! -f "$frontend_dir/node_modules/next/package.json" ]]; then
    printf 'Install frontend dependencies first: npm --prefix "%s" ci\n' "$frontend_dir" >&2
    exit 1
fi

for project_file in "$api_dir/Gml.Web.Api.csproj" "$skins_dir/Gml.Web.Skin.Service.csproj"; do
    if [[ ! -f "$project_file" ]]; then
        printf 'Project is missing: %s. Initialize Git submodules first.\n' "$project_file" >&2
        exit 1
    fi
done

# Binding also detects listeners on wildcard addresses; no platform-specific ss/lsof needed.
node <<'NODE'
const net = require('node:net');
Promise.all([3000, 5002, 5086].map(port => new Promise((resolve, reject) => {
    const server = net.createServer();
    server.once('error', error => reject(new Error(`Cannot bind port ${port}: ${error.message}`)));
    server.listen(port, () => server.close(resolve));
}))).catch(error => {
    console.error(error.message);
    process.exitCode = 1;
});
NODE

service_pids=()
service_names=()

cleanup() {
    trap '' INT TERM
    local pid attempt running
    for pid in "${service_pids[@]}"; do
        kill -TERM -- "-$pid" 2>/dev/null || true
    done
    for ((attempt = 0; attempt < 50; attempt++)); do
        running=0
        for pid in "${service_pids[@]}"; do
            if kill -0 -- "-$pid" 2>/dev/null; then
                running=1
            fi
        done
        if ((running == 0)); then
            break
        fi
        sleep 0.1
    done
    for pid in "${service_pids[@]}"; do
        kill -KILL -- "-$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    done
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Bash job control gives each service its own process group, including npm/dotnet children.
set -m
start_service() {
    local name="$1" directory="$2"
    shift 2
    (
        cd -- "$directory"
        exec "$@"
    ) &
    service_pids+=("$!")
    service_names+=("$name")
}

start_service API "$api_dir" dotnet run --project Gml.Web.Api.csproj --launch-profile frontend
start_service Skins "$skins_dir" dotnet run --project Gml.Web.Skin.Service.csproj --launch-profile http
start_service Frontend "$frontend_dir" npm run dev

printf 'Starting GML: http://localhost:3000 (API :5002, skins :5086). Ctrl+C stops all services.\n'

while true; do
    for index in "${!service_pids[@]}"; do
        if ! kill -0 "${service_pids[$index]}" 2>/dev/null; then
            status=0
            wait "${service_pids[$index]}" || status=$?
            printf '%s exited (status %s); stopping all services.\n' "${service_names[$index]}" "$status" >&2
            if ((status == 0)); then
                status=1
            fi
            exit "$status"
        fi
    done
    sleep 1
done
