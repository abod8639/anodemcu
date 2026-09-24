#!/bin/bash

# Arduino CLI Manager - Cores Module
# This file contains core management and update functions

function list_installed_cores() {
    print_header
    echo -e "${C_GREEN}==> Installed Cores:${C_RESET}"
    run_arduino_cli_command core list
    echo
    press_enter_to_continue
}

function update_script() {
    print_header
    local is_newer=false
    if [[ -n "$LATEST_VERSION" ]]; then
        vercmp_portable "${LATEST_VERSION#v}" "${VERSION#v}"
        [[ $? -eq 1 ]] && is_newer=true
    fi

    if [[ "$is_newer" == true ]]; then
        echo -e "${C_GREEN}==> Update Available! ${C_RESET}"
        echo -e "A new version (${C_YELLOW}v$LATEST_VERSION${C_RESET}) is available."
        echo -e "Your current version is ${C_YELLOW}v$VERSION${C_RESET}."
        echo
        
        # Check if running from a git repository
        if git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree &> /dev/null; then
            read -rp "Update repository using git pull? [Y/n]: " update_choice
            if [[ -z "$update_choice" || "$update_choice" =~ ^[Yy]$ ]]; then
                echo -e "${C_GREEN}==> Pulling latest changes...${C_RESET}"
                if (cd "$SCRIPT_DIR" && git pull --ff-only); then
                    echo -e "${C_GREEN}Update successful! Please restart the script.${C_RESET}"
                    exit 0
                else
                    echo -e "${C_RED}Error: git pull failed. Please update manually.${C_RESET}"
                    press_enter_to_continue
                fi
            else
                echo "Update skipped."
                press_enter_to_continue
            fi
        elif [[ "$SCRIPT_DIR" == /usr/* ]]; then
            echo -e "${C_CYAN}Anode MCU was installed via system package manager (AUR/pacman).${C_RESET}"
            echo -e "Please update using your AUR helper, for example:"
            echo -e "  ${C_YELLOW}yay -Syu anodemcu${C_RESET}  or  ${C_YELLOW}paru -Syu anodemcu${C_RESET}"
            press_enter_to_continue
        else
            echo -e "To update, please download the latest release v$LATEST_VERSION from:"
            echo -e "  ${C_YELLOW}https://github.com/abod8639/anodemcu/releases/latest${C_RESET}"
            press_enter_to_continue
        fi
    else
        echo -e "${C_GREEN}You are already on the latest version (v$VERSION).${C_RESET}"
        press_enter_to_continue
    fi
}


function install_core() {
    print_header
    local core_name=""

    # Check if fzf is installed for a better experience
    if command -v fzf &> /dev/null; then
        echo -e "${C_GREEN}==> Use interactive search to find and select cores.${C_RESET}"
        echo -e "${C_YELLOW}Use TAB to multi-select. Enter to install.${C_RESET}"

        local installed_cores
        installed_cores=$(run_arduino_cli_command core list | awk 'NR>1 {print $1}')

        local choices
        choices=$(run_arduino_cli_command core search --all | sed '1d' | \
            fzf --reverse --prompt="Select core(s) to install: " -m \
                --header "TAB to multi-select, Enter to install."
        )

        if [[ -n "$choices" ]]; then
            echo "$choices" | while read -r choice; do
                core_name=$(echo "$choice" | awk '{print $1}')
                if [[ -n "$core_name" ]]; then
                    echo -e "${C_GREEN}==> Installing '$core_name'...${C_RESET}"
                    if ! arduino-cli core install "$core_name"; then
                        echo -e "${C_RED}Error: Core installation failed for '$core_name'.${C_RESET}"
                    else
                        echo -e "${C_GREEN}Core '$core_name' installed successfully.${C_RESET}"
                    fi
                fi
            done
        else
            echo -e "${C_RED}No core selected.${C_RESET}"
            sleep 1
        fi
        press_enter_to_continue
        return
    else
        # Fallback to menu if fzf is not installed
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a much better interactive search experience.${C_RESET}"
        echo "(e.g., 'sudo apt install fzf' or 'brew install fzf')"
        sleep 1

        echo -e "${C_GREEN}==> Available Cores:${C_RESET}"
        mapfile -t all_cores < <(run_arduino_cli_command core search --all | sed '1d')

        select choice in "${all_cores[@]}" "Cancel"; do
            if [[ "$choice" == "Cancel" ]]; then
                break
            elif [[ -n "$choice" ]]; then
                core_name=$(echo "$choice" | awk '{print $1}')
                break
            else
                echo -e "${C_RED}Invalid selection. Please try again.${C_RESET}"
            fi
        done
    fi

    if [[ -n "$core_name" ]]; then
        echo -e "${C_GREEN}==> Installing '$core_name'...${C_RESET}"
        # Execute directly to show live progress
        if ! arduino-cli core install "$core_name"; then
            echo -e "${C_RED}Error: Core installation failed for '$core_name'. Please check the output above for details.${C_RESET}"
            press_enter_to_continue # Add this here so the user can read the error before the screen clears
            return # Exit the function on failure
        fi
        echo -e "${C_GREEN}Core '$core_name' installed successfully.${C_RESET}"
    else
        echo -e "${C_RED}No core selected or entered.${C_RESET}"
        sleep 1
    fi
    press_enter_to_continue
}
