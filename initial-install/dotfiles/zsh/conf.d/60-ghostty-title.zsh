# Ghostty tab title: folder - git branch (if any) - process
_ghostty_title_branch=""

_ghostty_set_title() {
  local folder="${PWD:t}"
  [[ "$PWD" == "$HOME" ]] && folder="~"
  [[ "$PWD" == "/" ]] && folder="/"
  local title="$folder"
  [[ -n "$_ghostty_title_branch" ]] && title+=" - $_ghostty_title_branch"
  title+=" - $1"
  printf '\e]2;%s\a' "$title"
}

_ghostty_title_precmd() {
  _ghostty_title_branch=$(git symbolic-ref --short HEAD 2>/dev/null \
    || git rev-parse --short HEAD 2>/dev/null)
  _ghostty_set_title "zsh"
}

_ghostty_title_preexec() {
  local -a words=(${(z)1})
  local cmd="${words[1]}"
  [[ "$cmd" == (sudo|exec|time|nohup|command) && -n "${words[2]}" ]] && cmd="${words[2]}"
  _ghostty_set_title "${cmd:t}"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd  _ghostty_title_precmd
add-zsh-hook preexec _ghostty_title_preexec
