# AGENTS.md

Guidance for AI coding agents working in this OpenCode configuration repository.

## Project Overview

Deploys AI agent configs, slash commands, and skills to OpenCode directories.
Each source directory contains a `location` file specifying its deployment target;
these files are excluded from copying. The script never overwrites existing files.

## Commands

### Build/Setup
```bash
./oc-cfg.sh              # Deploy configs to target locations
./oc-cfg.sh -h           # Show help
```

### Testing
```bash
./test_oc_cfg.sh                        # Run all 42 tests (17 branches)

# Run a single branch by number (1-17):
./test_oc_cfg.sh 2>&1 | sed -n '/=== Branch 7:/,/=== Branch 8:/p'

# For the last branch (17), use end-of-output anchor:
./test_oc_cfg.sh 2>&1 | sed -n '/=== Branch 17:/,/^Tests passed/p'
```

Tests use `create_test_script()` to generate an isolated copy of `oc-cfg.sh`
with controlled source/dest paths. Only Branch 17 runs the real script.

### Linting
```bash
shellcheck oc-cfg.sh test_oc_cfg.sh   # Bash
ruff check skills/                     # Python
mypy skills/                           # Types
```

### Office Document Scripts
```bash
python skills/docx/scripts/office/unpack.py file.docx unpacked/
python skills/docx/scripts/office/pack.py unpacked/ output.docx
python skills/docx/scripts/office/validate.py unpacked/
python -m markitdown presentation.pptx
```

## Directory Structure
```
oc-cfg/
├── AGENTS.md, README.md   # Documentation
├── AGENTS_md/             # → ~/.config/opencode/ (_agents._md → AGENTS.md)
├── commands/              # → ~/.opencode/commands/ (slash commands)
├── oc-cfg.sh              # Main deployment script
├── skills/                # → ~/.config/opencode/skills/
│   ├── docx/scripts/      # Word: unpack/pack/comment/accept_changes
│   ├── pdf/scripts/       # PDF: form filling, extraction, validation
│   ├── pptx/scripts/      # PowerPoint: add_slide
│   ├── xlsx/scripts/      # Excel: recalc, shared office/ utilities
│   └── (6 more skills)    # c-pro, cpp-pro, arch-design-review, etc.
├── _config/               # Manual config snippets (not auto-deployed)
├── specs/                 # Requirements specification (bilingual EN/CN)
└── test_oc_cfg.sh         # Test suite (42 tests, 17 branches, 100% coverage)
```

The `office/` subdirectory is duplicated between `docx/scripts/` and
`xlsx/scripts/` — each skill is a self-contained deployable unit.

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

**Test conventions:**
- `pass "desc"` / `fail "desc"` with ANSI color; `setup_test_env` + `trap cleanup EXIT`
- Each branch: `echo "=== Branch N: description ==="`

## Code Style: Python

**Imports** — stdlib first (alphabetical), blank line, then third-party:
```python
import argparse
import sys
from pathlib import Path

import defusedxml.minidom
```

**Script structure** — docstring, imports, constants, helpers, `main()`, guard:
```python
"""Brief description.

Usage: python script.py <args>
"""
import argparse
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description="...")
    args = parser.parse_args()
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: {args.input} not found", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
```

**Type hints** — Python 3.10+ syntax: `list[dict]`, `str | None`, `tuple[Path, str]`

**Error return pattern** — return `tuple[None, str]`; check for `"Error"` in message:
```python
def do_something(path: Path) -> tuple[None, str]:
    if not path.exists():
        return None, f"Error: {path} not found"
    return None, f"Success: processed {path}"
```

**XML handling** — use `defusedxml.minidom` for all parsing (security).
Use `lxml.etree` only for XSD schema validation (in validators/).

## Code Style: Markdown

**Commands (commands/*.md):**
```markdown
---description: Brief description---
Body content with executable blocks.
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
| Python classes | PascalCase | `BaseSchemaValidator` |
| Constants | UPPER_SNAKE | `THUMBNAIL_WIDTH` |

## Rules

- NEVER add code comments unless explicitly requested
- Keep responses concise (1-3 sentences)
- Run `shellcheck` and tests before committing bash changes
- Use `defusedxml` for all XML parsing (security requirement)
- Always handle errors explicitly in Python (no bare `except`)
- Prefer `Path` objects over string paths in Python
- Each skill must be self-contained (no cross-skill imports)
