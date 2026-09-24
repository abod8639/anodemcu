#!/bin/bash

# Arduino CLI Manager - Ports Module
# This file contains port selection and serial monitor functions

function select_port() {
    print_header
    echo -e "${C_GREEN}==> Detecting available ports...${C_RESET}"
    
    local board_list
    # Use run_arduino_cli_command for better error handling
    if ! board_list=$(run_arduino_cli_command board list | awk 'NR>1'); then
        echo -e "${C_RED}Failed to detect ports. Please check your connections.${C_RESET}"
        press_enter_to_continue
        return 1
    fi

    # Filter out empty lines
    board_list=$(echo "$board_list" | sed '/^[[:space:]]*$/d')

    if [ -z "$board_list" ]; then
        echo -e "${C_RED}No connected boards or ports found.${C_RESET}"
        local use_default
        read -rp "$(echo -e "Use default port ${C_YELLOW}$DEFAULT_PORT${C_RESET}? [Y/n]: ")" use_default
        if [[ -z "$use_default" || "$use_default" =~ ^[Yy]$ ]]; then
            PORT="$DEFAULT_PORT"
            echo -e "${C_GREEN}Using default port: ${C_YELLOW}$DEFAULT_PORT${C_RESET}"
            save_config # Save the port selection to config
            sleep 1
            return 0
        else
            read -rp "Enter custom port (e.g. /dev/ttyUSB0): " custom_port
            if [[ -n "$custom_port" ]]; then
                PORT="$custom_port"
                echo -e "${C_GREEN}Using custom port: ${C_YELLOW}$PORT${C_RESET}"
                save_config
                sleep 1
                return 0
            fi
        fi
        return 1
    fi

    local choice
    if command -v fzf &> /dev/null; then
        # Use fzf if available for better UX
        echo -e "${C_GREEN}==> Select a port:${C_RESET}"
        choice=$(echo "$board_list" | \
            fzf --height=50% \
                --reverse \
                --header="Use arrows to move, Enter to select" \
                --prompt="Select port > " \
                --ansi
        )
    else
        # Fallback to simple select menu
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a better selection experience.${C_RESET}"
        echo -e "${C_GREEN}==> Available ports:${C_RESET}"
        
        local -a options=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && options+=("$line")
        done <<< "$board_list"
        
        select opt in "${options[@]}" "Cancel"; do
            if [[ "$opt" == "Cancel" ]]; then
                return 1
            elif [[ -n "$opt" ]]; then
                choice="$opt"
                break
            fi
        done
    fi

    if [[ -n "$choice" ]]; then
        # Extract port from the selected line (first column)
        PORT=$(echo "$choice" | awk '{print $1}')
        
        echo -e "\n${C_GREEN}Selected:${C_RESET}"
        echo -e "${C_CYAN}Port:${C_RESET} ${C_YELLOW}${PORT}${C_RESET}"
        
        save_config # Save the port selection to config
        sleep 1
        return 0
    else
        echo -e "${C_RED}No selection made.${C_RESET}"
        sleep 1
        return 1
    fi
}


function open_serial() {
    print_header
    echo -e "${C_GREEN}==> Opening Serial Monitor...${C_RESET}"

    local selected_port="${PORT:-}"
    
    if [[ -z "$selected_port" ]]; then
        local board_list
        board_list=$(run_arduino_cli_command board list | awk 'NR>1')
        board_list=$(echo "$board_list" | sed '/^[[:space:]]*$/d')

        if [ -z "$board_list" ]; then
            echo -e "${C_YELLOW}No auto-detected boards found.${C_RESET}"
            read -rp "Enter port to monitor (e.g. /dev/ttyUSB0, /dev/ttyACM0): " manual_port
            if [[ -n "$manual_port" ]]; then
                selected_port="$manual_port"
                PORT="$selected_port"
                save_config
            else
                echo -e "${C_RED}No port specified. Cannot open serial monitor.${C_RESET}"
                press_enter_to_continue
                return
            fi
        elif [ "$(echo "$board_list" | wc -l)" -eq 1 ]; then
            selected_port=$(echo "$board_list" | awk '{print $1}')
            echo -e "${C_GREEN}Auto-selected port: ${C_YELLOW}${selected_port}${C_RESET}"
            PORT="$selected_port"
            save_config
        else
            echo -e "${C_YELLOW}Multiple boards detected. Please select one:${C_RESET}"
            local choice
            if command -v fzf &> /dev/null; then
                choice=$(echo "$board_list" | fzf --reverse --header="Select a board/port to monitor" --prompt="Selection: ")
            else
                local -a options=()
                while IFS= read -r line; do [[ -n "$line" ]] && options+=("$line"); done <<< "$board_list"
                select opt in "${options[@]}" "Cancel"; do
                    if [[ "$opt" == "Cancel" ]]; then return;
                    elif [[ -n "$opt" ]]; then choice="$opt"; break; fi
                done
            fi

            if [[ -n "$choice" ]]; then
                selected_port=$(echo "$choice" | awk '{print $1}')
                PORT="$selected_port"
                save_config
            else
                echo -e "${C_RED}No selection made. Aborting.${C_RESET}"
                press_enter_to_continue
                return
            fi
        fi
    fi

    # 2. Select baud rate
    local current_baud="${BAUD:-$DEFAULT_BAUD}"
    local use_current_prompt="Use current baud rate (${C_YELLOW}$current_baud${C_RESET})? [Y/n]: "
    read -rp "$(echo -e "$use_current_prompt")" use_current
    echo

    if [[ "$use_current" =~ ^[Nn]$ ]]; then
        echo -e "${C_GREEN}==> Select a baud rate (current: ${C_YELLOW}$current_baud${C_GREEN})${C_RESET}"

        local baud_rates=(
        "9600"
        "19200"
        "38400"
        "57600"
        "74880"
        "115200"
        "230400"
        "250000"
        "500000"
        "1000000"
        "Custom"
        )

        local selected_baud

        if command -v fzf &>/dev/null; then
            selected_baud=$(printf "%s\n" "${baud_rates[@]}" | fzf \
                --reverse \
                --cycle \
                --height=50% \
                --prompt="Current baud rate " \
                --header="Select a baud rate" \
                --border \
                --color=prompt:green \
                --query=" ")
        else
            # For the select menu, create a new array with the current value marked.
            local menu_options=()
            for rate in "${baud_rates[@]}"; do
                if [[ "$rate" == "$current_baud" ]]; then
                    menu_options+=("$rate <== current")
                else
                    menu_options+=("$rate")
                fi
            done
            menu_options+=("Cancel")

            select choice in "${menu_options[@]}"; do
                if [[ "$choice" == "Cancel" ]]; then
                    return
                fi
                # Remove the marker before setting the baud rate
                selected_baud=${choice% *<==*}
                break
            done
        fi

        if [[ -z "$selected_baud" ]]; then
            echo -e "${C_YELLOW}No baud rate selected, using current: $current_baud${C_RESET}"
            # BAUD remains unchanged
        elif [[ "$selected_baud" == "Custom" ]]; then
            read -rp "Enter custom baud rate: " custom_baud
            if [[ -n "$custom_baud" ]]; then
                BAUD="$custom_baud"
            else
                echo -e "${C_YELLOW}No custom baud rate entered, using current: $current_baud${C_RESET}"
            fi
        else
            BAUD="$selected_baud"
        fi
    fi

    # 3. Open monitor
    local ptype
    ptype=$(detect_project_type "$PROJECT")
    local active_baud="${BAUD:-$DEFAULT_BAUD}"

    echo -e "${C_GREEN}==> Opening Serial Monitor on port ${PORT} at ${active_baud} baud (${ptype})...${C_RESET}"
    echo -e "${C_YELLOW}(Press Ctrl+C to exit)${C_RESET}"
    sleep 1

    if [[ "$ptype" == "espidf" ]]; then
        (cd "$PROJECT" && run_idf_command -p "${PORT}" -b "${active_baud}" monitor)
    elif [[ "$ptype" == "platformio" ]]; then
        (cd "$PROJECT" && pio device monitor -p "${PORT}" -b "${active_baud}")
    else
        arduino-cli monitor -p "${PORT}" --config "baudrate=${active_baud}"
    fi
    
    echo # Add a newline for better formatting after monitor exits
    press_enter_to_continue
}

