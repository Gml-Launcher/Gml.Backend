# Entrypoint: parse, validate privileges, resolve prompts, then dispatch.
main() {
    detect_language "$@"
    print_banner
    parse_args "$@"
    require_root
    resolve_action_and_base_dir
    resolve_proxy_inputs

    case "$ACTION" in
        install|update)
            if [ -z "$VERSION" ]; then
                run_step "$(message step_install_curl)" ensure_command curl curl
            fi
            ;;
    esac

    resolve_version_input

    case "$ACTION" in
        install)
            run_install
            ;;
        update)
            run_update
            ;;
        delete)
            run_delete
            ;;
        *)
            error "$(message unknown_action "$ACTION")"
            ;;
    esac
}

if [ "${GML_MANAGER_SKIP_MAIN:-0}" != "1" ]; then
    main "$@"
fi

