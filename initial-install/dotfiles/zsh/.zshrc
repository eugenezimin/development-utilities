# Interactive shell entry point. Real config lives in the files sourced below.

# Prompt engine: starship | p10k  (override per session: ZSH_PROMPT=p10k zsh)
: ${ZSH_PROMPT:=starship}
#: ${ZSH_PROMPT:=p10k}

# p10k instant prompt: must stay at the top; nothing that needs input may run above it.
if [[ $ZSH_PROMPT == p10k && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Secrets (API keys etc.) live in .zsh_secrets (chmod 600, not in version control)
[[ -r "$ZDOTDIR/.zsh_secrets" ]] && source "$ZDOTDIR/.zsh_secrets"

source "$ZDOTDIR/plugins.zsh"

# Personal config, loaded after plugins so it can override their defaults
for _conf in "$ZDOTDIR"/conf.d/*.zsh(N); do
  source "$_conf"
done
unset _conf

source "$ZDOTDIR/prompt.zsh"
