#!/bin/bash

# Arduino CLI Manager - Boards Module
# This file contains board selection and listing functions

function list_all_supported_boards() {
    print_header
    echo -e "${C_GREEN}==> All Supported Boards (use this to find FQBNs):${C_RESET}"
    run_arduino_cli_command board listall 
    echo
    press_enter_to_continue
}

function _select_board_fzf() {
    print_header
    echo -e "${C_GREEN}==> Use interactive search. ${C_YELLOW}Enter${C_RESET} to select.${C_RESET}"
    local choice
    choice=$(run_arduino_cli_command board listall | sed '1d' | \
        fzf --height=50% --reverse --prompt="Select a board: " \
            --header "Enter to select." )
    
    if [[ -n "$choice" ]]; then
        local selected_fqbn
        selected_fqbn=$(echo "$choice" | awk '{for (i=1; i<=NF; i++) {if ($i ~ /.*:.*:.*/) {print $i; break}}}')
        FQBN="$selected_fqbn"
        echo
        echo -e "${C_GREEN}Selected board: ${C_YELLOW}$FQBN${C_RESET}"
        press_enter_to_continue
    fi
}

function _select_board_menu() {
    print_header
    local all_boards
    mapfile -t all_boards < <(run_arduino_cli_command board listall | sed '1d') # Pre-load all boards, remove header

    while true; do
        print_header
        echo -e "${C_GREEN}==> Enter a search term to filter boards.${C_RESET}"
        read -rp "Search (or press Enter for all, 'q' to quit): " search_term

        if [[ "$search_term" == "q" ]]; then
            return
        fi

        local filtered_boards=()
        for board in "${all_boards[@]}"; do
            if [[ -z "$search_term" || "$board" =~ .*$search_term.* ]]; then
                filtered_boards+=("$board")
            fi
        done

        if [ ${#filtered_boards[@]} -eq 0 ]; then
            echo -e "${C_RED}No boards found matching '$search_term'.${C_RESET}"
            sleep 1
            continue # Restart the loop
        fi

        echo
        echo -e "${C_GREEN}==> Select a board:${C_RESET}"
        select choice in "${filtered_boards[@]}" "New Search" "Cancel"; do
            if [[ "$choice" == "New Search" ]]; then
                break # Exit select, re-enter while loop
            elif [[ "$choice" == "Cancel" ]]; then
                return # Exit function
            elif [[ -n "$choice" ]]; then
                # Robustly extract FQBN
                local selected_fqbn
                selected_fqbn=$(echo "$choice" | awk '{for (i=1; i<=NF; i++) {if ($i ~ /.*:.*:.*/) {print $i; break}}}')
                FQBN="$selected_fqbn"
                echo
                echo -e "${C_GREEN}Selected board: ${C_YELLOW}$FQBN${C_RESET}"
                press_enter_to_continue
                return # Exit function
            else
                echo -e "${C_RED}Invalid selection. Please try again.${C_RESET}"
            fi
        done
    done
}

function select_board() {
    print_header
    local ptype
    ptype=$(detect_project_type "$PROJECT")

    if [[ "$ptype" == "espidf" ]]; then
        echo -e "${C_GREEN}==> Select ESP-IDF Target:${C_RESET}"
        read -rp "Enter target (e.g., esp32, esp32s2, esp32s3, esp32c3): " target
        if [[ -n "$target" ]]; then
            (cd "$PROJECT" && run_idf_command set-target "$target")
            echo -e "${C_GREEN}Target set to ${C_YELLOW}$target${C_RESET}"
            press_enter_to_continue
        fi
        return
    elif [[ "$ptype" == "platformio" ]]; then
        echo -e "${C_GREEN}==> Select PlatformIO Board:${C_RESET}"
        read -rp "Enter Board ID (e.g., esp32dev, uno): " board_id
        if [[ -n "$board_id" ]]; then
            if sed -i "s/^board *=.*/board = $board_id/" "$PROJECT/platformio.ini"; then
                echo -e "${C_GREEN}Board updated to ${C_YELLOW}$board_id${C_RESET} in platformio.ini"
            else
                echo -e "${C_RED}Failed to update platformio.ini${C_RESET}"
            fi
            press_enter_to_continue
        fi
        return
    fi

    # Check if fzf is installed for a better experience
    if command -v fzf &> /dev/null; then
        _select_board_fzf
    else
        print_header
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a much better interactive search experience.${C_RESET}"
        echo "(e.g., 'sudo apt install fzf' or 'brew install fzf')"
        sleep 1
        _select_board_menu
    fi
}
