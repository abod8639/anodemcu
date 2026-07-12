#!/bin/bash

# Arduino CLI Manager - Projects Module
# This file contains project management functions

function add_to_history() {
    local path="$1"
    if [[ -z "$path" || "$path" == "$DEFAULT_PROJECT" || ! -d "$path" ]]; then
        return
    fi

    # Check if the project is supported (not unknown)
    local ptype
    ptype=$(detect_project_type "$path")
    if [[ "$ptype" == "unknown" ]]; then
        return
    fi

    # Normalize path
    path=$(realpath "$path")

    # Create temporary file
    local temp_file
    temp_file=$(mktemp)

    # Put new path at top
    echo "$path" > "$temp_file"

    # Append existing history, filtering out duplicates and keeping only directories that still exist
    if [[ -f "$HISTORY_FILE" ]]; then
        while IFS= read -r line; do
            if [[ -d "$line" && "$line" != "$path" ]]; then
                echo "$line" >> "$temp_file"
            fi
        done < "$HISTORY_FILE"
    fi

    # Keep only top 10 items
    head -n 10 "$temp_file" > "$HISTORY_FILE"
    rm -f "$temp_file"
}

function _create_new_project_prompt() {
    print_header
    echo -e "${C_GREEN}==> Select Platform:${C_RESET}"
    echo -e " 1) Arduino"
    echo -e " 2) ESP-IDF"
    echo -e " 3) PlatformIO"
    read -rp "Choice [1/2/3]: " plat_choice
    
    read -rp "Enter new project name: " name
    if [[ -z "$name" ]]; then
        echo -e "${C_RED}Project name cannot be empty.${C_RESET}"
        sleep 1
        return
    fi

    local target_dir="$SKETCH_DIR/$name"

    case "$plat_choice" in
        2)
            echo -e "${C_GREEN}Creating ESP-IDF project...${C_RESET}"
            (cd "$SKETCH_DIR" && run_idf_command create-project "$name")
            PROJECT="$target_dir"
            ;;
        3)
            echo -e "${C_GREEN}Creating PlatformIO project...${C_RESET}"
            read -rp "Enter Board ID (e.g. esp32dev, uno): " board_id
            if [[ -z "$board_id" ]]; then
                echo -e "${C_RED}Board ID is required for PlatformIO.${C_RESET}"
                sleep 1
                return
            fi
            mkdir -p "$target_dir"
            (cd "$target_dir" && pio project init -b "$board_id")
            PROJECT="$target_dir"
            ;;
        *)
            echo -e "${C_GREEN}Creating Arduino project...${C_RESET}"
            run_arduino_cli_command sketch new "$target_dir"
            PROJECT="$target_dir"
            ;;
    esac
    add_to_history "$PROJECT"
}

function select_or_create_project() {
    print_header

    if command -v fzf &> /dev/null; then 
        # Load history
        local history_paths=""
        if [[ -f "$HISTORY_FILE" ]]; then
            while IFS= read -r line; do
                if [[ -d "$line" ]]; then
                    history_paths+="$line"$'\n'
                fi
            done < "$HISTORY_FILE"
        fi
        
        # Remove trailing newline from history_paths
        history_paths="${history_paths%$'\n'}"

        # Get other projects
        local other_projects=""
        if command -v fd &> /dev/null; then
            other_projects=$(fd . "$SKETCH_DIR" --type d --max-depth 1)
        else
            other_projects=$(find "$SKETCH_DIR" -mindepth 1 -maxdepth 1 -type d)
        fi

        # Remove projects that are already in history to avoid duplication in FZF list
        local filtered_projects=""
        while IFS= read -r proj; do
            if [[ -n "$proj" ]]; then
                if ! echo "$history_paths" | grep -qFx "$proj"; then
                    filtered_projects+="$proj"$'\n'
                fi
            fi
        done <<< "$other_projects"
        filtered_projects="${filtered_projects%$'\n'}"

        local fzf_list="--- CREATE NEW PROJECT ---"$'\n'"--- BROWSE CUSTOM PATH ---"
        if [[ -n "$history_paths" ]]; then
            fzf_list+=$'\n'"--- RECENT PROJECTS ---"$'\n'"$history_paths"
        fi
        if [[ -n "$filtered_projects" ]]; then
            fzf_list+=$'\n'"--- OTHER PROJECTS ---"$'\n'"$filtered_projects"
        fi

        local choice
        choice=$(echo "$fzf_list" | \
            fzf --reverse --ansi \
                --prompt="Select or create a project: " \
                --height=70% \
                --header "Enter to select." \
                --preview='bash -c '"'"'
                    dir="$1"
                    if [[ "$dir" == ---* ]]; then exit 0; fi
                    if [ -f "$dir/platformio.ini" ]; then
                        printf "  \033[38;2;180;190;254mPlatform:\033[0m \033[38;2;203;166;247mPlatformIO\033[0m\n"
                    elif [ -f "$dir/CMakeLists.txt" ] && grep -q "project.cmake" "$dir/CMakeLists.txt" 2>/dev/null; then
                        printf "  \033[38;2;180;190;254mPlatform:\033[0m \033[38;2;243;139;168mESP-IDF\033[0m\n"
                    elif [ -f "$dir/sdkconfig" ] || [ -f "$dir/sdkconfig.defaults" ] || [ -f "$dir/idf_component.yml" ]; then
                        printf "  \033[38;2;180;190;254mPlatform:\033[0m \033[38;2;243;139;168mESP-IDF\033[0m\n"
                    elif ls "$dir"/*.ino >/dev/null 2>&1; then
                        printf "  \033[38;2;180;190;254mPlatform:\033[0m \033[38;2;166;227;161mArduino\033[0m\n"
                    else
                        printf "  \033[38;2;180;190;254mPlatform:\033[0m \033[38;2;249;226;175mUnknown\033[0m\n"
                    fi
                    printf "\033[38;2;203;166;247m── CONTENTS ──────────────────────────\033[0m\n"
                    ls -lah "$dir" 2>/dev/null | head -15
                '"'"' -- {}' \
                --preview-window=right:45%:wrap
        )

        if [[ -z "$choice" || "$choice" == "--- RECENT PROJECTS ---" || "$choice" == "--- OTHER PROJECTS ---" ]]; then
            return # User pressed Esc or selected a header
        elif [[ "$choice" == "--- CREATE NEW PROJECT ---" ]]; then
            _create_new_project_prompt
        elif [[ "$choice" == "--- BROWSE CUSTOM PATH ---" ]]; then
            browse_custom_path
        else
            PROJECT="$choice"
            add_to_history "$PROJECT"
        fi
    else
        # Fallback to the original menu if fzf is not installed
        echo -e "${C_YELLOW}Tip: Install 'fzf' for a better project selection experience.${C_RESET}"
        sleep 1
        print_header
        echo -e "${C_GREEN}==> (1) Select an existing sketch\n==> (2) Create a new sketch\n==> (3) Browse custom path${C_RESET}"
        read -rp "[1/2/3]: " menu_choice
        if [[ "$menu_choice" == "2" ]]; then
            _create_new_project_prompt
        elif [[ "$menu_choice" == "3" ]]; then
            browse_custom_path
        else
            echo -e "${C_GREEN}==> Select a project from $SKETCH_DIR:${C_RESET}"
            local current_dir
            current_dir=$(pwd)
            cd "$SKETCH_DIR" || return

            select project_dir in */ "Cancel"; do
                if [[ "$project_dir" == "Cancel" ]]; then
                    break
                elif [[ -n "$project_dir" ]]; then
                    PROJECT="$SKETCH_DIR/${project_dir%/}"
                    add_to_history "$PROJECT"
                    break
                else
                    echo -e "${C_RED}Invalid selection. Please try again.${C_RESET}"
                fi
            done
            cd "$current_dir"
        fi
    fi
    resolve_project_type_ambiguity "$PROJECT"
}

function browse_custom_path() {
    print_header
    echo -e "${C_GREEN}==> Browse for Arduino project${C_RESET}"
    echo ""
    
    if command -v fzf &> /dev/null; then
        # Interactive directory browsing with fzf
        echo -e "${C_CYAN}Use fzf to browse directories interactively${C_RESET}"
        echo -e "${C_YELLOW}Tip: Type to filter, Enter to select, Esc to cancel${C_RESET}"
        echo ""
        
        local start_dir="${1:-$HOME}"
        local selected_dir
        
        # Build the async scan command based on available tools.
        # Regex matches ONLY: platformio.ini, CMakeLists.txt, *.ino, sdkconfig, sdkconfig.defaults, idf_component.yml
        local _scan_cmd
        if command -v fd &> /dev/null; then
            _scan_cmd="fd -H -t f -d 5 --exclude .git \
'(platformio\\.ini|CMakeLists\\.txt|\\.ino|sdkconfig|sdkconfig\\.defaults|idf_component\\.yml)\$' \
\"$start_dir\" | bash -c 'while IFS= read -r f; do
    case \"\$f\" in
        *platformio.ini)        dirname \"\$f\" ;;
        *CMakeLists.txt)        grep -q \"project.cmake\" \"\$f\" 2>/dev/null && dirname \"\$f\" ;;
        *sdkconfig|*sdkconfig.defaults|*idf_component.yml) dirname \"\$f\" ;;
        *.ino)                  dirname \"\$f\" ;;
    esac
done' | sort -u"
        else
            _scan_cmd="find \"$start_dir\" -maxdepth 5 -type f \
\( -name 'platformio.ini' -o -name 'CMakeLists.txt' -o -name '*.ino' \
   -o -name 'sdkconfig' -o -name 'sdkconfig.defaults' -o -name 'idf_component.yml' \) \
! -path '*/.*' 2>/dev/null | bash -c 'while IFS= read -r f; do
    case \"\$f\" in
        *platformio.ini)        dirname \"\$f\" ;;
        *CMakeLists.txt)        grep -q \"project.cmake\" \"\$f\" 2>/dev/null && dirname \"\$f\" ;;
        *sdkconfig|*sdkconfig.defaults|*idf_component.yml) dirname \"\$f\" ;;
        *.ino)                  dirname \"\$f\" ;;
    esac
done' | sort -u"
        fi

        selected_dir=$(fzf \
                --reverse \
                --ansi \
                --prompt="Select project directory > " \
                --header="Browse project directories (scanning... type to filter, Enter to select)" \
                --bind "start:reload:$_scan_cmd" \
                --preview='bash -c '"'"'
                    dir="$1"
                    printf "\033[38;2;203;166;247m── PROJECT INFO ────────────────────────\033[0m\n"
                    if [ -f "$dir/platformio.ini" ]; then
                        printf "  \033[38;2;180;190;254mPlatform:\033[0m \033[38;2;203;166;247mPlatformIO\033[0m\n"
                    elif [ -f "$dir/CMakeLists.txt" ] && grep -q "project.cmake" "$dir/CMakeLists.txt" 2>/dev/null; then
                        printf "  \033[38;2;180;190;254mPlatform:\033[0m \033[38;2;243;139;168mESP-IDF\033[0m\n"
                    elif [ -f "$dir/sdkconfig" ] || [ -f "$dir/sdkconfig.defaults" ] || [ -f "$dir/idf_component.yml" ]; then
                        printf "  \033[38;2;180;190;254mPlatform:\033[0m \033[38;2;243;139;168mESP-IDF\033[0m\n"
                    elif ls "$dir"/*.ino >/dev/null 2>&1; then
                        printf "  \033[38;2;180;190;254mPlatform:\033[0m \033[38;2;166;227;161mArduino\033[0m\n"
                    else
                        printf "  \033[38;2;180;190;254mPlatform:\033[0m \033[38;2;249;226;175mUnknown\033[0m\n"
                    fi
                    printf "  \033[38;2;180;190;254mPath:\033[0m %s\n" "$dir"
                    printf "\033[38;2;203;166;247m── CONTENTS ────────────────────────────\033[0m\n"
                    ls -lah "$dir" 2>/dev/null | head -15
                '"'"' -- {}' \
                --preview-window=right:50%:wrap \
                --height=80% \
            < /dev/null)
        
        if [[ -z "$selected_dir" ]]; then
            echo -e "${C_YELLOW}No directory selected.${C_RESET}"
            sleep 1
            return
        fi
        
        custom_path="$selected_dir"
    else
        # Fallback to manual path entry if fzf is not available
        echo -e "${C_YELLOW}Tip: Install 'fzf' for interactive directory browsing${C_RESET}"
        echo -e "${C_YELLOW}Enter the full path to your project directory${C_RESET}"
        echo -e "${C_CYAN}(The directory should contain a project file like .ino, CMakeLists.txt, or platformio.ini)${C_RESET}"
        echo ""
        
        read -rp "Path: " custom_path
        
        # Expand ~ to home directory
        custom_path="${custom_path/#\~/$HOME}"
        
        if [[ -z "$custom_path" ]]; then
            echo -e "${C_RED}No path entered.${C_RESET}"
            sleep 1
            return
        fi
    fi
    
    # Validate the selected path
    if [[ ! -d "$custom_path" ]]; then
        echo -e "${C_RED}Error: Directory does not exist: $custom_path${C_RESET}"
        sleep 2
        return
    fi
    
    # Check project type
    local ptype
    ptype=$(detect_project_type "$custom_path")
    
    if [[ "$ptype" == "unknown" ]]; then
        echo -e "${C_YELLOW}Warning: No Arduino, ESP-IDF, or PlatformIO project found in this directory.${C_RESET}"
        echo -e "${C_CYAN}Found in: $custom_path${C_RESET}"
        read -rp "Use this path anyway? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${C_RED}Cancelled.${C_RESET}"
            sleep 1
            return
        fi
    else
        echo -e "${C_GREEN}Detected project type: $ptype ✓${C_RESET}"
    fi
    
    PROJECT="$custom_path"
    add_to_history "$PROJECT"
    echo -e "${C_GREEN}Selected project: ${C_YELLOW}$PROJECT${C_RESET}"
    sleep 1
}


function edit_project_nvim() {
    print_header
    if [[ -z "$PROJECT" || "$PROJECT" == "$DEFAULT_PROJECT" ]]; then
        echo -e "${C_RED}No project selected. Please select a project first.${C_RESET}"
        select_or_create_project
        # If user cancelled, PROJECT is still empty. Return to menu.
        if [[ -z "$PROJECT" || "$PROJECT" == "$DEFAULT_PROJECT" ]]; then
            return
        fi
    fi

    if ! command -v nvim &> /dev/null; then
        echo -e "${C_RED}Error: 'nvim' is not installed or not in your PATH.${C_RESET}"
        echo "Please install it to use this feature."
        press_enter_to_continue
        return
    fi

    local project_name
    project_name=$(basename "$PROJECT")

    echo -e "${C_GREEN}==> Opening project '${project_name}' in nvim...${C_RESET}"
    
    # Change to the project directory and open the main .ino file
    (
        cd "$PROJECT" && nvim "${project_name}.ino"
    )
    
    echo # Add a newline for better formatting after nvim exits
}
