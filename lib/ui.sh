#!/bin/bash

# Arduino CLI Manager - UI Module
# This file contains all user interface functions

# --- UI Functions ---

# function print_logo() {
#     echo "                                                                            "
#     echo -e "${C_LOGO}   █████╗  ███╗   ██╗  ██████╗  ██████╗  ███████╗███╗   ███╗  ██████╗ ██╗   ██╗"
#                 echo "  ██╔══██╗ ████╗  ██║ ██╔═══██╗ ██╔══██╗ ██╔════╝████╗ ████║ ██╔════╝ ██║   ██║"
#                 echo "  ███████║ ██╔██╗ ██║ ██║   ██║ ██║  ██║ █████╗  ██╔████╔██║ ██║      ██║   ██║"
#                 echo "  ██╔══██║ ██║╚██╗██║ ██║   ██║ ██╔══██╗ ██╔══╝  ██║╚██╔╝██║ ██║      ██║   ██║"
#                 echo "  ██║  ██║ ██║ ╚████║ ╚██████╔╝ ██████╔╝ ███████╗██║ ╚═╝ ██║ ╚██████╗ ╚██████╔╝"
#              echo -e "  ╚═╝  ╚═╝ ╚═╝  ╚═══╝  ╚═════╝  ╚═════╝  ╚══════╝╚═╝     ╚═╝  ╚═════╝  ╚═════╝ ${C_RESET}"
# }
function print_logo() {
    echo "                                                                            "
    echo -e "${C_LOGO}        █████╗ ███╗   ██╗ ██████╗ ██████╗ ███████╗MSU"
                echo "       ██╔══██╗████╗  ██║██╔═══██╗██╔══██╗██╔════╝MSU"
                echo "       ███████║██╔██╗ ██║██║   ██║██║  ██║█████╗  MSU"
                echo "       ██╔══██║██║╚██╗██║██║   ██║██╔══██╗██╔══╝  MSU"
                echo "       ██║  ██║██║ ╚████║╚██████╔╝██████╔╝███████╗MSU"
             echo -e "       ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝MSU${C_RESET}"
}

function print_header() {
    clear
                                              print_logo
    echo -e "${C_LOGO} ┌────────────────────────────────────────────────────────┐"
                 echo " │                                                        │"
                 echo " │ Select board, serial, compile, upload & monitor easily │"
                 echo " │                                                        │"
              echo -e " └────────────────────────────────────────────────────────┘${C_RESET}"
                                          get_version_line
                 echo "────────────────────────────────────────────────────────────"
                 printf " ${C_SHORTCUT}%-12s${C_RESET} %s\\n" "Project:" "${PROJECT:-$DEFAULT_PROJECT}"
                 
                 local ptype
                 ptype=$(detect_project_type "$PROJECT")
                 local ptype_lbl="${C_YELLOW}Unknown${C_RESET}"
                 case "$ptype" in
                     espidf) ptype_lbl="${C_RED}ESP-IDF${C_RESET}" ;;
                     platformio) ptype_lbl="${C_PURPLE}PlatformIO${C_RESET}" ;;
                     arduino) ptype_lbl="${C_GREEN}Arduino${C_RESET}" ;;
                 esac
                 printf " ${C_SHORTCUT}%-12s${C_RESET} %b\\n" "Platform:" "$ptype_lbl"
                 
                 printf " ${C_SHORTCUT}%-12s${C_RESET} %s\\n" "Board:"   "${FQBN:-   $DEFAULT_FQBN}"
                 printf " ${C_SHORTCUT}%-12s${C_RESET} %s\\n" "Port:"    "${PORT:-   $DEFAULT_PORT}"
                 printf " ${C_SHORTCUT}%-12s${C_RESET} %s\\n" "Baud:"    "${BAUD:-   $DEFAULT_BAUD}"
                 echo "────────────────────────────────────────────────────────────"
}

function get_version_line() {
    local current="${VERSION#v}"
    local latest="${LATEST_VERSION#v}"

    if [[ -n "$LATEST_VERSION" ]]; then
        vercmp_portable "$latest" "$current"
        local result=$?
        if [[ $result -eq 1 ]]; then
            local update_msg="Update available: v$VERSION → v$LATEST_VERSION"
            printf " ${C_YELLOW}%*s${C_RESET}${C_GREEN}%*s \\n" $(( (59 + ${#update_msg}) / 2 )) "$update_msg" $(( (59 - ${#update_msg}) / 2 )) ""
            return
        fi
    fi

    local version_msg=" "
    printf "${C_GREEN} %*s%*s \\n${C_RESET}" $(( (59 + ${#version_msg}) / 2 )) "$version_msg" $(( (59 - ${#version_msg}) / 2 )) ""
}

function press_enter_to_continue() {
    read -p "Press Enter to continue..."
}

function show_help() {
    print_header
    echo -e "${C_GREEN}==> Anode MCU Manager - Quick Help${C_RESET}"
    echo ""
    echo "This tool helps you manage microcontroller projects easily."
    echo ""
    echo -e "${C_SHORTCUT}Getting Started:${C_RESET}"
    echo "  1. Select or create a project (S)"
    echo "  2. Select your board type (B)"
    echo "  3. Connect board and select port (P)"
    echo "  4. Compile your sketch (C)"
    echo "  5. Upload to board (U)"
    echo ""
    echo -e "${C_SHORTCUT}Keyboard Shortcuts:${C_RESET}"
    echo "  S - Select/Create Project    B - Select Board (FQBN)"
    echo "  P - Select Port              C - Compile Project"
    echo "  U - Upload Project           M - Serial Monitor"
    echo "  E - Edit in nvim             L - List Cores"
    echo "  A - List All Boards          I - Install Core"
    echo "  H - Show this help           Q - Quit"
    echo ""
    echo -e "${C_SHORTCUT}Common Workflows:${C_RESET}"
    echo "  ${C_SHORTCUT}New Project:${C_RESET} S → Create new → B → P → C → U"
    echo "  ${C_SHORTCUT}Quick Upload:${C_RESET} U (if project already selected)"
    echo "  ${C_SHORTCUT}Debug Output:${C_RESET} M (opens serial monitor)"
    echo ""
    echo -e "${C_SHORTCUT}Configuration:${C_RESET}"
    echo "  Config file: ~/.anodemcu.conf"
    echo "  Projects directory: $SKETCH_DIR"
    echo ""
    echo -e "${C_SHORTCUT}Official Repository:${C_RESET}"
    echo "  https://github.com/abod8639/anodemcu"
    echo ""
    press_enter_to_continue
}
