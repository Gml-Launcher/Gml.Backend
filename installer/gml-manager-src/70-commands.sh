# Keep removed installations recoverable by moving the directory aside.
backup_install_directory() {
    timestamp=$(date +%Y%m%d_%H%M%S)
    parent_dir=$(dirname "$BASE_DIR")
    base_name=$(basename "$BASE_DIR")

    mv "$BASE_DIR" "$parent_dir/${base_name}_backup_$timestamp"
}

# Show reachable admin panel URLs after install or update.
write_success_message() {
    mode=$(get_env_value "$BASE_DIR/.env" "GML_PROXY_MODE")
    domain=$(get_env_value "$BASE_DIR/.env" "GML_PROXY_DOMAIN")
    port=$(get_env_value "$BASE_DIR/.env" "PORT_GML_FRONTEND")
    port=${port:-5003}
    ip_list=""

    if command -v ip >/dev/null 2>&1; then
        ip_list=$(ip -4 -o addr show up | awk '!/ lo / && !/docker|br-|veth/ {print $4}' | cut -d/ -f1 | sort -u)
    fi

    # Some containers expose `ip`, but it returns no matching addresses.
    if [ -z "$ip_list" ] && command -v hostname >/dev/null 2>&1; then
        ip_list=$(hostname -I 2>/dev/null)
    fi

    if [ -z "$ip_list" ] && [ -n "${SSH_CONNECTION:-}" ]; then
        ip_list=$(echo "$SSH_CONNECTION" | awk '{print $3}')
    fi

    # Always print at least an address that is reachable from the host itself.
    ip_list=${ip_list:-127.0.0.1}

    echo
    printf "\033[32m==================================================\033[0m\n"
    printf "\033[32m%s\033[0m\n" "$(message backend_ready)"
    printf "\033[32m==================================================\033[0m\n"
    message admin_panel
    printf "\n"

    if [ "$mode" = "global" ] && [ -n "$domain" ]; then
        echo " - https://$domain/"
        return 0
    fi

    for ip in $ip_list; do
        [ -n "$ip" ] && echo " - http://$ip:$port/"
    done
}

# Confirm that delete finished and the directory was backed up.
write_delete_message() {
    echo
    printf "\033[32m==================================================\033[0m\n"
    printf "\033[32m%s\033[0m\n" "$(message backend_removed)"
    printf "\033[32m==================================================\033[0m\n"
}

# Full installation flow. Every step must succeed before the next starts.
run_install() {
    run_step "$(message step_detect_os)" detect_os
    run_step "$(message step_prepare_os)" disable_additional_notify
    run_step "$(message step_install_curl)" ensure_command curl curl
    run_step "$(message step_install_openssl)" ensure_command openssl openssl
    run_step "$(message step_install_docker)" install_docker
    run_step "$(message step_install_network_tools)" ensure_socket_tools
    run_step "$(message step_check_empty_directory)" ensure_install_directory_empty
    run_step "$(message step_check_proxy)" check_proxy_requirements
    run_step "$(message step_create_directory)" prepare_directory
    run_step "$(message step_download_compose)" download_compose
    run_step "$(message step_update_env)" ensure_env
    run_step "$(message step_start_compose)" start_install_stack
    write_success_message
}

# Update the compose file, version variable, images, and running containers.
run_update() {
    run_step "$(message step_check_directory)" ensure_install_directory_exists
    if ! confirm_compose_overwrite; then
        return 0
    fi
    run_step "$(message step_install_curl)" ensure_command curl curl
    run_step "$(message step_install_network_tools)" ensure_socket_tools
    run_step "$(message step_check_proxy)" check_proxy_requirements
    run_step "$(message step_start_compose)" update_stack_transaction
    write_success_message
}

# Stop the stack, remove compose-managed resources, and back up the directory.
run_delete() {
    run_step "$(message step_check_directory)" ensure_install_directory_exists
    run_step "$(message step_stop_compose_volumes)" docker_compose_down_volumes
    run_step "$(message step_remove_images)" docker_compose_down_images
    run_step "$(message step_backup_directory)" backup_install_directory
    write_delete_message
}


