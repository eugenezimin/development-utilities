# Starts the prompt chosen by $ZSH_PROMPT in .zshrc.

case $ZSH_PROMPT in
  p10k)
    source "${ANTIDOTE_HOME:-$HOME/Library/Caches/antidote}/github.com/romkatv/powerlevel10k/powerlevel10k.zsh-theme"
    # To customize prompt, run `p10k configure` or edit $ZDOTDIR/.p10k.zsh.
    export POWERLEVEL9K_CONFIG_FILE="$ZDOTDIR/.p10k.zsh"
    [[ -r "$ZDOTDIR/.p10k.zsh" ]] && source "$ZDOTDIR/.p10k.zsh"
    ;;
  *)
    [[ $ZSH_PROMPT == starship ]] || print -u2 "prompt.zsh: unknown ZSH_PROMPT='$ZSH_PROMPT', using starship"
    eval "$(starship init zsh)"
    ;;
esac
