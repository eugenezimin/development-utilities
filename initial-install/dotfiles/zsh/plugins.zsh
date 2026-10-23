# Plugins are listed in .zsh_plugins.txt. `antidote load` rebuilds the static
# bundle (.zsh_plugins.zsh) only when the list changes, then sources it.

# Settings that plugins read at load time
zstyle ':omz:update' mode disabled        # antidote updates OMZ plugins (`antidote update`), not OMZ itself
ZSH_COLORIZE_TOOL="chroma"
ZSH_COLORIZE_CHROMA_FORMATTER="terminal16m"
ZSH_COLORIZE_STYLE="base16-snazzy"

source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
antidote load

# zsh-autocomplete runs compinit itself. Stop use-omz from running it a second
# time and hand the compdef calls it queued over to zsh-autocomplete instead.
if (( $+functions[compinit_deferred] )); then
  add-zsh-hook -d precmd ensure-compinit-during-precmd
  for _cmd in $__compcmd_queue; do eval $_cmd; done
  unset __compcmd_queue _cmd
  unfunction compinit_deferred queued_compcmd 2>/dev/null
fi
