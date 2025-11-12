# macOS Development Environment Setup Script

A shell script for bootstrapping a production-ready macOS development environment. Automates installation of essential dev tools, configures Git with power-user aliases, and sets up a modern terminal stack with Oh My Zsh and Powerlevel10k. Built with defensive programming practices including error handling, atomic operations with automatic rollback capability, and structured logging.

## Features

✅ **Safe & Idempotent** - Run multiple times without breaking existing setup  
✅ **Automatic Backups** - Preserves your existing configurations with timestamps  
✅ **Color-Coded Logging** - Clear visual feedback for all operations  
✅ **Input Validation** - Ensures valid user data before making changes  
✅ **Apple Silicon Support** - Optimized for both Intel and M1 - M5 Macs  
✅ **Error Handling** - Graceful failures with informative messages  
✅ **Prerequisite Checks** - Verifies system requirements before installation  

## Prerequisites

- **macOS** (Intel or Apple Silicon)
- **iTerm2** installed ([Download here](https://iterm2.com))
- **Active internet connection**
- **Administrator privileges** (for Homebrew installation)

The script will automatically check for and offer to install Xcode Command Line Tools if missing.

## What This Script Installs

### Package Manager
- **Homebrew** - The missing package manager for macOS

### Version Control
- **Git** - Distributed version control system
- Configures global `.gitconfig` with useful aliases
- Creates global `.gitignore` with sensible defaults

### Terminal Enhancements
- **Oh My Zsh** - Framework for managing zsh configuration
- **Powerlevel10k** - Beautiful and fast zsh theme with rich customization
- **zsh-syntax-highlighting** - Fish-like syntax highlighting for zsh

### CLI Tools
- **LSD (LSDeluxe)** - Modern `ls` replacement with icons and colors
- **Micro** - Modern, intuitive terminal-based text editor
- **Chroma** - Syntax highlighter for terminal output

## Installation

### Quick Start

```bash
# Download the script
curl -O https://your-repo/setup-improved.sh

# Make it executable
chmod +x setup-improved.sh

# Run the script
./setup-improved.sh
```

### What Happens During Installation

1. **Prerequisites Check**
   - Verifies iTerm2 is installed
   - Confirms macOS operating system
   - Checks for Xcode Command Line Tools

2. **User Configuration**
   - Prompts for your full name (with validation)
   - Prompts for your email (with regex validation)
   - Shows confirmation before proceeding

3. **Git Setup**
   - Backs up existing `.gitconfig` (if present)
   - Creates new Git configuration with your details
   - Generates global `.gitignore` file

4. **Tool Installation**
   - Installs or updates Homebrew
   - Installs Git (if not present)
   - Installs Oh My Zsh (unattended mode)
   - Installs Powerlevel10k theme
   - Installs zsh-syntax-highlighting plugin
   - Installs CLI tools (lsd, micro, chroma)

5. **Configuration Generation**
   - Creates `~/zshrc_additions.txt` with recommended settings
   - Provides clear next steps

## Git Configuration

### Aliases Included

| Alias | Command | Description |
|-------|---------|-------------|
| `co` | `checkout` | Switch branches or restore files |
| `br` | `branch` | List, create, or delete branches |
| `ci` | `commit` | Record changes to repository |
| `st` | `status` | Show working tree status |
| `unstage` | `reset HEAD --` | Remove files from staging area |
| `last` | `log -1 HEAD` | Show last commit |
| `cim` | `commit -m` | Commit with message |
| `ciam` | `commit -a -m` | Commit all changes with message |

### Additional Git Settings

- **Default editor**: micro
- **Default branch**: main
- **Pull strategy**: merge (not rebase)
- **GPG signing**: disabled by default
- **Global ignore file**: `~/.gitignore`

## Post-Installation Steps

After the script completes, follow these steps:

### 1. Review Generated Configurations

```bash
cat ~/zshrc_additions.txt
```

### 2. Add Configurations to ~/.zshrc

Open your `.zshrc` file:

```bash
micro ~/.zshrc
```

Add the following sections:

#### Chroma Configuration
```bash
ZSH_COLORIZE_TOOL="chroma"
ZSH_COLORIZE_STYLE="colorful"
ZSH_COLORIZE_CHROMA_FORMATTER="terminal16m"
ZSH_COLORIZE_STYLE="base16-snazzy"
```

#### Oh My Zsh Plugins
```bash
plugins=(
  colored-man-pages
  colorize
  git
  zsh-syntax-highlighting
  jsontools
  macos
)
```

#### Custom Aliases
```bash
alias zshconfig="micro ~/.zshrc"
alias ohmyzsh="micro ~/.oh-my-zsh"
alias nano="micro"
alias docker="podman"
alias pd="podman"
alias ll='lsd -l --group-dirs=first'
alias la='lsd -l -A --group-dirs=first'
alias cat=cat
alias less=less
```

### 3. Apply Changes

```bash
# Reload configuration
source ~/.zshrc

# Or restart your shell
exec zsh
```

### 4. Configure Powerlevel10k

Run the configuration wizard:

```bash
p10k configure
```

Follow the interactive prompts to customize your prompt appearance.

## Script Features in Detail

### Color-Coded Output

The script uses color-coded logging for better visibility:

- 🔵 **INFO** - General information messages
- 🟢 **SUCCESS** - Successful operations
- 🟡 **WARNING** - Non-critical issues or notifications
- 🔴 **ERROR** - Critical failures

### Automatic Backups

Before modifying any existing configuration files, the script creates timestamped backups:

```
~/.gitconfig → ~/.gitconfig.backup.20241112_143022
~/.zshrc → ~/.zshrc.backup.20241112_143023
```

### Input Validation

- **Name validation**: Ensures non-empty input
- **Email validation**: Uses regex to verify valid email format
- **Confirmation prompt**: Shows summary before making changes

### Idempotent Design

The script safely handles existing installations:

- ✅ Skips already-installed tools
- ✅ Updates Homebrew if present
- ✅ Preserves existing configurations
- ✅ Can be run multiple times without issues

### Apple Silicon Support

Automatically detects ARM64 architecture and:
- Uses correct Homebrew installation path (`/opt/homebrew`)
- Adds Homebrew to PATH in `.zprofile`
- Ensures shell environment is properly configured

## Troubleshooting

### iTerm2 Not Found

**Error**: "iTerm2 is not installed"

**Solution**: 
1. Download iTerm2 from [iterm2.com](https://iterm2.com)
2. Install the application
3. Run the script again

### Xcode Command Line Tools Required

**Error**: Xcode tools not found

**Solution**: 
The script will automatically prompt you to install them. Follow the system prompts and press Enter when complete.

### Homebrew Installation Failed

**Possible causes**:
- No internet connection
- Insufficient permissions
- Xcode Command Line Tools missing

**Solution**:
1. Check internet connection
2. Ensure Xcode Command Line Tools: `xcode-select --install`
3. Visit [brew.sh](https://brew.sh) for manual installation
4. Run the script again

### Oh My Zsh Already Installed

If Oh My Zsh is already installed, the script will:
- Detect the existing installation
- Skip reinstallation
- Continue with other components

### Permission Denied Errors

**Solution**:
```bash
# Ensure script is executable
chmod +x setup-improved.sh

# Check file permissions
ls -la setup-improved.sh
```

### Powerlevel10k Not Loading

**Solution**:
1. Verify theme in `~/.zshrc`: `ZSH_THEME="powerlevel10k/powerlevel10k"`
2. Check installation: `ls ~/.oh-my-zsh/custom/themes/powerlevel10k`
3. Reload configuration: `source ~/.zshrc`
4. Run configuration wizard: `p10k configure`

### Colors Not Showing

**Solution**:
1. Ensure you're using iTerm2 (not default Terminal.app)
2. Check iTerm2 color settings: Preferences → Profiles → Colors
3. Verify terminal type: `echo $TERM` should show `xterm-256color`

## Backup Recovery

If you need to restore your previous configuration:

```bash
# List available backups
ls -la ~/*.backup.*

# Restore gitconfig
cp ~/.gitconfig.backup.YYYYMMDD_HHMMSS ~/.gitconfig

# Restore zshrc
cp ~/.zshrc.backup.YYYYMMDD_HHMMSS ~/.zshrc

# Reload configuration
source ~/.zshrc
```

## Customization

### Modify Git Aliases

Edit the `configure_git()` function in the script to add or modify Git aliases:

```bash
local config='[alias]
         your_alias = your_command
         # ... other aliases'
```

### Change Default Git Editor

In the script, modify line 131:

```bash
editor = nano  # or vim, code, etc.
```

### Add More CLI Tools

In the `install_cli_tools()` function, add to the tools array:

```bash
local tools=("lsd" "micro" "chroma" "htop" "jq" "bat")
```

### Modify Plugin List

Edit the `generate_zshrc_additions()` function to customize plugins:

```bash
plugins=(
  colored-man-pages
  colorize
  git
  zsh-syntax-highlighting
  jsontools
  macos
  your-custom-plugin
)
```

## Uninstallation

To remove components installed by this script:

### Remove Oh My Zsh
```bash
uninstall_oh_my_zsh
```

### Uninstall Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

### Restore Original Configurations
```bash
# Restore from backups
cp ~/.gitconfig.backup.YYYYMMDD_HHMMSS ~/.gitconfig
cp ~/.zshrc.backup.YYYYMMDD_HHMMSS ~/.zshrc
```

## Security Considerations

- Script downloads installation scripts from official, trusted sources
- User credentials (name/email) stored in plaintext in `~/.gitconfig`
- No passwords or sensitive data are collected
- All network requests use HTTPS
- Review script contents before execution

## Compatibility

### Tested On
- ✅ macOS Sonoma (14.x)
- ✅ Apple Silicon (M1/M2/M3)

### Requirements
- macOS 26 (Tahoe) or later
- Zsh (default shell since macOS Catalina)
- At least 2GB free disk space

## FAQ

**Q: Can I run this script multiple times?**  
A: Yes! The script is idempotent and will skip already-installed components.

**Q: Will this overwrite my existing configurations?**  
A: No. The script creates timestamped backups before modifying any files.

**Q: Do I need to restart my computer?**  
A: No. Just restart your terminal or run `exec zsh`.

**Q: Can I use this with Terminal.app instead of iTerm2?**  
A: The script requires iTerm2, but you can modify the prerequisite check if needed.

**Q: What if I don't want some components?**  
A: Comment out the corresponding function calls in the `main()` function.

**Q: Is this safe to run on my work computer?**  
A: Yes, but review your company's IT policies first. The script doesn't modify system files.

## Contributing

Suggestions and improvements are welcome! Consider:

- Additional CLI tools that would benefit developers
- Better error handling for edge cases
- Support for additional terminal emulators
- More comprehensive `.gitignore` patterns

## License

This script is provided as-is for personal use. Modify and distribute freely.

## Credits

Built for macOS developers who value automation and a beautiful terminal experience.

### Tools Used
- [Homebrew](https://brew.sh) - Package manager
- [Oh My Zsh](https://ohmyz.sh) - Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [LSD](https://github.com/Peltoche/lsd) - Modern ls
- [Micro](https://micro-editor.github.io) - Terminal editor
- [Chroma](https://github.com/alecthomas/chroma) - Syntax highlighter

---

**Note**: Always review scripts before executing them, especially those requiring administrator privileges or downloading content from the internet.

**Last Updated**: November 2025  
**Version**: 2.0 (Enhanced)