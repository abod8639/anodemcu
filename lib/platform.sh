#!/bin/bash

# Arduino CLI Manager - Platform Module
# This file contains platform detection and handling functions

function detect_project_type() {
    local proj_dir="${1:-$PROJECT}"
    
    if [[ -z "$proj_dir" || "$proj_dir" == "$DEFAULT_PROJECT" || ! -d "$proj_dir" ]]; then
        echo "unknown"
        return
    fi

    # 1. Check if project-specific type config exists
    if [[ -f "$proj_dir/.arduino-cli-manager.type" ]]; then
        local saved_type
        saved_type=$(cat "$proj_dir/.arduino-cli-manager.type" 2>/dev/null | tr -d '[:space:]')
        if [[ "$saved_type" == "espidf" || "$saved_type" == "platformio" || "$saved_type" == "arduino" ]]; then
            echo "$saved_type"
            return
        fi
    fi

    # 2. Hard detection
    local has_pio=false
    local has_idf=false
    local has_ard=false

    if [[ -f "$proj_dir/platformio.ini" ]]; then
        has_pio=true
    fi
    if [[ -f "$proj_dir/CMakeLists.txt" ]] && grep -q "project.cmake" "$proj_dir/CMakeLists.txt"; then
        has_idf=true
    fi
    if ls "$proj_dir"/*.ino >/dev/null 2>&1; then
        has_ard=true
    fi

    # 3. Resolve
    if [[ "$has_idf" == true && "$has_pio" == true ]]; then
        # Default to espidf when both exist
        echo "espidf"
    elif [[ "$has_idf" == true ]]; then
        echo "espidf"
    elif [[ "$has_pio" == true ]]; then
        echo "platformio"
    elif [[ "$has_ard" == true ]]; then
        echo "arduino"
    else
        echo "unknown"
    fi
}

function resolve_project_type_ambiguity() {
    local proj_dir="${1:-$PROJECT}"
    if [[ -z "$proj_dir" || ! -d "$proj_dir" ]]; then
        return
    fi

    if [[ -f "$proj_dir/platformio.ini" && -f "$proj_dir/CMakeLists.txt" ]] && grep -q -i "project(" "$proj_dir/CMakeLists.txt"; then
        # If the file already exists, don't prompt
        if [[ -f "$proj_dir/.arduino-cli-manager.type" ]]; then
            return
        fi
        
        print_header
        echo -e "${C_YELLOW}Ambiguity Detected: Both ESP-IDF (CMake) and PlatformIO files exist.${C_RESET}"
        echo -e "Which platform do you want to use for compiling/uploading this project?"
        echo -e " 1) ESP-IDF (idf.py)"
        echo -e " 2) PlatformIO (pio)"
        read -rp "Choice [1/2]: " choice
        
        if [[ "$choice" == "2" ]]; then
            echo "platformio" > "$proj_dir/.arduino-cli-manager.type"
        else
            echo "espidf" > "$proj_dir/.arduino-cli-manager.type"
        fi
    fi
}

function run_idf_command() {
    local cmd=("$@")
    
    # 1. If idf.py is already in PATH, run it directly
    if command -v idf.py &> /dev/null; then
        idf.py "${cmd[@]}"
        return $?
    fi

    # 2. Try to find export.sh in common locations
    local export_paths=(
        "${IDF_PATH}/export.sh"
        "$HOME/esp/esp-idf/export.sh"
        "$HOME/esp/esp/esp-idf/export.sh"
        "/opt/esp-idf/export.sh"
        "/opt/esp/esp-idf/export.sh"
    )

    for path in "${export_paths[@]}"; do
        if [[ -n "$path" && -f "$path" ]]; then
            # Source export.sh and run the command in a subshell
            (
                . "$path" > /dev/null 2>&1
                if command -v idf.py &> /dev/null; then
                    idf.py "${cmd[@]}"
                else
                    return 127
                fi
            )
            return $?
        fi
    done

    # 3. If we still can't find it, print error
    echo -e "${C_RED}Error: 'idf.py' not found in PATH and could not locate ESP-IDF export.sh.${C_RESET}"
    echo -e "Please ensure ESP-IDF is installed, or set the IDF_PATH environment variable."
    return 127
}
