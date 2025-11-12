#!/bin/zsh

# macOS Development Environment Setup Script
# Enhanced version with error handling and logging

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup existing file
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warning "Backing up existing $file to $backup"
        cp "$file" "$backup"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check for iTerm2
    if [ ! -d "/Applications/iTerm.app" ]; then
        log_error "iTerm2 is not installed"
        echo "Please install iTerm2 from https://iterm2.com"
        exit 1
    fi
    
    # Check for macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Check for Xcode Command Line Tools
    if ! xcode-select -p &>/dev/null; then
        log_warning "Xcode Command Line Tools not found. Installing..."
        xcode-select --install
        read -p "Press Enter after Xcode Command Line Tools installation completes..."
    fi
    
    log_success "Prerequisites check passed"
}

# Get user information
get_user_info() {
    log_info "Setting up Git configuration..."
    
    # Get name with validation
    while true; do
        echo -n "Enter your full name: "
        read user_name
        if [[ -n "$user_name" ]]; then
            break
        else
            log_warning "Name cannot be empty"
        fi
    done
    
    # Get email with basic validation
    while true; do
        echo -n "Enter your email: "
        read user_email
        if [[ "$user_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            break
        else
            log_warning "Please enter a valid email address"
        fi
    done
    
    echo
    log_info "Configuration will use:"
    echo "  Name:  $user_name"
    echo "  Email: $user_email"
    echo
    echo -n "Continue? (y/n): "
    read confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warning "Setup cancelled by user"
        exit 0
    fi
}

# Configure Git
configure_git() {
    log_info "Configuring Git..."
    
    # Backup existing gitconfig
    backup_file "$HOME/.gitconfig"
    
    # Create gitconfig content
    local config='[alias]
         co = checkout
         br = branch
         ci = commit
         st = status
         unstage = reset HEAD --
         last = log -1 HEAD
         cim = commit -m
         ciam = commit -a -m
[core]
         excludesfile = ~/.gitignore
         editor = micro
[pull]
         rebase = false
[commit]
         gpgsign = false
[user]
         name = USER_NAME_PLACEHOLDER
         email = USER_EMAIL_PLACEHOLDER
[init]
         defaultBranch = main'
    
    # Replace placeholders
    config="${config//USER_NAME_PLACEHOLDER/$user_name}"
    config="${config//USER_EMAIL_PLACEHOLDER/$user_email}"
    
    # Write config
    echo "$config" > "$HOME/.gitconfig"
    
    # Create global gitignore if it doesn't exist
    if [ ! -f "$HOME/.gitignore" ]; then
        log_info "Creating global .gitignore..."
        cat > "$HOME/.gitignore" << 'EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride
Icon
._*
.Spotlight-V100
.Trashes

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# Logs
*.log
EOF
    fi
    
    log_success "Git configured successfully"
}

# Install Homebrew
install_homebrew() {
    if command_exists brew; then
        log_info "Homebrew already installed, updating..."
        brew update
    else
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
            log_error "Homebrew installation failed"
            exit 1
        }
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    log_success "Homebrew ready"
}

# Install Git
install_git() {
    if command_exists git; then
        log_info "Git already installed: $(git --version)"
    else
        log_info "Installing Git..."
        brew install git || {
            log_error "Git installation failed"
            exit 1
        }
        log_success "Git installed"
    fi
}

# Install Oh My Zsh
install_ohmyzsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "Oh My Zsh already installed"
    else
        log_info "Installing Oh My Zsh..."
        backup_file "$HOME/.zshrc"
        
        # Unattended installation
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
            log_error "Oh My Zsh installation failed"
            exit 1
        }
        log_success "Oh My Zsh installed"
    fi
}

# Install Powerlevel10k
install_powerlevel10k() {
    local p10k_path="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    
    if [ -d "$p10k_path" ]; then
        log_info "Powerlevel10k already installed"
    else
        log_info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_path" || {
            log_error "Powerlevel10k installation failed"
            exit 1
        }
        log_success "Powerlevel10k installed"
    fi
    
    # Update zshrc theme
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "ZSH_THEME=" "$HOME/.zshrc"; then
            perl -i -pe's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' "$HOME/.zshrc"
            log_success "Updated zshrc theme to Powerlevel10k"
        fi
    fi
}

# Install zsh-syntax-highlighting
install_syntax_highlighting() {
    local plugin_path="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    
    if [ -d "$plugin_path" ]; then
        log_info "zsh-syntax-highlighting already installed"
    else
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_path" || {
            log_warning "zsh-syntax-highlighting installation failed (non-critical)"
        }
        log_success "zsh-syntax-highlighting installed"
    fi
}

# Install CLI tools
install_cli_tools() {
    log_info "Installing CLI tools..."
    
    local tools=("lsd" "micro" "chroma")
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            log_info "$tool already installed"
        else
            log_info "Installing $tool..."
            brew install "$tool" || log_warning "Failed to install $tool (non-critical)"
        fi
    done
    
    log_success "CLI tools installation complete"
}

# Generate zshrc additions
generate_zshrc_additions() {
    log_info "Generating zshrc additions..."
    
    local additions_file="$HOME/zshrc_additions.txt"
    
    cat > "$additions_file" << 'EOF'
# ============================================
# Add these lines to your ~/.zshrc file
# ============================================

# Chroma configuration
ZSH_COLORIZE_TOOL="chroma"
ZSH_COLORIZE_STYLE="colorful"
ZSH_COLORIZE_CHROMA_FORMATTER="terminal16m"
ZSH_COLORIZE_STYLE="base16-snazzy"

# Oh My Zsh plugins
plugins=(
  colored-man-pages
  colorize
  git
  zsh-syntax-highlighting
  jsontools
  macos
)

# Custom aliases
alias zshconfig="micro ~/.zshrc"
alias ohmyzsh="micro ~/.oh-my-zsh"
alias nano="micro"
alias docker="podman"
alias pd="podman"
alias ll='lsd -l --group-dirs=first'
alias la='lsd -l -A --group-dirs=first'
alias cat=cat
alias less=less

# ============================================
EOF
    
    log_success "Generated zshrc additions at: $additions_file"
}

# Main installation flow
main() {
    echo
    log_info "================================================"
    log_info "macOS Development Environment Setup"
    log_info "================================================"
    echo
    
    # Run installation steps
    check_prerequisites
    get_user_info
    configure_git
    install_homebrew
    install_git
    install_ohmyzsh
    install_powerlevel10k
    install_syntax_highlighting
    install_cli_tools
    generate_zshrc_additions
    
    # Final instructions
    echo
    log_success "================================================"
    log_success "Installation Complete!"
    log_success "================================================"
    echo
    log_info "Next steps:"
    echo "  1. Review and add configurations from: ~/zshrc_additions.txt"
    echo "  2. Run: source ~/.zshrc"
    echo "  3. Restart your terminal or run: exec zsh"
    echo "  4. Configure Powerlevel10k: p10k configure"
    echo
    log_warning "IMPORTANT: Don't forget to add the configurations to ~/.zshrc!"
    echo
    log_info "Your original .zshrc and .gitconfig have been backed up if they existed."
    echo
}

# Run main function
main