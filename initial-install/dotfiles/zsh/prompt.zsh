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
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _prompt_dir
    eval "$(starship init zsh)"
    ;;
esac

# Path for starship, in parts it styles separately ([env_var.PROMPT_DIR_*] in starship.toml):
# parent folders cut to one letter, the repo root and the current folder kept whole.
#   ~/D/development-utilities/i/d/z/conf.d  =  PRE "~/D/"  ROOT "development-utilities"  SUB "/i/d/z/conf.d"

# REPLY = every folder in $1 cut to one letter (two for dot-folders), each followed by "/"
_prompt_dir_abbr() {
  local p
  REPLY=
  [[ $1 == /* ]] && REPLY=/
  for p in ${(s:/:)1}; do
    [[ $p == .* ]] && REPLY+=${p[1,2]}/ || REPLY+=${p[1]}/
  done
}

_prompt_dir() {
  local root=$PWD pre= name= sub= here=$PWD
  while [[ $root != / && ! -e $root/.git ]]; do root=${root:h}; done
  [[ -e $root/.git ]] || root=

  if [[ -n $root ]]; then
    local parent=${root:h} rel=${PWD#$root}
    [[ $parent == $HOME(|/*) ]] && parent="~${parent#$HOME}"
    if [[ $root == $HOME ]]; then
      name="~"
    else
      _prompt_dir_abbr $parent; pre=$REPLY name=${root:t}
    fi
    if [[ -n $rel ]]; then
      _prompt_dir_abbr ${rel:h}; sub=$REPLY${rel:t}
    fi
  else
    [[ $here == $HOME(|/*) ]] && here="~${here#$HOME}"
    if [[ $here == (\~|/) ]]; then
      sub=$here
    else
      _prompt_dir_abbr ${here:h}; sub=$REPLY${here:t}
    fi
  fi

  export PROMPT_DIR_PRE=$pre PROMPT_DIR_ROOT=$name PROMPT_DIR_SUB=$sub PROMPT_DIR_RO=
  [[ -w $PWD ]] || PROMPT_DIR_RO=$' \U000f033e'
}
