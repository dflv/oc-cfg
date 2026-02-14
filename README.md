# OpenCode Configuration

One-click setup script for configuring [OpenCode](https://opencode.ai) in a fresh Linux environment.

## What it does

This script deploys OpenCode configuration files to their target locations:

| Source | Destination |
|--------|-------------|
| `AGENTS_md/` | `~/.config/opencode/` |
| `commands/` | `~/.opencode/commands/` |
| `skills/` | `~/.config/opencode/skills/` |

## Quick Start

```bash
./oc-cfg.sh
```

## Safety Features

- Creates target directories if they don't exist
- Exits with error if any target file/directory already exists (prevents overwriting)
- Supports tilde expansion in paths

## Included Skills

| Skill | Description |
|-------|-------------|
| `pptx` | PowerPoint manipulation (create, edit, extract) |
| `docx` | Word document manipulation |
| `xlsx` | Excel spreadsheet operations |
| `pdf` | PDF operations (read, merge, split, OCR) |
| `code-review-excellence` | Code review best practices |
| `security-review` | Security review checklist |
| `find-skills` | Discover and install skills |
| `algorithmic-art` | Generative art with p5.js |
| `cpp-pro` | Modern C++ patterns |
| `c-pro` | C system programming |

## Included Commands

| Command | Description |
|---------|-------------|
| `/gcom` | Git commit with auto-generated message |

## Development

### Running Tests

```bash
./test_oc_cfg.sh
```

### Linting

```bash
shellcheck oc-cfg.sh test_oc_cfg.sh
```

## Directory Structure

```
oc-cfg/
├── AGENTS.md              # AI agent guidance
├── AGENTS_md/             # Files copied to ~/.config/opencode/
│   ├── _agents._md        # Renamed to AGENTS.md on copy
│   └── location           # Target path definition
├── README.md              # This file
├── commands/              # Slash commands
│   ├── gcom.md
│   └── location
├── oc-cfg.sh              # Main setup script
├── skills/                # Skill directories
│   ├── docx/
│   ├── pdf/
│   ├── pptx/
│   ├── xlsx/
│   └── ...
├── specs/                 # Requirements and specifications
└── test_oc_cfg.sh         # Test suite (42 tests, 100% coverage)
```

## License

MIT
