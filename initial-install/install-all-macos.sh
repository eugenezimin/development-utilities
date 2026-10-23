#!/bin/zsh

# macOS Development Environment Setup Script
#
# Restores this Mac's setup on a new machine: Homebrew formulae and casks,
# App Store apps, fonts, the zsh config (antidote + starship), git config,
# VS Code / iTerm2 settings and dev toolchains. Every step and every app is
# chosen at runtime from checklists (gum); all questions come first, then
# the installation runs unattended.
#
# Usage:
#   ./install-all-macos.sh              interactive install
#   ./install-all-macos.sh --all        no prompts, install the manifest defaults
#   ./install-all-macos.sh --dry-run    show what would run, change nothing
#   ./install-all-macos.sh --snapshot   refresh dotfiles/ and packages.conf from this Mac
#
# The app list lives in packages.conf next to this script.

set -e  # Exit on error
set -u  # Exit on undefined variable
setopt extended_glob

SCRIPT_PATH=${0:A}
SCRIPT_DIR=${SCRIPT_PATH:h}
REPO_DIR=${SCRIPT_DIR:h}
MANIFEST="$SCRIPT_DIR/packages.conf"
DOTFILES="$SCRIPT_DIR/dotfiles"
ZDOT_TARGET="$HOME/.config/zsh"
VSCODE_USER="$HOME/Library/Application Support/Code/User"
VSCODE_CONFIG="$REPO_DIR/vscode-configuration-dark"

# zsh files copied by --snapshot (conf.d/*.zsh is copied as a whole)
ZSH_FILES=(.zshenv .zprofile .zshrc .zsh_plugins.txt .p10k.zsh plugins.zsh prompt.zsh)

# Tools this script installs for itself; --snapshot doesn't add them to the manifest
SELF_TOOLS=(gum mas)

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

log_header() {
    echo
    log_info "================================================"
    log_info "$1"
    log_info "================================================"
}

usage() {
    sed -n '/^# Usage:/,/^# The app list/p' "$SCRIPT_PATH" | sed 's/^# \{0,1\}//'
}

# Options
ALL=0
DRY_RUN=0
MODE=install
for arg in "$@"; do
    case $arg in
        --all)      ALL=1 ;;
        --dry-run)  DRY_RUN=1 ;;
        --snapshot) MODE=snapshot ;;
        -h|--help)  usage; exit 0 ;;
        *)          log_error "Unknown option: $arg"; usage; exit 1 ;;
    esac
done

# Results for the final summary
INSTALLED=()
FAILED=()
MANUAL=()

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Run a command, or only print it in --dry-run mode
run() {
    if (( DRY_RUN )); then
        echo "  ${YELLOW}[dry-run]${NC} ${(j: :)${(q-)@}}"
        return 0
    fi
    "$@"
}

# Run a command and record it as installed or failed; never aborts the script
track() {
    local label=$1
    shift
    if run "$@"; then
        INSTALLED+=("$label")
    else
        FAILED+=("$label")
        log_warning "Failed: $label (continuing)"
    fi
}

# Function to backup an existing file or directory
backup_file() {
    local target=$1
    if [[ -e "$target" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warning "Backing up existing $target to $backup"
        run cp -R "$target" "$backup"
    fi
}

# ------------------------------------------------------------------
# Manifest and installed-state detection
# ------------------------------------------------------------------

typeset -a M_CAT M_TYPE M_ID M_DESC M_DEF
typeset -A HAVE       # "type:id" -> 1 for everything already on this Mac
typeset -A MAS_NAMES  # App Store ID -> app name (for --snapshot)

load_manifest() {
    local line
    local -a f
    [[ -r "$MANIFEST" ]] || { log_error "Manifest not found: $MANIFEST"; exit 1; }
    while IFS= read -r line || [[ -n $line ]]; do
        [[ $line == [[:space:]]#(\#*|) ]] && continue
        f=("${(@s:|:)line}")
        if (( ${#f} != 5 )); then
            log_warning "Skipping malformed manifest line: $line"
            continue
        fi
        f=("${(@)${(@)f##[[:space:]]#}%%[[:space:]]#}")
        M_CAT+=("$f[1]")
        M_TYPE+=("$f[2]")
        M_ID+=("$f[3]")
        M_DESC+=("$f[4]")
        M_DEF+=("$f[5]")
    done < "$MANIFEST"
}

detect_installed() {
    local x app id
    if command_exists brew; then
        for x in ${(f)"$(brew list --formula -1 2>/dev/null)"}; do HAVE[formula:$x]=1; done
        for x in ${(f)"$(brew list --cask -1 2>/dev/null)"}; do HAVE[cask:$x]=1; done
        detect_unmanaged_casks
    fi

    # App Store apps carry their store ID in Spotlight metadata (works without mas or sign-in)
    for app in /Applications/*.app(N); do
        id=$(mdls -raw -name kMDItemAppStoreAdamID "$app" 2>/dev/null) || continue
        if [[ $id == <-> ]]; then
            HAVE[mas:$id]=1
            MAS_NAMES[$id]=${app:t:r}
        fi
    done
}

# Apps and fonts installed by hand (not through brew) still count as installed;
# brew would refuse to overwrite them anyway.
detect_unmanaged_casks() {
    local -a casks
    local i token
    for (( i = 1; i <= ${#M_ID}; i++ )); do
        [[ $M_TYPE[i] == cask && -z ${HAVE[cask:$M_ID[i]]-} ]] && casks+=("$M_ID[i]")
    done
    (( ${#casks} )) || return 0

    for token in ${(f)"$(brew info --cask --json=v2 "${casks[@]}" 2>/dev/null | /usr/bin/python3 -c '
import json, os, sys
fonts = os.path.expanduser("~/Library/Fonts")
for c in json.load(sys.stdin)["casks"]:
    paths = []
    for a in c.get("artifacts", []):
        for item in a.get("app", []):
            if isinstance(item, str):
                paths.append("/Applications/" + os.path.basename(item))
            elif isinstance(item, dict) and "target" in item:
                paths.append(item["target"])
        if "target" in a and isinstance(a["target"], str):
            paths.append(a["target"])
        for item in a.get("font", [])[:1]:
            if isinstance(item, str):
                paths.append(os.path.join(fonts, os.path.basename(item)))
        if "pkg" in a:
            paths += ["/Applications/%s.app" % n for n in c.get("name", [])]
    if any(os.path.exists(p) for p in paths):
        print(c["token"])
' 2>/dev/null)"}; do
        HAVE[cask:$token]=1
    done
}

is_installed() {
    (( ${+HAVE[$1:$2]} ))
}

# ------------------------------------------------------------------
# Checklists
# ------------------------------------------------------------------

# pick <header> <defaults-csv> <items...>: prints the chosen items, one per line.
# With --all (or without gum) the defaults are chosen without asking.
pick() {
    local header=$1 defaults=$2 item
    shift 2
    (( $# )) || return 0
    if (( ALL )) || ! command_exists gum; then
        for item in "$@"; do
            [[ ",$defaults," == *",$item,"* ]] && print -r -- "$item"
        done
        return 0
    fi
    gum choose --no-limit --height 25 --header "$header" --selected "$defaults" "$@"
}

# Strip the " — description" part of a checklist label
label_id() {
    print -r -- "${1%% — *}"
}

# ask <prompt> <default>: free-text input
ask() {
    local prompt=$1 default=$2 answer
    if command_exists gum; then
        gum input --prompt "$prompt: " --value "$default"
    else
        read "answer?$prompt [$default]: "
        print -r -- "${answer:-$default}"
    fi
}

confirm() {
    if command_exists gum; then
        gum confirm "$1"
    else
        local reply
        read "reply?$1 (y/n): "
        [[ $reply == [Yy]* ]]
    fi
}

# ------------------------------------------------------------------
# Preflight
# ------------------------------------------------------------------

check_prerequisites() {
    log_info "Checking prerequisites..."

    if [[ "$OSTYPE" != darwin* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi

    if ! xcode-select -p &>/dev/null; then
        log_warning "Xcode Command Line Tools not found. Installing..."
        run xcode-select --install
        if (( ! DRY_RUN )); then
            read "?Press Enter after the Xcode Command Line Tools installation completes..."
        fi
    fi

    log_success "Prerequisites check passed"
}

install_homebrew() {
    if command_exists brew; then
        log_info "Homebrew already installed, updating..."
        run brew update || log_warning "brew update failed (non-critical)"
    else
        log_info "Installing Homebrew..."
        if (( DRY_RUN )); then
            echo "  ${YELLOW}[dry-run]${NC} /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
                log_error "Homebrew installation failed"
                exit 1
            }
        fi
    fi

    # Make brew available in this session (the restored .zprofile does it for new shells)
    local brew_bin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x $brew_bin ]]; then
            eval "$($brew_bin shellenv)"
            break
        fi
    done
    log_success "Homebrew ready"
}

install_gum() {
    (( ALL )) && return 0
    if command_exists gum; then
        return 0
    fi
    if (( DRY_RUN )); then
        log_warning "gum is not installed; the dry run uses the manifest defaults instead of checklists"
        return 0
    fi
    log_info "Installing gum for the interactive checklists..."
    brew install gum || {
        log_error "Could not install gum"
        exit 1
    }
}

# ------------------------------------------------------------------
# Questions (everything is asked up front)
# ------------------------------------------------------------------

typeset -a STEPS TODO VSCODE_TODO TOOLCHAINS REPO_FONTS
GIT_NAME=""
GIT_EMAIL=""

step_on() {
    (( ${STEPS[(Ie)$1]} ))
}

todo_add() {
    (( ${TODO[(Ie)$1]} )) || TODO+=("$1")
}

choose_steps() {
    local -a labels=(
        "git — Git config and global gitignore"
        "shell — zsh config (antidote + starship) from dotfiles/"
        "apps — Homebrew formulae and apps"
        "appstore — App Store apps (needs App Store sign-in)"
        "fonts — Nerd Fonts and fonts from nerd-fonts/"
        "configs — VS Code and iTerm2 settings from this repo"
        "toolchains — Node / Rust / Java"
        "mail — Flagged-mail reminders LaunchAgent"
    )
    local -a chosen
    chosen=(${(f)"$(pick "Which steps should run? (space toggles, enter confirms)" "${(j:,:)labels}" "${labels[@]}")"})
    STEPS=(${chosen%% — *})
}

ask_git_info() {
    local current_name current_email
    current_name=$(git config --global user.name 2>/dev/null || true)
    current_email=$(git config --global user.email 2>/dev/null || true)

    if (( ALL )); then
        if [[ -n $current_name && -n $current_email ]]; then
            GIT_NAME=$current_name
            GIT_EMAIL=$current_email
        else
            log_warning "No git identity found and --all asks no questions; skipping the git step"
            STEPS=(${STEPS:#git})
        fi
        return 0
    fi

    log_info "Git identity"
    while true; do
        GIT_NAME=$(ask "Full name" "$current_name")
        [[ -n "$GIT_NAME" ]] && break
        log_warning "Name cannot be empty"
    done
    while true; do
        GIT_EMAIL=$(ask "Email" "$current_email")
        [[ "$GIT_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] && break
        log_warning "Please enter a valid email address"
    done
}

# choose_category <category> [extra labels...]: checklist of the not-yet-installed items
choose_category() {
    local category=$1 i label
    shift
    local -a labels defaults present chosen
    labels=("$@")
    defaults=("$@")
    for (( i = 1; i <= ${#M_ID}; i++ )); do
        [[ $M_CAT[i] == "$category" ]] || continue
        if is_installed "$M_TYPE[i]" "$M_ID[i]"; then
            present+=("$M_DESC[i]")
            continue
        fi
        label="$M_TYPE[i]:$M_ID[i] — $M_DESC[i]"
        labels+=("$label")
        [[ $M_DEF[i] == on ]] && defaults+=("$label")
    done

    (( ${#present} )) && log_info "$category: already installed: ${(j:, :)present}"
    if (( ! ${#labels} )); then
        log_success "$category: nothing left to install"
        return 0
    fi

    chosen=(${(f)"$(pick "$category: choose what to install" "${(j:,:)defaults}" "${labels[@]}")"})
    for label in "${chosen[@]}"; do
        todo_add "$(label_id "$label")"
    done
}

choose_apps() {
    local category
    for category in ${(u)M_CAT}; do
        [[ $category == ("App Store"|Fonts|Manual) ]] && continue
        choose_category "$category"
    done
}

choose_fonts() {
    local dir name label f
    local -a extra chosen
    for dir in "$REPO_DIR"/nerd-fonts/*(N/); do
        name=${dir:t}
        # Skip folders that are fully installed in ~/Library/Fonts already
        local -a files=("$dir"/*.(ttf|otf)(N)) missing=()
        for f in "${files[@]}"; do
            [[ -e "$HOME/Library/Fonts/${f:t}" ]] || missing+=("$f")
        done
        (( ${#missing} )) || continue
        extra+=("repo:$name — copy from nerd-fonts/")
    done
    choose_category Fonts "${extra[@]}"

    # Repo folders were queued as "repo:<name>"; move them to their own list
    for label in ${(M)TODO:#repo:*}; do
        REPO_FONTS+=("${label#repo:}")
    done
    TODO=(${TODO:#repo:*})
}

choose_configs() {
    local -a labels=(
        "vscode — VS Code settings + keybindings + extensions"
        "iterm2 — iTerm2 preferences loaded from iterm2-config/"
    )
    local -a chosen
    chosen=(${(f)"$(pick "Which app configs should be restored?" "${(j:,:)labels}" "${labels[@]}")"})
    VSCODE_TODO=(${chosen%% — *})
}

choose_toolchains() {
    local -a labels=(
        "node — Node 20 and 24 via nvm + pnpm and serverless"
        "rust — rustup + cargo-deny and cargo-nextest"
        "java — Oracle JDK 25 (opens the download page)"
    )
    local -a chosen
    chosen=(${(f)"$(pick "Which toolchains should be installed?" "${(j:,:)labels}" "${labels[@]}")"})
    TOOLCHAINS=(${chosen%% — *})
}

# Add packages that the chosen steps depend on
add_dependencies() {
    if step_on shell; then
        is_installed formula antidote || todo_add formula:antidote
        is_installed formula starship || todo_add formula:starship
    fi
    if (( ${TOOLCHAINS[(Ie)node]} )); then
        is_installed formula nvm || todo_add formula:nvm
    fi
    if (( ${VSCODE_TODO[(Ie)vscode]} )) && ! command_exists code && ! is_installed cask visual-studio-code; then
        todo_add cask:visual-studio-code
    fi
    if (( ${#${(M)TODO:#mas:*}} )) && ! command_exists mas; then
        todo_add formula:mas
    fi
}

ask_everything() {
    log_header "Choose what to set up"
    choose_steps
    if (( ! ${#STEPS} )); then
        log_warning "No steps selected, nothing to do"
        exit 0
    fi

    detect_installed
    step_on git        && ask_git_info
    step_on apps       && choose_apps
    step_on appstore   && choose_category "App Store"
    step_on fonts      && choose_fonts
    step_on configs    && choose_configs
    step_on toolchains && choose_toolchains
    add_dependencies

    log_header "Plan"
    echo "  Steps:      ${(j:, :)STEPS}"
    echo "  Packages:   ${#TODO} to install"
    local item
    for item in "${TODO[@]}"; do
        echo "              $item"
    done
    (( ${#REPO_FONTS} ))  && echo "  Repo fonts: ${(j:, :)REPO_FONTS}"
    (( ${#VSCODE_TODO} )) && echo "  Configs:    ${(j:, :)VSCODE_TODO}"
    (( ${#TOOLCHAINS} ))  && echo "  Toolchains: ${(j:, :)TOOLCHAINS}"
    echo

    if (( ! ALL && ! DRY_RUN )); then
        confirm "Start the installation?" || {
            log_warning "Setup cancelled by user"
            exit 0
        }
    fi
}

# ------------------------------------------------------------------
# Installation steps
# ------------------------------------------------------------------

configure_git() {
    log_header "Git"
    backup_file "$HOME/.gitconfig"

    local config="[alias]
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
	name = $GIT_NAME
	email = $GIT_EMAIL
[init]
	defaultBranch = main
[mergetool]
	keepBackup = true"

    if (( DRY_RUN )); then
        echo "  ${YELLOW}[dry-run]${NC} write ~/.gitconfig for $GIT_NAME <$GIT_EMAIL>"
    else
        print -r -- "$config" > "$HOME/.gitconfig"
    fi

    if [[ ! -f "$HOME/.gitignore" ]]; then
        run cp "$DOTFILES/gitignore" "$HOME/.gitignore"
    fi
    log_success "Git configured"
}

install_packages() {
    local item type id
    local -a formulae casks apps

    formulae=(${${(M)TODO:#formula:*}#formula:})
    casks=(${${(M)TODO:#cask:*}#cask:})
    apps=(${${(M)TODO:#mas:*}#mas:})

    if (( ${#formulae} )); then
        log_header "Homebrew formulae (${#formulae})"
        for id in "${formulae[@]}"; do
            log_info "Installing $id..."
            track "$id" brew install "$id"
        done
    fi

    if (( ${#casks} )); then
        log_header "Homebrew apps (${#casks})"
        for id in "${casks[@]}"; do
            log_info "Installing $id..."
            track "$id" brew install --cask "$id"
        done
    fi

    if (( ${#apps} )); then
        log_header "App Store apps (${#apps})"
        log_warning "You must be signed in to the App Store app for these to install"
        for id in "${apps[@]}"; do
            log_info "Installing $(manifest_desc mas "$id") ($id)..."
            track "$(manifest_desc mas "$id")" mas install "$id"
        done
    fi
}

manifest_desc() {
    local i
    for (( i = 1; i <= ${#M_ID}; i++ )); do
        if [[ $M_TYPE[i] == "$1" && $M_ID[i] == "$2" ]]; then
            print -r -- "$M_DESC[i]"
            return 0
        fi
    done
    print -r -- "$2"
}

install_repo_fonts() {
    (( ${#REPO_FONTS} )) || return 0
    log_header "Fonts from nerd-fonts/"
    local name
    run mkdir -p "$HOME/Library/Fonts"
    for name in "${REPO_FONTS[@]}"; do
        local -a files=("$REPO_DIR/nerd-fonts/$name"/*.(ttf|otf)(N))
        track "font: $name" cp "${files[@]}" "$HOME/Library/Fonts/"
    done
}

restore_shell() {
    log_header "Shell"
    log_info "Restoring zsh config (ZDOTDIR=$ZDOT_TARGET)..."
    backup_file "$HOME/.zshenv"
    backup_file "$ZDOT_TARGET"
    backup_file "$HOME/.config/starship.toml"

    # Copy over the existing directory so history, sessions and .zsh_secrets survive
    run mkdir -p "$ZDOT_TARGET/conf.d"
    run cp "$DOTFILES/zshenv" "$HOME/.zshenv"
    run cp -R "$DOTFILES/zsh/." "$ZDOT_TARGET/"
    run cp "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"

    if [[ ! -e "$ZDOT_TARGET/.zsh_secrets" ]]; then
        run touch "$ZDOT_TARGET/.zsh_secrets"
        run chmod 600 "$ZDOT_TARGET/.zsh_secrets"
        MANUAL+=("Add API keys and tokens to $ZDOT_TARGET/.zsh_secrets")
    fi

    # With ZDOTDIR set, zsh no longer reads these
    local old
    for old in "$HOME/.zshrc" "$HOME/.zprofile"; do
        [[ -e $old ]] && log_warning "$old is now ignored (config lives in $ZDOT_TARGET)"
    done
    log_success "zsh config restored; antidote builds the plugin bundle on the first new shell"
}

restore_configs() {
    (( ${#VSCODE_TODO} )) || return 0
    log_header "App configs"

    if (( ${VSCODE_TODO[(Ie)vscode]} )); then
        log_info "Restoring VS Code settings..."
        run mkdir -p "$VSCODE_USER"
        backup_file "$VSCODE_USER/settings.json"
        backup_file "$VSCODE_USER/keybindings.json"
        track "VS Code settings" cp "$VSCODE_CONFIG/settings.json" "$VSCODE_CONFIG/keybindings.json" "$VSCODE_USER/"

        local code_cli="code" ext failed=0
        if ! command_exists code; then
            code_cli="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        fi
        if [[ $code_cli == code || -x $code_cli ]] || (( DRY_RUN )); then
            log_info "Installing VS Code extensions..."
            for ext in ${(f)"$(grep -v '^[[:space:]]*$' "$VSCODE_CONFIG/extensions.txt")"}; do
                run "$code_cli" --install-extension "$ext" || { FAILED+=("vscode: $ext"); failed=1; }
            done
            (( failed )) || INSTALLED+=("VS Code extensions")
        else
            FAILED+=("VS Code extensions (code CLI not found)")
        fi
    fi

    if (( ${VSCODE_TODO[(Ie)iterm2]} )); then
        log_info "Pointing iTerm2 at $REPO_DIR/iterm2-config..."
        track "iTerm2 preferences" defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$REPO_DIR/iterm2-config"
        run defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
        MANUAL+=("Restart iTerm2 to load its preferences from iterm2-config/")
    fi
}

install_toolchains() {
    (( ${#TOOLCHAINS} )) || return 0
    log_header "Dev toolchains"

    if (( ${TOOLCHAINS[(Ie)node]} )); then
        log_info "Installing Node via nvm..."
        track "Node 20 + 24 (nvm)" zsh -c '
            export NVM_DIR="$HOME/.nvm"
            mkdir -p "$NVM_DIR"
            source "$(brew --prefix nvm)/nvm.sh"
            nvm install 24 && nvm install 20 && nvm alias default 20 &&
                npm install -g pnpm@10 serverless@3'
    fi

    if (( ${TOOLCHAINS[(Ie)rust]} )); then
        if [[ -x "$HOME/.cargo/bin/rustup" ]]; then
            log_info "rustup already installed"
        else
            log_info "Installing Rust via rustup..."
            # --no-modify-path: the restored .zshenv already sources ~/.cargo/env
            track "rustup" /bin/bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path"
        fi
        track "cargo-deny + cargo-nextest" "$HOME/.cargo/bin/cargo" install --locked cargo-deny cargo-nextest
    fi

    if (( ${TOOLCHAINS[(Ie)java]} )); then
        if /usr/libexec/java_home -v 25 &>/dev/null; then
            log_info "JDK 25 already installed"
        else
            MANUAL+=("Install Oracle JDK 25: https://www.oracle.com/java/technologies/downloads/")
            (( ALL || DRY_RUN )) || open "https://www.oracle.com/java/technologies/downloads/"
        fi
    fi
}

install_mail_reminder() {
    log_header "Mail reminder"
    track "Flagged-mail reminders agent" "$REPO_DIR/mail-reminder/install.sh" "$REPO_DIR/mail-reminder/flagged_mail_reminders.scpt"
}

print_summary() {
    local i item
    for (( i = 1; i <= ${#M_ID}; i++ )); do
        [[ $M_TYPE[i] == manual ]] && MANUAL+=("$M_ID[i]: $M_DESC[i]")
    done

    log_header "Summary"
    if (( DRY_RUN )); then
        log_warning "Dry run: nothing was changed"
    fi
    if (( DRY_RUN )); then
        log_success "Would run: ${#INSTALLED}"
    else
        log_success "Done: ${#INSTALLED}"
    fi
    for item in "${INSTALLED[@]}"; do echo "    $item"; done
    if (( ${#FAILED} )); then
        log_error "Failed: ${#FAILED} (re-run the script to retry)"
        for item in "${FAILED[@]}"; do echo "    $item"; done
    fi
    echo
    log_info "Manual follow-ups:"
    for item in "${MANUAL[@]}"; do echo "    - $item"; done
    echo "    - LaunchAgents other than the mail reminder are not managed by this script"
    step_on shell && echo "    - Open a new terminal or run: exec zsh"
    echo
}

# ------------------------------------------------------------------
# --snapshot: refresh the repo from this Mac
# ------------------------------------------------------------------

snapshot() {
    log_header "Snapshot of this Mac into the repo"

    log_info "Copying zsh config from $ZDOT_TARGET..."
    local f
    run mkdir -p "$DOTFILES/zsh/conf.d"
    for f in "${ZSH_FILES[@]}"; do
        [[ -f "$ZDOT_TARGET/$f" ]] && run cp "$ZDOT_TARGET/$f" "$DOTFILES/zsh/$f"
    done
    local -a stale=("$DOTFILES"/zsh/conf.d/*.zsh(N)) fresh=("$ZDOT_TARGET"/conf.d/*.zsh(N))
    (( ${#stale} )) && run rm -f "${stale[@]}"
    (( ${#fresh} )) && run cp "${fresh[@]}" "$DOTFILES/zsh/conf.d/"
    [[ -f "$HOME/.zshenv" ]] && run cp "$HOME/.zshenv" "$DOTFILES/zshenv"
    [[ -f "$HOME/.config/starship.toml" ]] && run cp "$HOME/.config/starship.toml" "$DOTFILES/starship.toml"
    [[ -f "$HOME/.gitignore" ]] && run cp "$HOME/.gitignore" "$DOTFILES/gitignore"

    if command_exists code; then
        log_info "Saving VS Code extension list..."
        if (( DRY_RUN )); then
            echo "  ${YELLOW}[dry-run]${NC} code --list-extensions > $VSCODE_CONFIG/extensions.txt"
        else
            code --list-extensions > "$VSCODE_CONFIG/extensions.txt"
        fi
    fi

    if grep -rnIiE '(token|api[_-]?key|secret|password)[[:space:]]*=' "$DOTFILES" 2>/dev/null; then
        log_warning "The lines above look like secrets; move them to .zsh_secrets before committing"
    fi

    log_info "Looking for packages missing from packages.conf..."
    detect_installed
    local -A known
    local i key id
    for (( i = 1; i <= ${#M_ID}; i++ )); do
        known[$M_TYPE[i]:$M_ID[i]]=1
    done

    local -a new_lines
    for id in ${(f)"$(brew leaves 2>/dev/null)"}; do
        (( ${SELF_TOOLS[(Ie)$id]} )) && continue
        (( ${+known[formula:$id]} )) || new_lines+=("Uncategorized    | formula | $id | $id | on")
    done
    for id in ${(f)"$(brew list --cask -1 2>/dev/null)"}; do
        (( ${+known[cask:$id]} )) || new_lines+=("Uncategorized    | cask    | $id | $id | on")
    done
    for id in ${(k)MAS_NAMES}; do
        (( ${+known[mas:$id]} )) || new_lines+=("Uncategorized    | mas     | $id | ${MAS_NAMES[$id]//,/} | on")
    done

    if (( ${#new_lines} )); then
        log_warning "Adding ${#new_lines} new package(s) to packages.conf under 'Uncategorized':"
        printf '    %s\n' "${new_lines[@]}"
        if (( ! DRY_RUN )); then
            {
                echo
                echo "# --- Uncategorized (added by --snapshot on $(date +%Y-%m-%d); move into a category) ---"
                printf '%s\n' "${new_lines[@]}"
            } >> "$MANIFEST"
        fi
    else
        log_success "packages.conf already lists everything installed here"
    fi

    local -a missing
    for (( i = 1; i <= ${#M_ID}; i++ )); do
        [[ $M_TYPE[i] == manual ]] && continue
        is_installed "$M_TYPE[i]" "$M_ID[i]" || missing+=("$M_ID[i]")
    done
    (( ${#missing} )) && log_info "In packages.conf but not installed here: ${(j:, :)missing}"

    echo
    log_success "Snapshot complete. Review with: git -C \"$REPO_DIR\" diff"
}

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

main() {
    log_header "macOS Development Environment Setup"
    (( DRY_RUN )) && log_warning "Dry run: commands are printed, nothing is changed"

    load_manifest
    if [[ $MODE == snapshot ]]; then
        snapshot
        return
    fi

    check_prerequisites
    install_homebrew
    install_gum
    ask_everything

    step_on git        && configure_git
    install_packages
    step_on fonts      && install_repo_fonts
    step_on shell      && restore_shell
    step_on configs    && restore_configs
    step_on toolchains && install_toolchains
    step_on mail       && install_mail_reminder

    print_summary
}

main
