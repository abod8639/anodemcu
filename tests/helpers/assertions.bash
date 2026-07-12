#!/usr/bin/env bash

# Custom assertion helpers for tests

# Assert that a variable is set
assert_var_set() {
    local var_name="$1"
    local var_value="${!var_name}"
    
    if [[ -z "$var_value" ]]; then
        echo "FAIL: Variable '$var_name' is not set"
        return 1
    fi
    return 0
}

# Assert that a variable equals expected value
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [[ "$expected" != "$actual" ]]; then
        echo "FAIL: Expected '$expected' but got '$actual'"
        [[ -n "$message" ]] && echo "  $message"
        return 1
    fi
    return 0
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "FAIL: File does not exist: $file"
        return 1
    fi
    return 0
}

# Assert that a directory exists
assert_dir_exists() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        echo "FAIL: Directory does not exist: $dir"
        return 1
    fi
    return 0
}

# Assert that output contains string
assert_output_contains() {
    local expected="$1"
    
    if [[ ! "$output" =~ $expected ]]; then
        echo "FAIL: Output does not contain '$expected'"
        echo "  Output was: $output"
        return 1
    fi
    return 0
}

# Assert that a function exists
assert_function_exists() {        local result=$?
        if [[ $result -eq 1 ]]; then
            local update_msg="Update available: v$VERSION → v$LATEST_VERSION"
            printf " ${C_YELLOW}%*s${C_RESET}${C_GREEN}%*s \\n" $(( (59 + ${#update_msg}) / 2 )) "$update_msg" $(( (59 - ${#update_msg}) / 2 )) ""
            return
        fi
    fi

    local version_msg="v$VERSION"
    printf "${C_GREEN} %*s%*s \\n${C_RESET}" $(( (59 + ${#version_msg}) / 2 )) "$version_msg" $(( (59 - ${#version_msg}) / 2 )) ""
}

function press_enter_to_continue() {
    read -p "Press Enter to continue..."
}

function show_help() {
    print_header
    echo -e "${C_GREEN}==> Arduino CLI Manager - Quick Help${C_RESET}"
    echo ""
    echo "This tool helps you manage Arduino projects easily."
    echo ""
    echo -e "${C_CYAN}Getting Started:${C_RESET}"
    echo "  1. Select or create a project (S)"
    echo "  2. Select your board type (B)"
    echo "  3. Connect board and select port (P)"
    echo "  4. Compile your sketch (C)"
    echo "  5. Upload to board (U)"
    echo ""
    echo -e "${C_CYAN}Keyboard Shortcuts:${C_RESET}"
    echo "  S - Select/Create Project    B - Select Board (FQBN)"
    echo "  P - Select Port              C - Compile Project"
    echo "  U - Upload Project           M - Serial Monitor"
    echo "  E - Edit in nvim             L - List Cores"
    echo "  A - List All Boards          I - Install Core"
    echo "  H - Show this help           Q - Quit"
    echo ""
    echo -e "${C_CYAN}Common Workflows:${C_RESET}"
    echo "  ${C_YELLOW}New Project:${C_RESET} S → Create new → B → P → C → U"
    echo "  ${C_YELLOW}Quick Upload:${C_RESET} U (if project already selected)"
    echo "  ${C_YELLOW}Debug Output:${C_RESET} M (opens serial monitor)"
    echo ""
    echo -e "${C_CYAN}Configuration:${C_RESET}"
    echo "  Config file: ~/.arduino-cli-manager.conf"
    echo "  Projects directory: $SKETCH_DIR"
    echo ""
    press_enter_to_continue
}
    local func_name="$1"
    
    if ! declare -F "$func_name" > /dev/null; then
        echo "FAIL: Function '$func_name' does not exist"
        return 1
    fi
    return 0
}

# Assert that command succeeds
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "FAIL: Command failed with status $status"
        echo "  Output: $output"
        return 1
    fi
    return 0
}

# Assert that command fails
assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "FAIL: Command succeeded but was expected to fail"
        return 1
    fi
    return 0
}

# Assert line count
assert_line_count() {
    local expected="$1"
    local actual="${#lines[@]}"
    
    if [[ "$expected" -ne "$actual" ]]; then
        echo "FAIL: Expected $expected lines but got $actual"
        return 1
    fi
    return 0
}

# Assert that output matches regex
assert_output_matches() {
    local pattern="$1"
    
    if [[ ! "$output" =~ $pattern ]]; then
        echo "FAIL: Output does not match pattern '$pattern'"
        echo "  Output was: $output"
        return 1
    fi
    return 0
}
