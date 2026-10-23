# Sourced by every zsh (login, interactive, scripts). Keep it fast and silent.
typeset -U path fpath

export EDITOR="micro"
export VISUAL="$EDITOR"

[[ -r "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
[[ -r "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
