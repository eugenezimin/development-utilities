### Make iTerm nice

This repository contains configuration file for iTerm2 to create the view like on the screenshot below.
![iTerm 2 view](iterm2-view.png)
There are some pre-requisites should be satisfied first:
- install [iTerm 2](https://iterm2.com/downloads.html)
- install [Oh-My-Zsh](https://ohmyz.sh/#install)
- install [Google Mono Sans Nerd Font](https://github.com/eugenezimin/google-mono-sans-nerd) or any other [nerd font](https://www.nerdfonts.com/font-downloads) you like
- install [Powerlevel10k](https://github.com/romkatv/powerlevel10k) and use it as the main theme in your `.zshrc` file
- install [LS Deluxe](https://github.com/lsd-rs/lsd)

Optional tools:
- install [micro](https://micro-editor.github.io/) instead of `nano` or `vim`
- install [podman] instead of `docker`

Add some changes into your configurational file `.zshrc`:
```shell
# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    colored-man-pages
    colorize
    git
    zsh-syntax-highlighting
    jsontools
    macos
)
```

in case you would like to colorize the `cat` output, you can add following configuration (but read about additional dependencies, like [`chroma`](https://github.com/alecthomas/chroma)):
```shell
ZSH_COLORIZE_TOOL="chroma"
ZSH_COLORIZE_STYLE="colorful"
ZSH_COLORIZE_CHROMA_FORMATTER="terminal16m"
ZSH_COLORIZE_STYLE="base16-snazzy"
```

and finally add some aliases:
```shell
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

or you may try to use `install-all.sh` script on your own risk.

### Read configuration into iTerm

Simply do like it is shown on the picture:
![Restore Configuration](iterm2-config.png)

There is also another way to keep it updated in case you would like to use Git or another remote repository to store your configs.
```shell
# Specify the preferences directory
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "~/Desktop/iTerm/settings"

# Tell iTerm2 to use the custom preferences in the directory
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
```
