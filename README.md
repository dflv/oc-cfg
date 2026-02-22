# OpenCode Configuration

[![Tests](https://img.shields.io/badge/tests-42%20passing-brightgreen)](test_oc_cfg.sh)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

One-click setup for [OpenCode](https://opencode.ai) AI configuration, including office document skills (PDF, DOCX, XLSX, PPTX) and coding utilities.

## Features

- **Zero-config deployment**: Single command setup
- **Safety-first**: Never overwrites existing files
- **Office document suite**: PDF forms, Word docs, Excel sheets, PowerPoint
- **Code review tools**: Security checklists and best practices
- **100% test coverage**: 42 comprehensive test cases

## Quick Start

```bash
# Deploy all configurations
./oc-cfg.sh

# Verify everything works
./test_oc_cfg.sh
```

## What Gets Installed

| Source | Destination | Contents |
|--------|-------------|----------|
| `AGENTS_md/` | `~/.config/opencode/` | AI agent guidance |
| `commands/` | `~/.opencode/commands/` | Slash commands (`/gcom`) |
| `skills/` | `~/.config/opencode/skills/` | Document & code tools |

## Included Skills

### Office Documents

| Skill | Description | Key Capabilities |
|-------|-------------|------------------|
| `pdf` | PDF operations | Fill forms, extract text, OCR, merge, split |
| `docx` | Word documents | Create, edit, comments, track changes |
| `xlsx` | Excel spreadsheets | Read, modify, formulas, validation |
| `pptx` | PowerPoint | Create slides, extract thumbnails |

### Development Tools

| Skill | Description |
|-------|-------------|
| `code-review-excellence` | Code review best practices and templates |
| `security-review` | Security audit checklists |
| `cpp-pro` | Modern C++ patterns and idioms |
| `c-pro` | System programming with C |
| `algorithmic-art` | Generative art with p5.js |
| `find-skills` | Discover and install additional skills |

## Safety Features

- **No overwrites**: Exits with error if files exist
- **Atomic operations**: All-or-nothing deployment
- **Backup verification**: Tests confirm real configs are never touched

## Development

### Testing

```bash
# Run full test suite (42 tests)
./test_oc_cfg.sh

# Run specific test branch
./test_oc_cfg.sh 2>&1 | sed -n '/Branch 7:/,/Branch 8:/p'
```

### Code Quality

```bash
# Bash linting
shellcheck oc-cfg.sh test_oc_cfg.sh

# Python linting and type checking
ruff check skills/
mypy skills/
```

## Directory Structure

```
oc-cfg/
├── oc-cfg.sh          # Main deployment script
├── test_oc_cfg.sh     # Test suite (100% coverage)
├── AGENTS.md          # AI agent configuration
├── AGENTS_md/         # Source: agent guidance files
├── commands/          # Source: slash commands
├── skills/            # Source: skill definitions
│   ├── pdf/
│   ├── docx/
│   ├── xlsx/
│   └── ...
├── _config/           # Configuration snippets
└── specs/             # Requirements docs
```

## Requirements

- Linux environment
- Bash 4.0+
- Python 3.8+ (for skills)
- Git

## License

MIT License - See [LICENSE](LICENSE) for details.
