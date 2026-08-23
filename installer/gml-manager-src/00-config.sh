DEFAULT_BASE_DIR="/srv/gml"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-Gml-Launcher/Gml.Backend}"
COMPOSE_URL_OVERRIDE="${COMPOSE_URL:-}"
DEFAULT_COMPOSE_URL="${DEFAULT_COMPOSE_URL:-https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/master/docker-compose-installer.yml}"
ENV_URL="${ENV_URL:-https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/master/installer/installer.env}"
DEFAULT_TAGS_URL="https://api.github.com/repos/$GITHUB_REPOSITORY/tags?per_page=100"
DNS_DOH_URLS="${DNS_DOH_URLS:-https://dns.google/resolve https://cloudflare-dns.com/dns-query}"

SCRIPT_DIR=""
if [ -f "$0" ]; then
    SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
fi

ACTION=""
BASE_DIR=""
VERSION=""
PROXY_MODE=""
PROXY_DOMAIN=""
TARGET_FRONTEND_PORT="5003"
PROXY_HTTPS_PORT="0"
CURRENT_PROXY_MODE="external"
ACCEPT_ACME_TERMS=0
COMPOSE_URL=""
PROMPT_ANSWER=""
INTERACTIVE_MODE=0
SHOW_HELP=0
GML_MANAGER_LANGUAGE="en"

