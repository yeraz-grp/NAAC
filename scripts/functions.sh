#!/bin/bash

#trap "quit_installation; return;" INT TERM

#= SETTINGS ========================================================================================================

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

# Affiche un en-tête
print_header() {
    printf "\n${COLOR_HIGHLIGHT_FG}${1}${COLOR_RESET}\n"
}

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

# Verifie si un script est exécuté ou sourcé
is_sourced() {
   if [ -n "$ZSH_VERSION" ]; then 
       case $ZSH_EVAL_CONTEXT in *:file:*) return 1;; esac
   else
       case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 1;; esac
   fi
   return 0
}

# Efface l'écran
clear_screen() {
    printf '%b\n' '\033[2J\033[:H'
}

# Message de fin
end_message() {
    printf "\n\n${COLOR_HIGHLIGHT_BG}"
    printf " VENV activate ${COLOR_RESET}\n"
}

# Affiche un message d'erreur et quitte l'installation
quit_installation() {

    printf "\n\n"
    print_msg "INFO" "Quit installation"
    printf "\n\n"

    tput cnorm; 

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

# Détermine si l'on est dans un shell interactif
is_interactive_shell() {
    [[ $- == *i* ]]
}

choices() {
    local box_width=80
    local padding_h=2
    local padding_v=1
    local inner_width=$((box_width - 2 - 2 * padding_h))

    tput civis

    _choices() {
        local args=("${@:3}")
        local last_index=$((${#args[@]} - 1))

        for i in $(seq 0 $((last_index - 1))); do
            local display_content
            display_content="$(echo -e "${args[$i]}" | sed 's/\x1b\[[0-9;]*m//g')"
            local content_len=$(( ${#display_content} + 4 ))
            local pad_right=$((inner_width - content_len))

            printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}"
            printf "%*s" $padding_h ""
            printf "${COLOR_INFO_BG} %d ${COLOR_RESET} %b" $((i + 1)) "${args[$i]}"
            printf "%*s" $pad_right ""
            printf "%*s" $padding_h ""
            printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}\n"
        done
    }

    _label() {
        local display_content
        display_content="$(echo -e "$2" | sed 's/\x1b\[[0-9;]*m//g')"
        local content_len=$(( ${#display_content} ))
        local pad_right=$((inner_width - content_len))

        printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}"
        printf "%*s" $padding_h ""
        printf "$2"
        printf "%*s" $pad_right ""
        printf "%*s" $padding_h ""
        printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}\n"
    }

    _input() {
        local content=$(printf "Choice [${COLOR_HIGHLIGHT_FG}1-%d${COLOR_RESET}]: " $(( $# - 3 ))) 
        local display_content="$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')"
        local content_len=$(( ${#display_content} ))
        local pad_right=$((inner_width - content_len))

        printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}"
        printf "%*s" $padding_h ""
        printf "$content"        
        tput sc
        printf "%*s" $pad_right ""
        printf "%*s" $padding_h ""
        printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}\n"
    }

    _dialog() {
        printf "${COLOR_HIGHLIGHT_FG}┌%s┐${COLOR_RESET}\n" "$(printf '─%.0s' $(seq 1 $((box_width-2))))"
        for ((i=0;i<padding_v;i++)); do box_empty $((box_width-2)); done
        _label "$@"
        box_empty $((box_width-2))
        _choices "$@"
        box_empty $((box_width-2))
        _input "$@"
        for ((i=0;i<padding_v;i++)); do box_empty $((box_width-2)); done
        printf "${COLOR_HIGHLIGHT_FG}└%s┘${COLOR_RESET}\n" "$(printf '─%.0s' $(seq 1 $((box_width-2))))"
    }

    _dialog "$@"
#    tput cup 12 17
    tput cnorm

    CHOICE=""
    until [[ "$CHOICE" =~ ^[1-4]$ ]]; do
        tput rc
        read -r CHOICE
    done
}

print_choices() {

    if [[ "$1" == "no" ]] && is_interactive_shell; then
        choices "$@"

        if [ "$REPLY" = "1" ]; then
            return 0
        else
            return 1
        fi
    else
        return 0
    fi
}

box_empty() {
    printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}"
    printf "%*s" $1 ""
    printf "${COLOR_HIGHLIGHT_FG}│${COLOR_RESET}\n"
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
        for ((i=0;i<padding_v;i++)); do box_empty $((box_width-2)); done
        box_line "$3"
        box_empty $((box_width-2))
        draw_choices "$@"
        for ((i=0;i<padding_v;i++)); do box_empty $((box_width-2)); done
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