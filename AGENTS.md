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
./test_oc_cfg.sh         # Run all tests with coverage report (42 tests)

# Run specific test branch by filtering output
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
# PPTX operations
python -m markitdown presentation.pptx
python scripts/thumbnail.py presentation.pptx
python scripts/add_slide.py unpacked/ slide2.xml

# DOCX operations
python scripts/comment.py unpacked/ 0 "Comment text"

# Office document utilities
python scripts/office/unpack.py file.pptx unpacked/
python scripts/office/pack.py unpacked/ output.pptx
python scripts/office/validate.py unpacked/
```

## Directory Structure

```
oc-cfg/
├── AGENTS.md              # This file - guidance for AI agents
├── oc-cfg.sh              # Main setup script
├── test_oc_cfg.sh         # Test suite with coverage
├── AGENTS_md/             # Files copied to ~/.config/opencode/
│   ├── _agents._md        # Renamed to AGENTS.md on copy
│   └── location           # Target path definition
├── commands/              # Slash commands (~/.opencode/commands/)
│   ├── gcom.md            # Git commit helper
│   └── location
├── skills/                # Skill directories (~/.config/opencode/skills/)
│   ├── pptx/              # PowerPoint manipulation
│   ├── docx/              # Word document manipulation
│   ├── xlsx/              # Excel manipulation
│   ├── pdf/               # PDF operations
│   └── location
└── specs/                 # Requirements and specifications
```

## Code Style Guidelines

### Bash Scripts

**Formatting:**
- 4-space indentation (no tabs)
- Shebang: `#!/bin/bash`
- Get script directory: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`

**Variables:**
- Always use `local` for function-scoped variables
- Quote all variable expansions: `"$variable"` not `$variable`
- Use `[[ ]]` for conditionals, not `[ ]`

**Functions:**
```bash
copy_files_except_location() {
    local src_dir="$1"
    local dest_dir="$2"
    
    if [[ -n "$src_dir" ]]; then
        echo "Processing $src_dir"
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
- Use `trap cleanup EXIT` for cleanup functions

**Color Output:**
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
echo -e "${GREEN}[PASS]${NC} message"
```

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
| Directories | lowercase or UPPERCASE | `skills/pptx/`, `AGENTS_md/` |
| Constants | UPPER_SNAKE | `RED='\033[0;31m'` |

## Rules

- NEVER add code comments unless explicitly requested
- Keep responses concise (1-3 sentences when possible)
