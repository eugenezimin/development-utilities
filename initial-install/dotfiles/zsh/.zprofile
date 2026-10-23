# Login shells only. Runs after /etc/zprofile (path_helper), before .zshrc.

eval "$(/opt/homebrew/bin/brew shellenv)"

# OrbStack: command-line tools and completions
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# path_helper reorders PATH, so make sure ~/.local/bin stays in front
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
