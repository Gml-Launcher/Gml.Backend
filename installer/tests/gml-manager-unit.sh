#!/bin/sh

set -eu

TEST_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
INSTALLER_DIR=$(CDPATH= cd "$TEST_SCRIPT_DIR/.." && pwd)
MANAGER_FILE="$INSTALLER_DIR/gml-manager.sh"

GML_MANAGER_SKIP_MAIN=1
export GML_MANAGER_SKIP_MAIN
. "$MANAGER_FILE"

detect_language --lang ru
test "$GML_MANAGER_LANGUAGE" = ru
message compose_overwrite_warning | grep "docker-compose.yml будет заменён" >/dev/null
read_prompt_answer() { PROMPT_ANSWER=да; }
confirm_compose_overwrite >/dev/null 2>&1
read_prompt_answer() { PROMPT_ANSWER=n; }
! confirm_compose_overwrite >/dev/null 2>&1

parse_args --lang ru install --version v1.2.3 --dir /tmp/gml \
    --proxy-mode global --domain gml.example.com --accept-acme-terms
test "$ACTION" = install
test "$VERSION" = v1.2.3
test "$BASE_DIR" = /tmp/gml
test "$PROXY_MODE" = global
test "$PROXY_DOMAIN" = gml.example.com
test "$ACCEPT_ACME_TERMS" = 1

validate_proxy_domain gml.example.com
! validate_proxy_domain "*.example.com"
! validate_proxy_domain "-gml.example.com"
! validate_proxy_domain "gml..example.com"
multiline_domain=$(printf "gml.example.com\nother.example.com")
! validate_proxy_domain "$multiline_domain"

is_valid_port 1
is_valid_port 65535
! is_valid_port 0
! is_valid_port 65536
! is_valid_port invalid

doh_json='{"Status":0,"Question":[{"name":"gml.example.com.","type":1}],"Answer":[{"name":"gml.example.com.","type":5,"TTL":60,"data":"alias.example.com."},{"name":"alias.example.com.","type":1,"TTL":60,"data":"203.0.113.10"}]}'
test "$(parse_doh_records "$doh_json" 1)" = 203.0.113.10
test -z "$(parse_doh_records "$doh_json" 28)"

DNS_DOH_URLS=https://dns.test/resolve
PROXY_DOMAIN=gml.example.com
curl() { printf "%s" "$doh_json"; }
test "$(query_doh_records A 1)" = 203.0.113.10
unset -f curl

legacy_dir=$(mktemp -d)
transaction_dir=$(mktemp -d)
cleanup_test_directories() {
    rm -rf "$legacy_dir" "$transaction_dir"
}
trap cleanup_test_directories 0
trap 'exit 1' 1 2 15

ACTION=update
BASE_DIR="$legacy_dir"
INTERACTIVE_MODE=0
PROXY_MODE=
PROXY_DOMAIN=
ACCEPT_ACME_TERMS=0
resolve_proxy_inputs
test "$CURRENT_PROXY_MODE" = external
test "$PROXY_MODE" = external

printf "%s\n" old-compose > "$transaction_dir/docker-compose.yml"
printf "%s\n" "GML_VERSION=old" > "$transaction_dir/.env"
printf "%s\n" new-compose > "$transaction_dir/source-compose.yml"
BASE_DIR="$transaction_dir"
COMPOSE_URL=https://compose.test/docker-compose.yml
VERSION=new
PROXY_MODE=external
PROXY_DOMAIN=
PROXY_HTTPS_PORT=0
TARGET_FRONTEND_PORT=5003
transaction_log="$transaction_dir/operations.log"
transaction_up_count="$transaction_dir/up-count"

curl() {
    mock_output=
    while [ "$#" -gt 0 ]; do
        if [ "$1" = -o ]; then
            mock_output="$2"
            break
        fi
        shift
    done
    cp "$transaction_dir/source-compose.yml" "$mock_output"
}

docker() {
    case " $* " in
        *" config "*) echo config >> "$transaction_log" ;;
        *" pull "*) echo pull >> "$transaction_log" ;;
        *) return 1 ;;
    esac
}

docker_compose_down() {
    echo down >> "$transaction_log"
}

docker_compose_up() {
    mock_count=$(cat "$transaction_up_count" 2>/dev/null || echo 0)
    mock_count=$((mock_count + 1))
    printf "%s\n" "$mock_count" > "$transaction_up_count"
    echo "up-$mock_count" >> "$transaction_log"
    [ "$mock_count" -gt 1 ]
}

wait_for_global_certificate() { return 0; }

! update_stack_transaction
test "$(cat "$transaction_dir/docker-compose.yml")" = old-compose
grep -qx "GML_VERSION=old" "$transaction_dir/.env"
pull_line=$(awk '$0 == "pull" { print NR; exit }' "$transaction_log")
down_line=$(awk '$0 == "down" { print NR; exit }' "$transaction_log")
test "$pull_line" -lt "$down_line"
grep -qx up-2 "$transaction_log"

cleanup_test_directories
trap - 0 1 2 15
