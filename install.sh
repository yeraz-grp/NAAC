#!/bin/bash

PYTHON3=$(which python3)

REPOSITORY="https://github.com/yeraz-grp/NAAC.git"
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SILENT=${SILENT:-no}

#= SETTINGS ========================================================================================================

REPO_DIR="/opt/NAAC/repo"
VENV_DIR="/opt/NAAC/venv"

COLOR_OK_FG="\e[32m"
COLOR_OK_BG="\e[42m\e[30m"
COLOR_CRITICAL_FG="\e[31m"
COLOR_CRITICAL_BG="\e[41m\e[30m"
COLOR_HIGHLIGHT_FG="\e[1m\e[93m"
COLOR_HIGHLIGHT_FG_REGULAR="\e[93m"
COLOR_HIGHLIGHT_BG="\e[43m\e[30m"
COLOR_INFO_FG="\e[35m"
COLOR_INFO_BG="\e[45m\e[30m"
COLOR_RESET="\e[0m"

LABEL_WIDTH="10"

#= COMMON FEATURES =================================================================================================

# Affiche un messsage
print_msg() {
    case "$1" in
        "OK")
            local color1="$COLOR_OK_FG"
            local color2="$COLOR_OK_BG"
            ;;
        "ERROR")
            local color1="$COLOR_CRITICAL_FG"
            local color2="$COLOR_CRITICAL_BG"
            ;;
        "INFO")
            local color1="$COLOR_INFO_FG"
            local color2="$COLOR_INFO_BG"
            ;;
    esac 

    local label="$2"
    local label_len=${#label}+2
    local pad=$(($LABEL_WIDTH - label_len))
    (( pad < 1 )) && pad=1

    printf "${color2} ${label} ${COLOR_RESET}%*s${color1}${3}${COLOR_RESET}\n" "$pad"
}

# Affiche un message avec une boîte
print_box() {
    local padding=1
    local args=("$@")
    local last_index=$((${#args[@]} - 1))
    local box_width="${args[$last_index]}"
    local lines=("${args[@]:0:$last_index}")

    printf '┌'
    printf '─%.0s' $(seq 1 "$box_width")
    printf '┐\n'

    for line in "${lines[@]}"; do
        clean_line=$(echo -e "$line" | sed -r 's/\x1B\[[0-9;]*[mK]//g')
        space_count=$((box_width - ${#clean_line} - padding))
        printf '│'
        printf ' %.0s' $(seq 1 $padding)
        printf "%b" "$line"
        printf ' %.0s' $(seq 1 $space_count)
        printf '│\n'
    done

    printf '└'
    printf '─%.0s' $(seq 1 "$box_width")
    printf '┘\n'
}

# Affiche un en-tête
print_header() {
    printf "\n${COLOR_HIGHLIGHT_FG}${1}${COLOR_RESET}\n"
}

# Gère l'état de retour succès
set_success() {
    print_msg "OK" "$1" "$2"
    rm -f NAAC_error.log
    return 0
}

# Gère l'état de retour erreur
set_error() {
    print_msg "ERROR" "$1" "$2"
    printf "\n\n"
    cat NAAC_error.log
    rm -f NAAC_error.log
    return 1
}

# Efface l'écran
clear_screen() {
    printf '%b\n' '\033[2J\033[:H'
}

# l'utilisateur est chroot
check_isroot() {
    if [ "$(id -u)" != "0" ]; then
        print_msg "ERROR" "SCRIPT" "This script must be run as root"
        printf "\n\n"
        print_box "${COLOR_OK_FG}In order to run in as root use :${COLOR_RESET}" \
                  "" \
                  "${COLOR_OK_FG}$ sudo bash -i ./install.sh${COLOR_RESET}" \
                  80
        
        return 1
    else
        print_msg "OK" "SCRIPT" "Script run with root privileges"
        return 0
    fi
}

# Vérifie si une comande existe
has_command() {
  command -v "$@" >/dev/null 2>&1
}

# Verifie si un script est exécuté ou sourcé
is_sourced() {
   if [ -n "$ZSH_VERSION" ]; then 
       case $ZSH_EVAL_CONTEXT in *:file:*) return 1;; esac
   else
       case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 1;; esac
   fi
   return 0
}

# Détermine si l'on est dans un shell interactif
is_interactive_shell() {
    [[ $- == *i* ]]
}

# Affiche un dialogue oui/non suivant si l'on est en mode silencieux ou non
print_dialog() {
    if [[ "$1" == "no" ]] && is_interactive_shell; then
        dialog "Yes" "No" "${2}"

        if [ "$REPLY" = "1" ]; then
            return 0
        else
            return 1
        fi
    else
        return 0
    fi
}

dialog() {
    local selected=0
    local box_width=80
    local padding_h=2
    local padding_v=1
    local inner_width=$((box_width - 2 - 2 * padding_h))

    printf '\n\e[?25l'

    box_line() {
        local content="$1"
        local display_content
        display_content="$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')"

        local content_len=${#display_content}
        local pad_right=$((inner_width - content_len))

        printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}"
        printf "%*s" $padding_h ""
        printf "${COLOR_HIGHLIGHT_FG_REGULAR}%b${COLOR_RESET}" "$content"
        printf "%*s" $pad_right ""
        printf "%*s" $padding_h ""
        printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}\n"
    }

    box_empty() {
        printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}"
        printf "%*s" $((box_width-2)) ""
        printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}\n"
    }

    draw_choices() {
        local choice_line=""
        if (( selected == 0 )); then
            choice_line="${COLOR_OK_BG}  ${1}  ${COLOR_RESET}${COLOR_CRITICAL_FG}  ${2}  ${COLOR_RESET}"
        else
            choice_line="${COLOR_OK_FG}  ${1}  ${COLOR_RESET}${COLOR_CRITICAL_BG}  ${2}  ${COLOR_RESET}"
        fi
        box_line "$choice_line"
    }

    local total_lines=$((1 + padding_v + 3 + padding_v + 1))

    draw_dialog() {
        printf "${COLOR_HIGHLIGHT_FG}┌%s┐${COLOR_RESET}\n" "$(printf '─%.0s' $(seq 1 $((box_width-2))))"
        for ((i=0;i<padding_v;i++)); do box_empty; done
        box_line "$3"
        box_empty
        draw_choices "$@"
        for ((i=0;i<padding_v;i++)); do box_empty; done
        printf "${COLOR_HIGHLIGHT_FG}└%s┘${COLOR_RESET}\n" "$(printf '─%.0s' $(seq 1 $((box_width-2))))"
    }

    draw_dialog "$@"

    while :; do
        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key2
                key+="$key2"
                case "$key" in
                    $'\x1b[D'|$'\x1b[C')
                        if [[ "$key" == $'\x1b[D' ]]; then
                            selected=0
                        else
                            selected=1
                        fi
                        printf "\033[%uA" $total_lines
                        draw_dialog "$@"
                        ;;
                esac
                ;;
            "")
                printf '\n'
                printf '\e[?25h'
                if (( selected == 0 )); then
                    REPLY="1"
                else
                    REPLY="0"
                fi
                break
                ;;
        esac
    done
}

# Quitte l'installation proprement
abort_app() {
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate
    fi

    is_sourced
    if [ $? -eq 1 ]; then
        return 1
    else
        exit 1
    fi
}

# Affiche un message d'erreur et quitte l'installation
quit_installation() {
    printf "\n\n"
    print_msg "INFO" "Quit installation"
    printf "\n\n"

    abort_app
}

# Affiche le message de démarrage
start_message() {
    printf "${COLOR_HIGHLIGHT_FG}"
    printf "▗▄▄▄▖▗▖  ▗▖ ▗▄▄▖▗▄▄▄▖ ▗▄▖ ▗▖   ▗▖    ▗▄▖ ▗▄▄▄▖▗▄▄▄▖ ▗▄▖ ▗▖  ▗▖\n"
    printf "  █  ▐▛▚▖▐▌▐▌     █  ▐▌ ▐▌▐▌   ▐▌   ▐▌ ▐▌  █    █  ▐▌ ▐▌▐▛▚▖▐▌\n"
    printf "  █  ▐▌ ▝▜▌ ▝▀▚▖  █  ▐▛▀▜▌▐▌   ▐▌   ▐▛▀▜▌  █    █  ▐▌ ▐▌▐▌ ▝▜▌\n"
    printf "▗▄█▄▖▐▌  ▐▌▗▄▄▞▘  █  ▐▌ ▐▌▐▙▄▄▖▐▙▄▄▖▐▌ ▐▌  █  ▗▄█▄▖▝▚▄▞▘▐▌  ▐▌\n"
    printf "${COLOR_RESET}\n\n"
}

# Message de fin
end_message() {
    printf "\n\n${COLOR_HIGHLIGHT_BG}"
    printf " Install completed sucessfully ${COLOR_RESET}\n"
}

#= MAIN FEATURES ===================================================================================================

git_clone_or_update() {
    if has_command git; then
        if [ -d "$REPO_DIR" ] && [ -d "$REPO_DIR/.git" ]; then
            git_update
        else
            git_clone
        fi
    else
        set_error "GIT" "Git is not installed, please install git to continue"
    fi
}

git_update() {
    print_msg "OK" "GIT" "Updating NAAC repository"
    cd $REPO_DIR
    if git pull > /dev/null 2>NAAC_error.log; then
        set_success "GIT" "NAAC repository updated successfully"
    else
        set_error "GIT" "NAAC repository update error"
        return 1
    fi

    return 0
}

git_clone() {
    print_msg "OK" "GIT" "Cloning NAAC repository"
    if git clone $REPOSITORY $REPO_DIR > /dev/null 2>NAAC_error.log; then
        set_success "GIT" "NAAC repository updated successfully"
        cd $REPO_DIR
    else
        set_error "GIT" "NAAC repository update error"
        return 1
    fi

    return 0
}

# Installation des packages de VENV
install_venv() {
    if grep -qi ubuntu /etc/os-release 2>/dev/null; then
        if apt install python3-venv -y > /dev/null 2>NAAC_error.log; then
            set_success "VENV" "VENV package installed successfully"
        else
            set_error "VENV" "VENV package installation error"
        fi
    fi      

    return
}

# Création et activation d'un environnement virtuel
create_venv() {
    print_msg "OK" "VENV" "Python in use : $PYTHON3"
    if $PYTHON3 -m venv $VENV_DIR --system-site-packages > /dev/null 2>NAAC_error.log; then
        set_success "VENV" "Creating virtual environment in $VENV_DIR"
    else
        set_error "VENV" "Virtual environment creation error"
    fi

    return
}

# Active le VENV
activate_venv() {
    if source $VENV_DIR/bin/activate > /dev/null 2>NAAC_error.log; then
        set_success "VENV" "Virtual environment activated successfully"

        print_msg "OK" "VENV" "Redirect python binary to virtual environment"
        PYTHON3="$VENV_DIR/bin/python3"
    else
        set_error "VENV" "Virtual environment activation error"
    fi

    return
}

# Met à jour PIP
upgrading_pip() {
    if $PYTHON3 -m pip install --upgrade pip > /dev/null 2>NAAC_error.log; then
        set_success "PIP" "PIP upgraded successfully"
    else
        set_error "PIP" "PIP upgraded error"
    fi

    return
}

install_requirements() {
    if $PYTHON3 -m pip install -r "requirements.txt" > /dev/null 2>naac_error.log; then
        set_success "NAAC" "Requirements installed successfully"
    else
        set_error "NAAC" "Failed to install requirements"
    fi
}

# Compilation des packages python
build_module() {
    if $PYTHON3 -m pip install "$MODULE_DIR" > /dev/null 2>naac_error.log; then
        set_success "MOTD" "Module built successfully"
    else
        set_error "MOTD" "Failed to build module"
    fi
}

# Nettoyage des fichiers
clean_module() {
    if {
        $PYTHON3 setup.py clean --all &&
        rm -rf *.egg-info
        rm -rf __pycache__
    } > /dev/null 2>naac_error.log; then
        set_success "MOTD" "Module cleaned successfully"
    else
        set_error "MOTD" "Failed to cleaning module"
    fi
}

# Création d'un lien symbolique vers /usr/local/bin
link_module() {
    if print_dialog $SILENT "Create a symbolic link to naac_motd in /usr/local/bin ?"; then
        print_msg "OK" "MOTD" "Linking module to /usr/local/bin"
        ln -sf $VENV_DIR/bin/naac_motd /usr/local/bin/naac_motd
    else
        print_msg "INFO" "MOTD" "Skipping symbolic link creation"
    fi
}

print_is_silentmode() {
    if [ "$SILENT" = "yes" ]; then
        print_msg "INFO" "SCRIPT" "Silent mode is enabled"
    fi
}

# Créé la configuration de base
init_configuration() {
    if has_command systemctl; then
        print_msg "OK" "NAAC" "Configuration initialized"
        mkdir -p "/etc/NAAC/"

        local input_file="$MODULE_DIR/ressources/naac_motd.services"
        local template_file="$MODULE_DIR/ressources/naac_motd.yaml"
        local output_file="/etc/naac/naac_motd.yaml"

        local services_block=""

        while IFS=";" read -r name svc || [[ -n $name ]]; do
            [ -z "$svc" ] && continue

            if systemctl status "${svc}.service" &>/dev/null; then
                services_block+="        ${name}: ${svc}"$'\n'
            fi
        done < "$input_file"

        awk -v block="$services_block" '
        {
            if ($0 ~ /\{services\}/) {
                gsub(/\{services\}/, "")
                printf "%s", block
            } else {
                print
            }
        }
        ' "$template_file" > "$output_file"
    fi
}

# Affiche l'aide
print_help() {
    script="${BASH_SOURCE[0]##*/}"

    cat <<EOF
Usage: $script [OPTIONS]

Options:
  --silent          Disable all questions and enable all features
  -h, --help        Show this help message and exit

Examples:
  $script --silent

EOF
}

main() {
    while [ $# -gt 0 ]; do
        case $1 in
            --silent) 
                SILENT=yes
            ;;
            --help|-h)
                print_help
                abort_app
                return
            ;;
        esac
        shift
    done    

    clear_screen
    start_message

    print_is_silentmode

    check_isroot         || { quit_installation; return; }
    git_clone_or_update  || { quit_installation; return; }

    print_header "Environnement installation\n"
    install_venv         || { quit_installation; return; }
    create_venv          || { quit_installation; return; }
    activate_venv        || { quit_installation; return; }
    upgrading_pip        || { quit_installation; return; }
    install_requirements || { quit_installation; return; }
    build_module         || { quit_installation; return; }
    clean_module         || { quit_installation; return; }
    #init_configuration
    link_module

    end_message

    printf "\n\n"

}

main "$@"