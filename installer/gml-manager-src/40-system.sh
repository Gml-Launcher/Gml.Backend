# Root is required because the script installs packages and controls Docker.
require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "$(message root_required)"
    fi
}

# Display a lightweight spinner while a background step is running.
show_spinner() {
    pid="$1"
    text="$2"
    delay=0.1

    while kill -0 "$pid" 2>/dev/null; do
        for char in "/" "-" "\\" "|"; do
            printf "\r%s %s" "$text" "$char"
            sleep "$delay"
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
        done
    done

    wait "$pid"
    result="$?"

    if [ "$result" -eq 0 ]; then
        printf "\r%s \033[32m✓\033[0m\n" "$text"
    else
        printf "\r%s \033[31m✗\033[0m\n" "$text"
    fi

    return "$result"
}

# Strip terminal controls from logs, including Docker's carriage-return progress.
plain_step_log() {
    tr '\r' '\n' | awk '
        BEGIN { esc = sprintf("%c", 27); bel = sprintf("%c", 7) }
        {
            out = ""; state = ""
            for (i = 1; i <= length($0); i++) {
                c = substr($0, i, 1)
                if (state == "escape") {
                    if (c == "[") state = "csi"
                    else if (c == "]") state = "osc"
                    else state = ""
                } else if (state == "csi") {
                    if (c ~ /[@-~]/) state = ""
                } else if (state == "osc") {
                    if (c == bel) state = ""
                    else if (c == esc) state = "osc_escape"
                } else if (state == "osc_escape") {
                    if (c == "\\") state = ""
                    else state = "osc"
                } else if (c == esc) state = "escape"
                else if (c == "\t") out = out "    "
                else if (c !~ /[[:cntrl:]]/) out = out c
            }
            print out
        }
    '
}

# stty reads the output terminal: stdin may contain curl | sudo sh's script.
step_terminal_size() {
    [ -t 1 ] && [ "${TERM:-dumb}" != dumb ] || return 1
    step_size=$(stty size 2>/dev/null <&3) || return 1
    set -- $step_size
    [ "$#" -eq 2 ] || return 1
    step_rows=$1
    step_columns=$2
    case "$step_rows:$step_columns" in *[!0-9:]*|:*) return 1 ;; esac
    [ "$step_rows" -ge 7 ] && [ "$step_columns" -ge 30 ]
} 3>&1

# Count UTF-8 characters without splitting continuation bytes (also with mawk).
fit_step_lines() {
    LC_ALL=C awk -v width="$1" '
        {
            line = ""; columns = 0
            for (i = 1; i <= length($0); i++) {
                c = substr($0, i, 1)
                continuation = c ~ /^[\200-\277]$/
                if (!continuation && columns >= width) break
                line = line c
                if (!continuation) columns++
            }
            printf "%s%*s\n", line, width - columns, ""
        }
    '
}

render_step_box() {
    step_height=$((step_rows - 4))
    [ "$step_height" -le 8 ] || step_height=8
    step_width=$((step_columns - 4))
    # Clear the old block before redrawing, also after a terminal resize.
    if [ "$step_drawn" -gt 0 ]; then
        printf '\033[%sA\r\033[J' "$step_drawn"
    fi
    printf '\033[2K'
    printf '%s %s\n' "$1" "$step_text" | plain_step_log |
        head -n 1 | fit_step_lines "$((step_columns - 1))"
    awk -v width="$step_width" 'BEGIN {
        printf "+"; for (i = 0; i < width + 2; i++) printf "-"; print "+"
    }'
    tail -n 80 "$step_log" | plain_step_log | tail -n "$step_height" |
        fit_step_lines "$step_width" |
        awk -v width="$step_width" -v height="$step_height" '
            { printf "| %s |\n", $0; count++ }
            END { for (; count < height; count++) printf "| %*s |\n", width, "" }
        '
    awk -v width="$step_width" 'BEGIN {
        printf "+"; for (i = 0; i < width + 2; i++) printf "-"; print "+"
    }'
    step_drawn=$((step_height + 3))
}

# Plain output is streamed by byte offset so partial lines are never lost.
stream_step_log() {
    step_bytes=$(wc -c < "$step_log")
    if [ "$step_bytes" -gt "$step_offset" ]; then
        tail -c +$((step_offset + 1)) "$step_log" |
            head -c "$((step_bytes - step_offset))" | plain_step_log
        step_offset=$step_bytes
    fi
}

# Isolate traps and working variables from the calling installer shell.
run_step_output() (
    step_live="$1"
    step_text="$2"
    shift 2
    step_log=$(mktemp "${TMPDIR:-/tmp}/gml-manager.XXXXXX") || exit 1
    step_pid=""
    step_drawn=0
    step_offset=0
    step_tick=0
    step_cursor_hidden=0
    cleanup_step() {
        if [ "$step_cursor_hidden" -eq 1 ]; then
            printf '\033[?25h'
        fi
        rm -f "$step_log"
    }
    interrupt_step() {
        [ -z "$step_pid" ] || kill "$step_pid" 2>/dev/null || true
        exit "$1"
    }
    trap cleanup_step 0
    trap 'interrupt_step 129' 1
    trap 'interrupt_step 130' 2
    trap 'interrupt_step 143' 15

    ( "$@" ) >"$step_log" 2>&1 &
    step_pid=$!

    if [ "$step_live" -eq 1 ]; then
        if step_terminal_size; then
            printf '\033[?25l'
            step_cursor_hidden=1
        else
            printf '%s\n' "$step_text"
        fi
        while kill -0 "$step_pid" 2>/dev/null; do
            if [ "$step_cursor_hidden" -eq 1 ] && step_terminal_size; then
                case "$step_tick" in
                    0) step_mark='/' ;;
                    1) step_mark='-' ;;
                    2) step_mark='\' ;;
                    3) step_mark='|' ;;
                esac
                render_step_box "$step_mark"
                step_tick=$(((step_tick + 1) % 4))
            else
                if [ "$step_drawn" -gt 0 ]; then
                    printf '\033[%sA\r\033[J\033[?25h' "$step_drawn"
                    step_drawn=0
                    step_cursor_hidden=0
                fi
                stream_step_log
            fi
            sleep 0.2
        done
        step_result=0
        wait "$step_pid" || step_result=$?
        if [ "$step_result" -eq 0 ]; then step_mark='✓'; else step_mark='✗'; fi
        if [ "$step_cursor_hidden" -eq 1 ] && step_terminal_size; then
            render_step_box "$step_mark"
        else
            stream_step_log
            printf '%s %s\n' "$step_text" "$step_mark"
        fi
    else
        step_result=0
        show_spinner "$step_pid" "$step_text" || step_result=$?
    fi

    if [ "$step_result" -ne 0 ]; then
        message step_failed "$step_text" "$step_result" >&2
        if [ -s "$step_log" ]; then
            message last_log_lines >&2
            tail -n 40 "$step_log" | plain_step_log >&2
        fi
    fi
    exit "$step_result"
)

# A failed step still aborts the full workflow, not just the rendering subshell.
run_step() {
    run_step_output 0 "$@" || exit "$?"
}

run_compose_step() {
    run_step_output 1 "$@" || exit "$?"
}

# Avoid interactive package restart prompts on systems with needrestart.
disable_additional_notify() {
    if [ -f /etc/needrestart/needrestart.conf ]; then
        sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
    fi
}

# Record OS information in the step log for easier troubleshooting.
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "OS: ${NAME:-unknown} ${VERSION_ID:-unknown}"
    else
        echo "OS: unknown"
    fi
}

# Detect Alpine because Docker is installed from Alpine packages there.
is_alpine() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        [ "${ID:-}" = "alpine" ]
        return "$?"
    fi

    return 1
}

# Install a package through the first supported package manager found.
install_package() {
    package="$1"

    if command -v apk >/dev/null 2>&1; then
        apk add --no-cache "$package"
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y "$package"
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "$package"
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$package"
    elif command -v zypper >/dev/null 2>&1; then
        zypper install -y "$package"
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm "$package"
    else
        message no_package_manager >&2
        return 1
    fi
}

# Confirm the Docker Compose plugin exists.
docker_compose_available() {
    docker compose version >/dev/null 2>&1
}

# Ensure a command exists, installing its package when needed.
ensure_command() {
    command_name="$1"
    package_name="$2"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        install_package "$package_name"
    fi
}

# Install the package that provides ss on the detected distribution.
ensure_socket_tools() {
    command -v ss >/dev/null 2>&1 && return 0

    if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
        install_package iproute
    else
        install_package iproute2
    fi
}


# Start Docker across common Linux init systems.
start_docker_service() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl enable --now docker
    elif command -v rc-update >/dev/null 2>&1 && command -v rc-service >/dev/null 2>&1; then
        rc-update add docker default
        rc-service docker start
    elif command -v service >/dev/null 2>&1; then
        service docker start
    fi
}

# Install Docker from Alpine packages, including the Compose plugin.
install_alpine_docker() {
    apk add --no-cache docker docker-cli-compose || return 1
    start_docker_service
}

# Install Docker through the official convenience script and start the service.
install_docker() {
    if command -v docker >/dev/null 2>&1 && docker_compose_available; then
        return 0
    fi

    if is_alpine; then
        install_alpine_docker
    else
        sh -c "$(curl -fsSL https://get.docker.com)"
        start_docker_service
    fi

    docker_compose_available
}


