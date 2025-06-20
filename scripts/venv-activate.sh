source "scripts/functions.sh"

# Le script est sourcé
check_issourced() {
    if is_sourced; then
        print_msg "ERROR" "SCRIPT" "This script must be sourced, not executed directly."
        printf "\n\n"
        print_box "${COLOR_OK_FG}To run this script as sourced, use:${COLOR_RESET}" \
                  "" \
                  "${COLOR_OK_FG}$ source ./scripts/venv-activate.sh${COLOR_RESET}" \
                  80
        
        return 1
    else
        print_msg "OK" "SCRIPT" "Script successfully sourced."
        return 0
    fi
}

main() {
    clear_screen
    check_issourced || { quit_installation; return; }
    print_msg "OK" "VENV" "Activating the virtual environment"
    source $VENV_DIR/bin/activate

    printf "\n\n"
    print_box "${COLOR_OK_FG}To deactivate the virtual environment, simply run:${COLOR_RESET}" \
                "" \
                "${COLOR_OK_FG}$ deactivate${COLOR_RESET}" \
                80
    end_message
    printf "\n\n"

}

main "$@"