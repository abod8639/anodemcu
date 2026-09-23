# Contributing to Anode MCU Manager

Thank you for your interest in contributing to Anode MCU Manager (`anodemcu`)! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

- Be respectful and inclusive.
- Provide constructive feedback.
- Focus on what is best for the community.
- Show empathy towards other community members.

## How to Contribute

### Reporting Bugs

Before creating a bug report, please check existing GitHub issues to avoid duplicates. When creating an issue, please include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs **actual behavior**
- **Environment details**:
  - Operating System & desktop environment (e.g., Arch Linux, Ubuntu, macOS)
  - Bash version: `bash --version`
  - Framework tools in use:
    - Arduino CLI: `arduino-cli version`
    - ESP-IDF: `idf.py --version` (if applicable)
    - PlatformIO: `pio --version` (if applicable)
  - Optional utilities:
    - fzf: `fzf --version`
    - jq: `jq --version`
- **Console output/errors** or screenshots when applicable

### Suggesting Enhancements

Enhancement suggestions are tracked via GitHub issues. When proposing an enhancement, include:

- **Clear title and summary**
- **Use case**: Why would this enhancement be useful?
- **Proposed solution**: How should it work from a user's perspective?
- **Alternatives considered**: What other approaches did you consider?

### Pull Requests

1. **Fork the repository** and create your branch from `main`.
2. **Make your changes**:
   - Follow the coding style guidelines below.
   - Keep features modular within `lib/`.
   - Add inline comments for non-obvious logic.
3. **Add or update tests**:
   - Add unit tests under `tests/unit/` or integration tests under `tests/integration/` when adding new features or fixing bugs.
   - Run the test suite: `make test`.
4. **Update documentation**:
   - Update `README.md` if any user-facing command, prerequisite, or behavior changes.
5. **Commit your changes**:
   - Use clear, conventional commit messages (e.g., `feat: ...`, `fix: ...`, `docs: ...`).
   - Reference open issue numbers where relevant.
6. **Submit a pull request**.

## Architecture & Coding Style

Anode MCU Manager uses a modular architecture where functionality is separated into specialized libraries under the `lib/` directory and loaded by the main `anodemcu` entrypoint.

### Shell Script Guidelines

- **Interpreter**: Use Bash syntax with strict mode where appropriate (`set -e`, `set -o pipefail`).
- **Indentation**: Use 4 spaces (no tabs).
- **Line length**: Keep lines under 100 characters when reasonable.
- **Function names**: Use lowercase with underscores (e.g., `detect_project_type`, `compile_sketch`).
- **Variables**:
  - Local variables: `local var_name="value"` (always declare `local` in functions).
  - Global/environment variables: UPPERCASE with underscores (e.g., `PROJECT`, `BOARD_FQBN`).
- **Quoting**: Always double-quote variable expansions (e.g., `"$var"`) to prevent word splitting and globbing.
- **Error handling**:
  - Check command exit codes.
  - Use `print_error` / `handle_error` utilities for consistent messaging.

### Color & UI Output

Utilize the standard color variables defined in `lib/utils.sh`:
- `C_RED`: Errors and critical failures
- `C_GREEN`: Success messages
- `C_YELLOW`: Warnings and prompts
- `C_BLUE`: Informational messages
- `C_CYAN`: Highlights and active options
- `C_RESET`: Reset formatting

## Testing Guidelines

The project uses [bats-core](https://github.com/bats-core/bats-core) for automated testing.

### Prerequisites

Install testing dependencies via `make`:
```bash
make install-test-deps
```
Or manually via npm/package manager:
```bash
npm install -g bats
# Or on Arch Linux:
# sudo pacman -S bats
```

### Running Tests

```bash
# Run all tests (unit + integration)
make test

# Run unit tests only
make test-unit

# Run integration tests only
make test-integration

# Run tests with verbose output
make test-verbose
```

Before submitting a PR, ensure all tests pass cleanly.

## Project Structure

```
anodemcu/
├── anodemcu               # Main CLI entrypoint
├── install.sh             # Interactive installation script
├── uninstall.sh           # Uninstallation script
├── build.sh               # Build script
├── Makefile               # Make targets (build, test, clean)
├── PKGBUILD               # Arch Linux AUR package configuration
├── .SRCINFO               # AUR package metadata
├── AUR_INSTRUCTIONS.md    # Instructions for AUR maintainers
├── README.md              # Main project documentation
├── CONTRIBUTING.md        # Contribution guidelines (this file)
├── LICENSE                # MIT License
├── lib/                   # Modular script libraries
│   ├── config.sh          # Configuration and settings storage
│   ├── utils.sh           # Logging, error handling, and helpers
│   ├── ui.sh              # Menus, prompts, and fzf integration
│   ├── platform.sh        # Framework detection (Arduino, ESP-IDF, PlatformIO)
│   ├── projects.sh        # Project creation, discovery, and selection
│   ├── boards.sh          # Board selection and architecture config
│   ├── ports.sh           # Serial port detection and management
│   ├── sketch.sh          # Compilation, uploading, and serial monitor
│   ├── libraries.sh       # Library search, installation, and removal
│   └── cores.sh           # Core platform packages management
└── tests/                 # Bats test suites
    ├── setup_suite.bash   # Global test setup
    ├── teardown_suite.bash# Global test cleanup
    ├── helpers/           # Mocks and custom test assertions
    ├── unit/              # Unit tests for individual modules
    └── integration/       # Multi-step workflow integration tests
```

## Questions & Support

If you have questions about contributing:
- Open a GitHub issue with the `question` label.
- Review existing discussions, pull requests, and the [README.md](README.md).

## License

By contributing to Anode MCU Manager, you agree that your contributions will be licensed under the project's [MIT License](LICENSE).
