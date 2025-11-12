Here's an updated README for your development-utilities repository:

---

# Development Utilities

A curated collection of automation scripts, configuration tools, and utilities designed to streamline development workflows and system setup on macOS.

## Contents

### System Configuration

- **[initial-install](./initial-install/)** - Comprehensive shell script for bootstrapping a complete macOS development environment with Homebrew, Git configuration, Oh My Zsh, Powerlevel10k, and essential CLI tools

- **[iterm2-config](./iterm2-config/)** - Pre-configured iTerm2 settings and profiles for a production-ready terminal experience, including hotkey window setup and theme configurations

- **[nerd-fonts](./nerd-fonts/)** - Collection of patched programmer fonts with extended glyph support for powerline, devicons, and other terminal enhancements

### Development Tools

- **[git-cleaner](./git-cleaner/)** - Repository maintenance utility using BFG Repo-Cleaner for removing sensitive data, large files, and cleaning Git history

- **[git-mirror](./git-mirror/)** - Another repository cloning utility allowing to clone the WHOLE git repository, including WHOLE history from ALL branches. Beware: repositories might be too heavy in size!

### Productivity Scripts

- **[calendar-cleaner](./calendar-cleaner/)** - Python utility for filtering ICS calendar files by date, designed to manage large calendars and remove historical events while preserving metadata

## Getting Started

Each utility includes its own detailed documentation with installation instructions, usage examples, and troubleshooting guides. Navigate to the specific tool's directory and refer to its README file for complete information.

## Requirements

- macOS (Intel or Apple Silicon)
- Python 3.6+ (for Python-based utilities)
- Bash/Zsh shell (for shell scripts)
- Specific tools may have additional prerequisites detailed in their respective READMEs. Each utility includes its own detailed documentation. See individual README files for specific usage instructions, requirements, and features.

## License

This repository is under MIT License if not specified directly by nested utility. See individual LICENSE files in each utility directory for specific licensing information.

---

**Last Updated**: November 2025

