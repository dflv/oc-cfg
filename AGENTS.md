# AGENTS.md

Guidance for AI coding agents working in this OpenCode configuration repository.

## Commands

### Build/Setup
```bash
./oc-cfg.sh              # Deploy configs to target locations
./oc-cfg.sh -h           # Show help
```

### Testing
```bash
./test_oc_cfg.sh         # Run all 42 tests with coverage

# Run single test branch (1-17)
./test_oc_cfg.sh 2>&1 | sed -n '/=== Branch 7:/,/=== Branch 8:/p'
```

### Linting
```bash
shellcheck oc-cfg.sh test_oc_cfg.sh   # Bash
ruff check skills/                     # Python
mypy skills/                           # Types
```

### Office Document Scripts
```bash
# Unpack/edit/pack workflow (PPTX, DOCX, XLSX)
python scripts/office/unpack.py file.pptx unpacked/
python scripts/office/pack.py unpacked/ output.pptx
python scripts/office/validate.py unpacked/

# PPTX: extract text or thumbnails
python -m markitdown presentation.pptx
python scripts/thumbnail.py presentation.pptx
```

## Directory Structure
```
oc-cfg/
├── AGENTS.md              # This file
├── AGENTS_md/             # → ~/.config/opencode/
├── commands/              # → ~/.opencode/commands/
├── oc-cfg.sh              # Main setup script
├── skills/                # → ~/.config/opencode/skills/
│   ├── docx/scripts/      # Word utilities
│   ├── pdf/scripts/       # PDF utilities
│   ├── pptx/scripts/      # PowerPoint utilities
│   └── xlsx/scripts/      # Excel utilities
└── test_oc_cfg.sh         # Test suite (42 tests, 100% coverage)
```

## Code Style: Bash
**Formatting:**
- 4-space indentation, shebang `#!/bin/bash`
- Script directory: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`

**Variables:**
```bash
local src_dir="$1"          # Always local, always quoted
[[ -n "$src_dir" ]]         # Use [[ ]], not [ ]
```

**Declare separately (shellcheck SC2155):**
```bash
local filename
filename=$(basename "$file")
```

**Error handling:**
```bash
if [[ -e "$dest_file" ]]; then
    echo "Error: $dest_file already exists" >&2
    exit 1
fi
```

## Code Style: Python
**Imports (stdlib first, alphabetically):**
```python
import argparse
import sys
from pathlib import Path

import defusedxml.minidom
from PIL import Image
```

**Script structure:**
```python
"""Brief description.

Usage: python script.py <args>
"""
import argparse

CONSTANT = 100


def helper_function(path: Path) -> str:
    ...


def main():
    parser = argparse.ArgumentParser(description="...")
    parser.add_argument("input", help="Input file")
    args = parser.parse_args()
    
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: {args.input} not found", file=sys.stderr)
        sys.exit(1)
    
    print(helper_function(input_path))


if __name__ == "__main__":
    main()
```

**Type hints:**
```python
def get_slide_info(pptx_path: Path) -> list[dict]:
def build_slide_list(slides: list[dict], cols: int) -> list[tuple[Path, str]]:
```

**XML handling (use defusedxml for security):**
```python
import defusedxml.minidom

dom = defusedxml.minidom.parseString(xml_content)
for elem in dom.getElementsByTagName("w:p"):
    ...
```

## Code Style: Markdown
**Commands (commands/*.md):**
```markdown
---description: Brief description---
Body content with `!`command`` for executable blocks.
```

**Skills (skills/*/SKILL.md):**
```markdown
---
name: skillname
description: "What this skill does"
---
| Task | Command |
|------|---------|
| Read | `python -m markitdown file.pptx` |
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Bash scripts | kebab-case.sh | `oc-cfg.sh` |
| Bash functions | snake_case | `copy_files_except_location` |
| Python files | snake_case.py | `add_slide.py` |
| Python functions | snake_case | `get_next_slide_number` |
| Python classes | PascalCase | `SlideValidator` |
| Constants | UPPER_SNAKE | `THUMBNAIL_WIDTH` |

## Rules
- NEVER add code comments unless explicitly requested
- Keep responses concise (1-3 sentences)
- Run `shellcheck` and tests before committing bash changes
- Use `defusedxml` for all XML parsing (security)
- Always handle errors explicitly in Python (no bare except)
- Prefer `Path` objects over string paths in Python
