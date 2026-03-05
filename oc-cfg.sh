#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REVERSE_MODE=false
FORCE_MODE=false

print_help() {
    cat << 'EOF'
OpenCode Configuration Setup Script

Purpose:
    This script sets up OpenCode configuration by copying configuration files,
    commands, and skills to their respective target directories.

Usage:
    ./oc-cfg.sh [OPTIONS]

Options:
    -h, --help       Display this help message and exit
    -r, --reverse    Reverse: copy from target locations back to git repo
    -f, --force      Force: overwrite existing files in target locations

Modes:
    Default (no -r):  Copy from repo → target locations
    Reverse (-r):     Copy from target locations → repo
                      (AGENTS_md: only AGENTS.md → _agents._md)

Safety:
    - Creates target directories if they don't exist
    - Exits with error if any target file or directory already exists
      (use -f/--force to overwrite existing files in default mode)
    - Note: -f/--force has no effect in reverse mode (files are always overwritten)

EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        -r|--reverse)
            REVERSE_MODE=true
            shift
            ;;
        -f|--force)
            FORCE_MODE=true
            shift
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            print_help
            exit 1
            ;;
    esac
done

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
            if [[ -e "$dest_file" && "$FORCE_MODE" != true ]]; then
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
            if [[ -e "$dest_item" && "$FORCE_MODE" != true ]]; then
                echo "Error: $dest_item already exists" >&2
                exit 1
            fi
            if [[ -e "$dest_item" ]]; then
                rm -rf "$dest_item"
            fi
            cp -r "$item" "$dest_dir/"
        fi
    done
}

update_files_from_target() {
    local dest_dir="$1"
    local src_dir="$2"
    local rename_pattern="$3"
    local rename_target="$4"

    dest_dir=$(expand_path "$dest_dir")

    if [[ ! -d "$dest_dir" ]]; then
        echo "Error: Target directory $dest_dir does not exist" >&2
        exit 1
    fi

    # In reverse mode, only copy the file matching rename_pattern (AGENTS.md -> _agents._md)
    if [[ -n "$rename_pattern" ]]; then
        local target_file="$dest_dir/$rename_pattern"
        if [[ -e "$target_file" ]]; then
            local src_file="$src_dir/$rename_target"
            if [[ -e "$src_file" ]]; then
                if diff -q "$target_file" "$src_file" > /dev/null 2>&1; then
                    return
                fi
            fi
            cp "$target_file" "$src_file"
        fi
        return
    fi

    for file in "$dest_dir"/*; do
        local filename
        filename=$(basename "$file")
        if [[ "$filename" == "location" ]]; then
            continue
        fi
        local src_filename="$filename"
        local src_file="$src_dir/$src_filename"
        if [[ ! -e "$file" ]]; then
            continue
        fi
        if [[ -e "$src_file" ]]; then
            if diff -q "$file" "$src_file" > /dev/null 2>&1; then
                continue
            fi
        fi
        cp "$file" "$src_file"
    done
}

update_dirs_from_target() {
    local dest_dir="$1"
    local src_dir="$2"

    dest_dir=$(expand_path "$dest_dir")

    if [[ ! -d "$dest_dir" ]]; then
        echo "Error: Target directory $dest_dir does not exist" >&2
        exit 1
    fi

    for item in "$dest_dir"/*; do
        local itemname
        itemname=$(basename "$item")
        if [[ "$itemname" == "location" || ! -d "$item" ]]; then
            continue
        fi
        local src_item="$src_dir/$itemname"
        if [[ ! -e "$item" ]]; then
            continue
        fi
        if [[ -d "$src_item" ]]; then
            rm -rf "$src_item"
        fi
        cp -r "$item" "$src_dir/"
    done
}

agents_location=$(cat "$SCRIPT_DIR/AGENTS_md/location")
commands_location=$(cat "$SCRIPT_DIR/commands/location")
skills_location=$(cat "$SCRIPT_DIR/skills/location")

if [[ "$REVERSE_MODE" == true ]]; then
    echo "Reverse mode: copying from target locations back to repo..."

    echo "Updating AGENTS_md from $agents_location..."
    update_files_from_target "$agents_location" "$SCRIPT_DIR/AGENTS_md" "AGENTS.md" "_agents._md"

    echo "Updating commands from $commands_location..."
    update_files_from_target "$commands_location" "$SCRIPT_DIR/commands"

    echo "Updating skills from $skills_location..."
    update_dirs_from_target "$skills_location" "$SCRIPT_DIR/skills"

    echo "OpenCode configuration reversed successfully!"
else
    echo "Copying files from AGENTS_md to $agents_location..."
    copy_files_except_location "$SCRIPT_DIR/AGENTS_md" "$agents_location" "_agents._md" "AGENTS.md"

    echo "Copying files from commands to $commands_location..."
    copy_files_except_location "$SCRIPT_DIR/commands" "$commands_location"

    echo "Copying directories from skills to $skills_location..."
    copy_dirs_except_location "$SCRIPT_DIR/skills" "$skills_location"

    echo "Please manually insert \"permissions\" block into opencode.json in ~/.config/opencode."
    echo "After that, please manually disable the password when running \"sudo\"."

    echo "OpenCode configuration completed successfully!"
fi
