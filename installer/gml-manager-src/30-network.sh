# Accept a single ASCII hostname.
validate_proxy_domain() {
    domain="$1"

    [ "${#domain}" -le 253 ] || return 1
    is_ipv4 "$domain" && return 1

    printf '%s\n' "$domain" | LC_ALL=C awk '
        NR != 1 || index($0, ".") == 0 { exit 1 }

        {
            count = split($0, labels, ".")
            for (i = 1; i <= count; i++) {
                if (length(labels[i]) > 63 ||
                    labels[i] !~ /^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$/) {
                    exit 1
                }
            }
        }
    '
}

is_valid_port() {
    case "$1" in
        ""|*[!0-9]*) return 1 ;;
    esac

    printf '%s\n' "$1" | awk '{ exit !($0 + 0 >= 1 && $0 + 0 <= 65535) }'
}


is_ipv4() {
    printf '%s\n' "$1" | awk -F. '
        NF != 4 { exit 1 }
        {
            for (i = 1; i <= 4; i++) {
                if ($i !~ /^[0-9]+$/ || $i < 0 || $i > 255) exit 1
            }
        }
    '
}

# Query several independent services so a temporary outage does not prevent installation. 
# IPv4 is authoritative for the mandatory DNS A check.
detect_public_ipv4() {
    for endpoint in https://ifconfig.me/ip https://api.ipify.org https://icanhazip.com; do
        address=$(curl -4 -fsS --connect-timeout 3 --max-time 7 "$endpoint" 2>/dev/null | tr -d '[:space:]') || address=""
        if [ -n "$address" ] && is_ipv4 "$address"; then
            printf '%s\n' "$address"
            return 0
        fi
    done

    echo "Unable to determine the server public IPv4 address" >&2
    return 1
}

detect_public_ipv6() {
    for endpoint in https://ifconfig.me/ip https://api64.ipify.org https://icanhazip.com; do
        address=$(curl -6 -fsS --connect-timeout 3 --max-time 7 "$endpoint" 2>/dev/null | tr -d '[:space:]') || address=""
        case "$address" in
            *:*) printf '%s\n' "$address"; return 0 ;;
        esac
    done

    return 1
}

# Canonicalize equivalent IPv6 spellings (expanded/compressed, letter case)
# when libc getent is available; fall back to lowercase text otherwise.
normalize_ipv6() {
    normalized=""
    if command -v getent >/dev/null 2>&1; then
        normalized=$(getent ahostsv6 "$1" 2>/dev/null | awk 'NR == 1 { print $1 }')
    fi
    printf '%s\n' "${normalized:-$1}" | tr '[:upper:]' '[:lower:]'
}

# Extract address records from the compact or pretty-printed JSON returned by the Google and Cloudflare DNS-over-HTTPS APIs.
parse_doh_records() {
    response="$1"
    rr_number="$2"

    printf '%s' "$response" | awk -v RS='}' -v rr_number="$rr_number" '
        $0 ~ "\"type\"[[:space:]]*:[[:space:]]*" rr_number "([^0-9]|$)" &&
        match($0, /"data"[[:space:]]*:[[:space:]]*"[^"]*"/) {
            value = substr($0, RSTART, RLENGTH)
            sub(/^"data"[[:space:]]*:[[:space:]]*"/, "", value)
            sub(/"$/, "", value)
            print value
        }
    '
}

# Resolve through public DNS-over-HTTPS endpoints using curl, which the installer already requires. The optional URL list makes the check mockable.
query_doh_records() {
    record_type="$1"
    rr_number="$2"

    for doh_url in $DNS_DOH_URLS; do
        doh_response=$(curl -fsS --connect-timeout 3 --max-time 7 \
            --header 'accept: application/dns-json' \
            --get --data-urlencode "name=$PROXY_DOMAIN" --data "type=$record_type" \
            "$doh_url" 2>/dev/null) || continue

        if printf '%s' "$doh_response" | grep -Eq '"Status"[[:space:]]*:[[:space:]]*0([^0-9]|$)'; then
            parse_doh_records "$doh_response" "$rr_number"
            return 0
        fi
    done

    echo "Unable to query public DNS for $PROXY_DOMAIN $record_type records" >&2
    return 1
}

# Let's Encrypt must reach this exact machine. Proxy/CDN records are rejected
# because they require a different challenge and trusted-proxy configuration.
check_global_dns() {
    public_ipv4=$(detect_public_ipv4) || return 1
    a_records=$(query_doh_records A 1) || return 1

    if [ -z "$a_records" ]; then
        echo "Domain $PROXY_DOMAIN has no DNS A record" >&2
        return 1
    fi

    for address in $a_records; do
        if ! is_ipv4 "$address" || [ "$address" != "$public_ipv4" ]; then
            echo "DNS A for $PROXY_DOMAIN points to $address, but this server public IPv4 is $public_ipv4" >&2
            echo "Cloudflare/CDN proxying is not supported in global mode; use a direct DNS record" >&2
            return 1
        fi
    done

    aaaa_records=$(query_doh_records AAAA 28) || return 1
    if [ -n "$aaaa_records" ]; then
        public_ipv6=$(detect_public_ipv6) || {
            echo "Domain $PROXY_DOMAIN has an AAAA record, but this server has no detectable public IPv6" >&2
            echo "Point every AAAA record to this server or remove AAAA before requesting a certificate" >&2
            return 1
        }

        for address in $aaaa_records; do
            if [ "$(normalize_ipv6 "$address")" != "$(normalize_ipv6 "$public_ipv6")" ]; then
                echo "DNS AAAA for $PROXY_DOMAIN points to $address, but this server public IPv6 is $public_ipv6" >&2
                echo "Point every AAAA record to this server or remove AAAA before requesting a certificate" >&2
                return 1
            fi
        done
    fi

    echo "DNS A: $PROXY_DOMAIN -> $public_ipv4"
}

check_port_available() {
    port="$1"
    listening_sockets=$(ss -H -ltn 2>/dev/null) || {
        echo "Unable to inspect listening TCP ports with ss" >&2
        return 1
    }

    if printf '%s\n' "$listening_sockets" | awk -v port="$port" '
        {
            address = $4
            sub(/^.*:/, "", address)
            if (address == port) found = 1
        }
        END { exit found ? 0 : 1 }
    '; then
        echo "TCP port $port is already in use:" >&2
        ss -H -ltnp 2>/dev/null | awk -v port="$port" '$4 ~ (":" port "$")' >&2 || true
        return 1
    fi
}

# A running installation owns its current ports, so availability is checked for
# fresh installs and mode transitions only. DNS is checked on every global run.
check_proxy_requirements() {
    if [ "$PROXY_MODE" = "global" ]; then
        check_global_dns || return 1
    fi

    if [ "$ACTION" = "update" ] && [ "$PROXY_MODE" = "$CURRENT_PROXY_MODE" ]; then
        return 0
    fi

    if [ "$PROXY_MODE" = "global" ]; then
        check_port_available 80 || return 1
        check_port_available 443 || return 1
    else
        check_port_available "$TARGET_FRONTEND_PORT" || return 1
    fi
}


