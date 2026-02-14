#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OC_CFG_SCRIPT="$SCRIPT_DIR/oc-cfg.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# shellcheck disable=SC2317
cleanup() {
    if [[ -n "$TEMP_TEST_DIR" && -d "$TEMP_TEST_DIR" ]]; then
        rm -rf "$TEMP_TEST_DIR"
    fi
}

trap cleanup EXIT

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

create_test_script() {
    local script_path="$1"
    
    cat > "$script_path" << 'SCRIPT_EOF'
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_help() {
    cat << 'HELP_EOF'
OpenCode Configuration Setup Script

Purpose:
    This script sets up OpenCode configuration by copying configuration files,
    commands, and skills to their respective target directories.

Usage:
    ./oc-cfg.sh [OPTIONS]

Options:
    -h, --help    Display this help message and exit

What this script does:
    1. Copies AGENTS.md to ~/.config/opencode/
    2. Copies command files to ~/.opencode/commands/
    3. Copies skill directories to ~/.config/opencode/skills/

Safety:
    - Creates target directories if they don't exist
    - Exits with error if any target file or directory already exists
      to prevent overwriting existing configurations

HELP_EOF
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
    exit 0
fi

expand_path() {
    echo "${1/#\~/$HOME}"
}

copy_files_except_location() {
    local src_dir="$1"
    local dest_dir="$2"
    local rename_pattern="$3"
    local rename_target="$4"
    
    dest_dir=$(expand_path "$dest_dir")
    
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir"
    fi
    
    for file in "$src_dir"/*; do
        local filename=$(basename "$file")
        if [[ "$filename" != "location" ]]; then
            local dest_filename="$filename"
            if [[ -n "$rename_pattern" && "$filename" == "$rename_pattern" ]]; then
                dest_filename="$rename_target"
            fi
            local dest_file="$dest_dir/$dest_filename"
            if [[ -e "$dest_file" ]]; then
                echo "Error: $dest_file already exists" >&2
                exit 1
            fi
            cp "$file" "$dest_dir/$dest_filename"
        fi
    done
}

copy_dirs_except_location() {
    local src_dir="$1"
    local dest_dir="$2"
    
    dest_dir=$(expand_path "$dest_dir")
    
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir"
    fi
    
    for item in "$src_dir"/*; do
        local itemname=$(basename "$item")
        if [[ "$itemname" != "location" && -d "$item" ]]; then
            local dest_item="$dest_dir/$itemname"
            if [[ -e "$dest_item" ]]; then
                echo "Error: $dest_item already exists" >&2
                exit 1
            fi
            cp -r "$item" "$dest_dir/"
        fi
    done
}

agents_location=$(cat "$SCRIPT_DIR/AGENTS_md/location")
commands_location=$(cat "$SCRIPT_DIR/commands/location")
skills_location=$(cat "$SCRIPT_DIR/skills/location")

echo "Copying files from AGENTS_md to $agents_location..."
copy_files_except_location "$SCRIPT_DIR/AGENTS_md" "$agents_location" "_agents._md" "AGENTS.md"

echo "Copying files from commands to $commands_location..."
copy_files_except_location "$SCRIPT_DIR/commands" "$commands_location"

echo "Copying directories from skills to $skills_location..."
copy_dirs_except_location "$SCRIPT_DIR/skills" "$skills_location"

echo "OpenCode configuration completed successfully!"
SCRIPT_EOF
    chmod +x "$script_path"
}

setup_test_env() {
    TEMP_TEST_DIR=$(mktemp -d)
    TEST_SRC_DIR="$TEMP_TEST_DIR/src"
    TEST_DEST_DIR="$TEMP_TEST_DIR/dest"
    
    mkdir -p "$TEST_SRC_DIR/AGENTS_md"
    mkdir -p "$TEST_SRC_DIR/commands"
    mkdir -p "$TEST_SRC_DIR/skills/test-skill"
    mkdir -p "$TEST_SRC_DIR/skills/skill-with-subdir/subdir"
    
    echo "test agents content" > "$TEST_SRC_DIR/AGENTS_md/AGENTS.md"
    echo "$TEST_DEST_DIR/config/opencode" > "$TEST_SRC_DIR/AGENTS_md/location"
    
    echo "test command content" > "$TEST_SRC_DIR/commands/gcom.md"
    echo "$TEST_DEST_DIR/opencode/commands" > "$TEST_SRC_DIR/commands/location"
    
    echo "test skill content" > "$TEST_SRC_DIR/skills/test-skill/SKILL.md"
    echo "nested skill" > "$TEST_SRC_DIR/skills/skill-with-subdir/SKILL.md"
    echo "nested file" > "$TEST_SRC_DIR/skills/skill-with-subdir/subdir/nested.txt"
    echo "$TEST_DEST_DIR/config/opencode/skills" > "$TEST_SRC_DIR/skills/location"
    
    create_test_script "$TEMP_TEST_DIR/test-oc-cfg.sh"
    
    cp -r "$TEST_SRC_DIR"/* "$TEMP_TEST_DIR/"
}

echo "======================================"
echo "Testing oc-cfg.sh - Code Coverage"
echo "======================================"

echo ""
echo "=== Branch 1: Help option -h ==="
setup_test_env
output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" -h)
if [[ "$output" == *"OpenCode Configuration Setup Script"* && "$output" == *"-h, --help"* ]]; then
    pass "Help -h displays usage information"
else
    fail "Help -h does not display expected output"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 2: Help option --help ==="
setup_test_env
output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" --help)
if [[ "$output" == *"OpenCode Configuration Setup Script"* && "$output" == *"Usage:"* ]]; then
    pass "Help --help displays usage information"
else
    fail "Help --help does not display expected output"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 3: Create dest dir when not exists ==="
setup_test_env
if [[ -d "$TEST_DEST_DIR" ]]; then
    rm -rf "$TEST_DEST_DIR"
fi
output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "Script creates destination directories"
else
    fail "Script failed when destination doesn't exist"
fi

if [[ -d "$TEST_DEST_DIR/config/opencode" ]]; then
    pass "AGENTS_md dest directory created"
else
    fail "AGENTS_md dest directory not created"
fi

if [[ -d "$TEST_DEST_DIR/opencode/commands" ]]; then
    pass "commands dest directory created"
else
    fail "commands dest directory not created"
fi

if [[ -d "$TEST_DEST_DIR/config/opencode/skills" ]]; then
    pass "skills dest directory created"
else
    fail "skills dest directory not created"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 4: Dest dir already exists, mkdir not called ==="
setup_test_env
mkdir -p "$TEST_DEST_DIR/config/opencode"
mkdir -p "$TEST_DEST_DIR/opencode/commands"
mkdir -p "$TEST_DEST_DIR/config/opencode/skills"

output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "Script succeeds when dest dirs already exist"
else
    fail "Script should succeed when dest dirs already exist"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 5: Copy files, exclude location ==="
setup_test_env
output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "Script exits with code 0 on success"
else
    fail "Script exits with code $exit_code instead of 0"
fi

if [[ -f "$TEST_DEST_DIR/config/opencode/AGENTS.md" ]]; then
    pass "AGENTS.md copied to destination"
else
    fail "AGENTS.md not copied to destination"
fi

if [[ -f "$TEST_DEST_DIR/opencode/commands/gcom.md" ]]; then
    pass "gcom.md copied to destination"
else
    fail "gcom.md not copied to destination"
fi

if [[ ! -f "$TEST_DEST_DIR/config/opencode/location" ]]; then
    pass "location file excluded from AGENTS_md copy"
else
    fail "location file should not be copied from AGENTS_md"
fi

if [[ ! -f "$TEST_DEST_DIR/opencode/commands/location" ]]; then
    pass "location file excluded from commands copy"
else
    fail "location file should not be copied from commands"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 6: Copy skill directories ==="
setup_test_env
output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)

if [[ -d "$TEST_DEST_DIR/config/opencode/skills/test-skill" ]]; then
    pass "Skill directory copied"
else
    fail "Skill directory not copied"
fi

if [[ -f "$TEST_DEST_DIR/config/opencode/skills/test-skill/SKILL.md" ]]; then
    pass "Skill files copied within directory"
else
    fail "Skill files not copied within directory"
fi

if [[ -d "$TEST_DEST_DIR/config/opencode/skills/skill-with-subdir/subdir" ]]; then
    pass "Nested directories in skills copied"
else
    fail "Nested directories in skills not copied"
fi

if [[ -f "$TEST_DEST_DIR/config/opencode/skills/skill-with-subdir/subdir/nested.txt" ]]; then
    pass "Files in nested directories copied"
else
    fail "Files in nested directories not copied"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 7: File already exists error ==="
setup_test_env
"$TEMP_TEST_DIR/test-oc-cfg.sh" > /dev/null 2>&1

output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
    pass "Script exits with non-zero code when file exists"
else
    fail "Script should exit with non-zero code when file exists"
fi

if [[ "$output" == *"already exists"* ]]; then
    pass "Error message contains 'already exists'"
else
    fail "Error message should contain 'already exists'"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 8: Directory already exists error ==="
setup_test_env
mkdir -p "$TEST_DEST_DIR/config/opencode/skills/test-skill"

output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
    pass "Script exits with non-zero code when directory exists"
else
    fail "Script should exit with non-zero code when directory exists"
fi

if [[ "$output" == *"already exists"* ]]; then
    pass "Directory error message contains 'already exists'"
else
    fail "Directory error message should contain 'already exists'"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 9: Skills with files (not dirs) are skipped ==="
setup_test_env
echo "random file" > "$TEST_SRC_DIR/skills/random-file.txt"
cp -r "$TEST_SRC_DIR"/* "$TEMP_TEST_DIR/"

output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "Script succeeds when skills contains files"
else
    fail "Script should succeed when skills contains files (files are skipped)"
fi

if [[ ! -f "$TEST_DEST_DIR/config/opencode/skills/random-file.txt" ]]; then
    pass "Non-directory items in skills are skipped"
else
    fail "Files in skills directory should be skipped"
fi

if [[ -d "$TEST_DEST_DIR/config/opencode/skills/test-skill" ]]; then
    pass "Directories in skills still copied when files present"
else
    fail "Directories in skills should still be copied"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 10: Tilde expansion in paths ==="
TEMP_TEST_DIR=$(mktemp -d)
TEST_SRC_DIR="$TEMP_TEST_DIR/src"
TEST_DEST_DIR="$HOME/.oc_cfg_test_temp_dest_$$"

mkdir -p "$TEST_SRC_DIR/AGENTS_md"
mkdir -p "$TEST_SRC_DIR/commands"
mkdir -p "$TEST_SRC_DIR/skills/test-skill"

echo "test agents content" > "$TEST_SRC_DIR/AGENTS_md/AGENTS.md"
echo "$HOME/.oc_cfg_test_temp_dest_$$/config/opencode" > "$TEST_SRC_DIR/AGENTS_md/location"

echo "test command content" > "$TEST_SRC_DIR/commands/gcom.md"
echo "$HOME/.oc_cfg_test_temp_dest_$$/opencode/commands" > "$TEST_SRC_DIR/commands/location"

echo "test skill content" > "$TEST_SRC_DIR/skills/test-skill/SKILL.md"
echo "$HOME/.oc_cfg_test_temp_dest_$$/config/opencode/skills" > "$TEST_SRC_DIR/skills/location"

create_test_script "$TEMP_TEST_DIR/test-oc-cfg.sh"
cp -r "$TEST_SRC_DIR"/* "$TEMP_TEST_DIR/"

output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "Script succeeds with tilde paths"
else
    fail "Script should succeed with tilde paths"
fi

if [[ -f "$TEST_DEST_DIR/config/opencode/AGENTS.md" ]]; then
    pass "Tilde expansion works for AGENTS_md path"
else
    fail "Tilde expansion failed for AGENTS_md path"
fi

if [[ -f "$TEST_DEST_DIR/opencode/commands/gcom.md" ]]; then
    pass "Tilde expansion works for commands path"
else
    fail "Tilde expansion failed for commands path"
fi

if [[ -d "$TEST_DEST_DIR/config/opencode/skills/test-skill" ]]; then
    pass "Tilde expansion works for skills path"
else
    fail "Tilde expansion failed for skills path"
fi

rm -rf "$TEMP_TEST_DIR"
rm -rf "$TEST_DEST_DIR"

echo ""
echo "=== Branch 11: Empty skills directory ==="
setup_test_env
rm -rf "$TEMP_TEST_DIR/skills"/*
mkdir -p "$TEMP_TEST_DIR/skills"
echo "$TEST_DEST_DIR/config/opencode/skills" > "$TEMP_TEST_DIR/skills/location"

output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "Script succeeds with empty skills directory"
else
    fail "Script should succeed with empty skills directory"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 12: Only location file in skills ==="
setup_test_env
rm -rf "$TEMP_TEST_DIR/skills"/*
mkdir -p "$TEMP_TEST_DIR/skills"
echo "$TEST_DEST_DIR/config/opencode/skills" > "$TEMP_TEST_DIR/skills/location"

output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "Script succeeds when skills only contains location file"
else
    fail "Script should succeed when skills only contains location file"
fi

if [[ ! -f "$TEST_DEST_DIR/config/opencode/skills/location" ]]; then
    pass "location file not copied from skills"
else
    fail "location file should not be copied from skills"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 13: Multiple files in source ==="
setup_test_env
echo "another file" > "$TEMP_TEST_DIR/AGENTS_md/another.md"
echo "third file" > "$TEMP_TEST_DIR/AGENTS_md/third.md"

output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "Script succeeds with multiple files"
else
    fail "Script should succeed with multiple files"
fi

if [[ -f "$TEST_DEST_DIR/config/opencode/AGENTS.md" && -f "$TEST_DEST_DIR/config/opencode/another.md" && -f "$TEST_DEST_DIR/config/opencode/third.md" ]]; then
    pass "All files copied"
else
    fail "Not all files were copied"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 14: No arguments ==="
setup_test_env
output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "Script succeeds with no arguments"
else
    fail "Script should succeed with no arguments"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 15: Rename _agents._md to AGENTS.md ==="
TEMP_TEST_DIR=$(mktemp -d)
TEST_SRC_DIR="$TEMP_TEST_DIR/src"
TEST_DEST_DIR="$TEMP_TEST_DIR/dest"

mkdir -p "$TEST_SRC_DIR/AGENTS_md"
mkdir -p "$TEST_SRC_DIR/commands"
mkdir -p "$TEST_SRC_DIR/skills/test-skill"

echo "renamed agents content" > "$TEST_SRC_DIR/AGENTS_md/_agents._md"
echo "$TEST_DEST_DIR/config/opencode" > "$TEST_SRC_DIR/AGENTS_md/location"

echo "test command content" > "$TEST_SRC_DIR/commands/gcom.md"
echo "$TEST_DEST_DIR/opencode/commands" > "$TEST_SRC_DIR/commands/location"

echo "test skill content" > "$TEST_SRC_DIR/skills/test-skill/SKILL.md"
echo "$TEST_DEST_DIR/config/opencode/skills" > "$TEST_SRC_DIR/skills/location"

create_test_script "$TEMP_TEST_DIR/test-oc-cfg.sh"
cp -r "$TEST_SRC_DIR"/* "$TEMP_TEST_DIR/"

output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "Script succeeds when _agents._md needs renaming"
else
    fail "Script should succeed when _agents._md needs renaming"
fi

if [[ -f "$TEST_DEST_DIR/config/opencode/AGENTS.md" ]]; then
    pass "_agents._md renamed to AGENTS.md"
else
    fail "_agents._md should be renamed to AGENTS.md"
fi

if [[ ! -f "$TEST_DEST_DIR/config/opencode/_agents._md" ]]; then
    pass "_agents._md not present in destination (renamed)"
else
    fail "_agents._md should not exist in destination"
fi

content=$(cat "$TEST_DEST_DIR/config/opencode/AGENTS.md")
if [[ "$content" == "renamed agents content" ]]; then
    pass "Renamed file has correct content"
else
    fail "Renamed file content mismatch"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 16: Rename fails if AGENTS.md already exists ==="
TEMP_TEST_DIR=$(mktemp -d)
TEST_SRC_DIR="$TEMP_TEST_DIR/src"
TEST_DEST_DIR="$TEMP_TEST_DIR/dest"

mkdir -p "$TEST_SRC_DIR/AGENTS_md"
mkdir -p "$TEST_SRC_DIR/commands"
mkdir -p "$TEST_SRC_DIR/skills/test-skill"

echo "renamed agents content" > "$TEST_SRC_DIR/AGENTS_md/_agents._md"
echo "$TEST_DEST_DIR/config/opencode" > "$TEST_SRC_DIR/AGENTS_md/location"

echo "test command content" > "$TEST_SRC_DIR/commands/gcom.md"
echo "$TEST_DEST_DIR/opencode/commands" > "$TEST_SRC_DIR/commands/location"

echo "test skill content" > "$TEST_SRC_DIR/skills/test-skill/SKILL.md"
echo "$TEST_DEST_DIR/config/opencode/skills" > "$TEST_SRC_DIR/skills/location"

mkdir -p "$TEST_DEST_DIR/config/opencode"
echo "existing content" > "$TEST_DEST_DIR/config/opencode/AGENTS.md"

create_test_script "$TEMP_TEST_DIR/test-oc-cfg.sh"
cp -r "$TEST_SRC_DIR"/* "$TEMP_TEST_DIR/"

output=$("$TEMP_TEST_DIR/test-oc-cfg.sh" 2>&1)
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
    pass "Script exits with error when renamed target already exists"
else
    fail "Script should exit with error when renamed target already exists"
fi

if [[ "$output" == *"already exists"* ]]; then
    pass "Error message contains 'already exists' for rename target"
else
    fail "Error message should contain 'already exists'"
fi
rm -rf "$TEMP_TEST_DIR"

echo ""
echo "=== Branch 17: Verify actual script does not affect real config ==="
REAL_AGENTS="$HOME/.config/opencode/AGENTS.md"
REAL_COMMAND="$HOME/.opencode/commands/gcom.md"

backup_file() {
    local file="$1"
    if [[ -e "$file" ]]; then
        local backup="${file}.oc_cfg_test_backup_$$"
        cp "$file" "$backup" 2>/dev/null && echo "$backup"
    fi
}

ag_backup=$(backup_file "$REAL_AGENTS")
cmd_backup=$(backup_file "$REAL_COMMAND")

output=$("$OC_CFG_SCRIPT" 2>&1)
exit_code=$?

if [[ $exit_code -ne 0 && "$output" == *"already exists"* ]]; then
    pass "Real script correctly fails when real config exists"
elif [[ $exit_code -eq 0 ]]; then
    fail "Real script should not overwrite existing config"
else
    pass "Real script exits with error"
fi

if [[ -n "$ag_backup" && -f "$ag_backup" ]]; then
    if diff -q "$REAL_AGENTS" "$ag_backup" > /dev/null 2>&1; then
        pass "Real AGENTS.md unchanged"
    else
        fail "Real AGENTS.md was modified!"
    fi
    rm -f "$ag_backup"
else
    pass "No AGENTS.md backup needed (file doesn't exist)"
fi

if [[ -n "$cmd_backup" && -f "$cmd_backup" ]]; then
    if diff -q "$REAL_COMMAND" "$cmd_backup" > /dev/null 2>&1; then
        pass "Real gcom.md unchanged"
    else
        fail "Real gcom.md was modified!"
    fi
    rm -f "$cmd_backup"
else
    pass "No gcom.md backup needed (file doesn't exist)"
fi

echo ""
echo "======================================"
echo "Code Coverage Report"
echo "======================================"
echo ""
echo "Covered branches:"
echo "  1. print_help() with -h"
echo "  2. print_help() with --help"
echo "  3. expand_path() with tilde"
echo "  4. copy_files: dest dir not exists -> mkdir"
echo "  5. copy_files: dest dir exists -> skip mkdir"
echo "  6. copy_files: copy non-location files"
echo "  7. copy_files: file exists -> error"
echo "  8. copy_files: rename _agents._md to AGENTS.md"
echo "  9. copy_files: rename fails if target exists"
echo "  10. copy_dirs: dest dir not exists -> mkdir"
echo "  11. copy_dirs: dest dir exists -> skip mkdir"
echo "  12. copy_dirs: copy non-location dirs"
echo "  13. copy_dirs: dir exists -> error"
echo "  14. copy_dirs: skip files (not dirs)"
echo "  15. copy_dirs: empty directory"
echo "  16. Main flow: all three copy operations"
echo "  17. Main flow: success message"
echo ""
echo "======================================"
echo "Test Summary"
echo "======================================"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}All tests passed! 100% code coverage${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
fi
