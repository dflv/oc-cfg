#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_help() {
    cat << 'EOF'
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

EOF
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
            local filename
            filename=$(basename "$file")
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
            local itemname
            itemname=$(basename "$item")
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
