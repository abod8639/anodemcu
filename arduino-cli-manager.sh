#!/bin/bash
set -o pipefail  # Exit on pipe failures

# Arduino CLI Manager - Main Entry Point
#
# Copyright (c) 2025 abod8639
#
# This script is licensed under the MIT License.
# See the LICENSE file for details.

# Get script directory (finds real directory through symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Source all modules in order
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/platform.sh"
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/projects.sh"
source "$SCRIPT_DIR/lib/libraries.sh"
source "$SCRIPT_DIR/lib/boards.sh"
source "$SCRIPT_DIR/lib/ports.sh"
source "$SCRIPT_DIR/lib/sketch.sh"
source "$SCRIPT_DIR/lib/cores.sh"

function platformio_install_lib() {
    print_header
    echo -e "${C_GREEN}==> Install PlatformIO Library${C_RESET}"
    read -rp "Enter library name or ID: " lib_name
    if [[ -n "$lib_name" ]]; then
        (cd "$PROJECT" && pio pkg install -l "$lib_name")
        press_enter_to_continue
    fi
}

# --- Main Menu ---
function main_menu() {
    while true; do
        local ptype
        ptype=$(detect_project_type "$PROJECT")

        print_header
        echo -e " ${C_YELLOW}1 (S) S${C_RESET}elect/Create Project    "
        echo -e " ${C_YELLOW}2 (B)${C_RESET} Select ${C_YELLOW}B${C_RESET}oard           "
        echo -e " ${C_YELLOW}3 (P)${C_RESET} Select ${C_YELLOW}P${C_RESET}ort              "
        echo -e " ${C_YELLOW}4 (C) C${C_RESET}ompile Project          "
        echo -e " ${C_YELLOW}5 (U) U${C_RESET}pload Project           "
        
        if [[ "$ptype" == "espidf" ]]; then
            echo -e " ${C_YELLOW}6 (F)${C_RESET} idf.py menucon${C_YELLOW}f${C_RESET}ig      "
            echo -e " ${C_YELLOW}7 (N)${C_RESET} idf.py clea${C_YELLOW}n${C_RESET}           "
            echo -e " ${C_YELLOW}8 (Z)${C_RESET} idf.py si${C_YELLOW}z${C_RESET}e             "
        elif [[ "$ptype" == "platformio" ]]; then
            echo -e " ${C_YELLOW}6 (O)${C_RESET} pi${C_YELLOW}o${C_RESET} lib install          "
            echo -e " ${C_YELLOW}7 (N)${C_RESET} pio clea${C_YELLOW}n${C_RESET}              "
            echo -e "                         "
        else
            echo -e " ${C_YELLOW}6 (L) L${C_RESET}ist Installed Cores     "
            echo -e " ${C_YELLOW}7 (A)${C_RESET} List ${C_YELLOW}A${C_RESET}ll Supported Boards"
            echo -e " ${C_YELLOW}8 (I) I${C_RESET}nstall Core             " 
        fi 
        echo -e " ${C_YELLOW}9 (M)${C_RESET} Open Serial ${C_YELLOW}M${C_RESET}onitor      "
        echo -e " ${C_YELLOW}0 (E) E${C_RESET}dit Project (nvim)      "
        echo "────────────────────────────────────────────────────────────"
        echo -e " ${C_CYAN}(R)${C_RESET} Manage Libraries"
        echo -e " ${C_CYAN}(H)${C_RESET} Help"
        
        local update_prompt=""
        if [[ -n "$LATEST_VERSION" && "$LATEST_VERSION" != "$VERSION" ]]; then
            update_prompt="(${C_YELLOW}V${C_RESET}) Update to v$LATEST_VERSION"
        fi
        
        echo -e " ${update_prompt}${update_prompt:+, }(${C_RED}Q${C_RESET}) Quit"
        echo "────────────────────────────────────────────────────────────"

        read -rp "Enter your choice: " -n 1 option
        echo

        case $option in
            [1sS]) select_or_create_project ;;
            [2bB]) select_board ;;
            [3pP]) select_port ;;
            [4cC]) compile_sketch ;;
            [5uU]) upload_sketch ;;
            
            [6])
                if [[ "$ptype" == "espidf" ]]; then (cd "$PROJECT" && run_idf_command menuconfig); 
                elif [[ "$ptype" == "platformio" ]]; then platformio_install_lib; 
                else list_installed_cores; fi ;;
            [7])
                if [[ "$ptype" == "espidf" ]]; then (cd "$PROJECT" && run_idf_command clean); press_enter_to_continue;
                elif [[ "$ptype" == "platformio" ]]; then (cd "$PROJECT" && pio run -t clean); press_enter_to_continue;
                else list_all_supported_boards; fi ;;
            [8])
                if [[ "$ptype" == "espidf" ]]; then (cd "$PROJECT" && run_idf_command size); press_enter_to_continue;
                elif [[ "$ptype" == "platformio" ]]; then echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1;
                else install_core; fi ;;
            
            [lL]) list_installed_cores ;;
            [fF]) if [[ "$ptype" == "espidf" ]]; then (cd "$PROJECT" && run_idf_command menuconfig); else echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1; fi ;;
            [oO]) if [[ "$ptype" == "platformio" ]]; then platformio_install_lib; else echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1; fi ;;
            [aA]) list_all_supported_boards ;;
            [nN]) 
                if [[ "$ptype" == "espidf" ]]; then (cd "$PROJECT" && run_idf_command clean); press_enter_to_continue;
                elif [[ "$ptype" == "platformio" ]]; then (cd "$PROJECT" && pio run -t clean); press_enter_to_continue;
                else echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1; fi ;;
            [iI]) install_core ;;
            [zZ]) if [[ "$ptype" == "espidf" ]]; then (cd "$PROJECT" && run_idf_command size); press_enter_to_continue; else echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1; fi ;;
            [9mM]) open_serial ;;
            [0eE]) edit_project_nvim ;;
            [rR]) manage_libraries ;;
            [hH]) show_help ;;

            [vV]) 
                if [[ -n "$LATEST_VERSION" && "$LATEST_VERSION" != "$VERSION" ]]; then
                    update_script
                else
                    echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1
                fi
                ;;

            [qQ]) 
                clear
                print_logo
                echo " Goodbye Genius! V$VERSION"
                break
                ;;
            *) echo -e "${C_RED}Invalid option.${C_RESET}"; sleep 1 ;;
        esac
    done
}

# --- Initialization ---
check_dependencies
mkdir -p "$SKETCH_DIR"

# Load config and save on exit
load_config

# Auto-detect project from argument or current directory
if [[ -n "$1" ]]; then
    arg_path="$(realpath "$1")"
    if [[ "$(detect_project_type "$arg_path")" != "unknown" ]]; then
        PROJECT="$arg_path"
    else
        echo -e "${C_YELLOW}Warning: Provided path '$arg_path' is not a recognized project.${C_RESET}"
        sleep 2
    fi
elif [[ "$(detect_project_type "$(pwd)")" != "unknown" ]]; then
    PROJECT="$(pwd)"
fi

resolve_project_type_ambiguity "$PROJECT"

trap save_config EXIT

check_for_update
main_menu
