# AGENTS.md

This file provides guidance for AI coding agents working in this OpenCode configuration repository.

## Project Overview

This repository provides configuration files, commands, and skills for OpenCode CLI tool. It contains:
- Setup script (`oc-cfg.sh`) for deploying configurations to user systems
- Slash commands for common workflows
- Skills for document manipulation (PPTX, DOCX, XLSX, PDF)

## Commands

### Build/Setup

```bash
./oc-cfg.sh              # Run setup script (copies files to target locations)
./oc-cfg.sh -h           # Show help
./oc-cfg.sh --help       # Show help
```

### Testing

```bash
./test_oc_cfg.sh         # Run all tests with coverage report

# Run specific test branch
./test_oc_cfg.sh 2>&1 | grep -A10 "Branch 15"
```

### Linting

```bash
shellcheck oc-cfg.sh test_oc_cfg.sh   # Bash linting
ruff check skills/                     # Python linting
mypy skills/                           # Type checking
```

### Skill Scripts (Python)

```bash
# PPTX
python -m markitdown presentation.pptx
python scripts/thumbnail.py presentation.pptx
python scripts/add_slide.py unpacked/ slide2.xml

# DOCX
python scripts/comment.py unpacked/ 0 "Comment text"

# Office utilities
python scripts/office/unpack.py file.pptx unpacked/
python scripts/office/pack.py unpacked/ output.pptx
```

## Directory Structure

```
oc-cfg/
├── oc-cfg.sh              # Main setup script
├── test_oc_cfg.sh         # Test suite with coverage
├── agents_md/             # Files copied to ~/.config/opencode/
│   ├── _AGENTS.md         # Renamed to AGENTS.md on copy
│   └── location           # Target path
├── commands/              # Slash commands (~/.opencode/command/)
│   ├── gcom.md
│   └── location
├── skills/                # Skill directories (~/.config/opencode/skills/)
│   ├── pptx/, docx/, xlsx/, pdf/
│   └── location
└── specs/                 # Requirements
```

## Code Style Guidelines

### Bash Scripts

**Formatting:**
- 4-space indentation (no tabs)
- Shebang: `#!/bin/bash`
- Get script directory: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`

**Variables:**
- Always use `local` for function-scoped variables
- Quote all expansions: `"$variable"` not `$variable`
- Use `[[ ]]` for conditionals, not `[ ]`

**Functions:**
```bash
function_name() {
    local arg1="$1"
    local arg2="$2"
    
    if [[ -n "$arg1" ]]; then
        echo "arg1 is set"
    fi
}
```

**Error Handling:**
```bash
if [[ -e "$dest_file" ]]; then
    echo "Error: $dest_file already exists" >&2
    exit 1
fi
```

- Write errors to stderr: `>&2`
- Exit with non-zero code on failure
- Use `trap cleanup EXIT` for cleanup

### Python Scripts

**Imports (alphabetically grouped):**
```python
import re
import sys
from pathlib import Path
from typing import Optional

import defusedxml.minidom
```

**Type Hints:**
```python
def get_next_slide_number(slides_dir: Path) -> int:
def parse_source(source: str) -> tuple[str, str | None]:
```

**Error Handling:**
```python
if not path.exists():
    print(f"Error: {path} not found", file=sys.stderr)
    sys.exit(1)
```

**Docstrings:**
```python
"""Brief description.

Usage: python script.py <args>

Examples:
    python script.py input.pptx
"""
```

### Markdown Files

**Commands (commands/*.md):**
- First line: `---description: Brief description---`
- Use `!`command`` for executable blocks

**Skills (skills/*/SKILL.md):**
- YAML frontmatter with `name` and `description`
- Include Quick Reference table

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Bash scripts | kebab-case | `oc-cfg.sh` |
| Bash functions | snake_case | `copy_files_except_location` |
| Python files | snake_case | `add_slide.py` |
| Python functions | snake_case | `get_next_slide_number` |
| Python classes | PascalCase | `SlideValidator` |
| Directories | lowercase | `skills/pptx/` |

## Rules

- Print the names of skills to be loaded on screen before implementing a specific task. Highlight skill names using bright color formatting.
- Write code review results to a report file. Include timestamp in filename.
- If a required tool is not installed, ask for sudo password and run: `sudo -S apt update && sudo -S apt install <tool>`
- NEVER add code comments unless explicitly requested
- Keep responses concise (1-3 sentences when possible)
