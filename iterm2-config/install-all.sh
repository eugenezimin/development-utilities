#!/bin/zsh

if [ ! -d "/Applications/iTerm.app" ]; then
  echo "iTerm2 is not installed"
  exit 1
fi

echo -n "Enter your name: " && read -p "" user_name
echo -n "Enter your email: " && read -p "" user_email

# create .git aliases
config='[alias]
         co = checkout
         br = branch
         ci = commit
         st = status
         unstage = reset HEAD --
         last = log -1 HEAD
         cim = commit -m
         ciam = commit -a -m
[core]
         excludesfile = gitignore
         editor = micro
[user]
         name = 
         email = 
[pull]
         rebase = false
[commit]
         gpgsign = false'

config="${config//name = /name = $user_name}"
config="${config//email = /email = $user_email}"
config="$(echo "$config" | sed "s^gitignore^$home/.gitignore^g")"

echo "$config" > ~/.gitconfig

# install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install git
brew install git

# install oh-my-zsh via curl
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# install Powelevel 10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
perl -i -pe's/^ZSH_THEME=.*/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/g' ~/.zshrc

# install LS Deluxe
brew install lsd

# install micro instead of nano
brew install micro

# installing chroma
brew install chroma

echo "Don't forget to add into your .zshrc file"
echo
echo 'ZSH_COLORIZE_TOOL="chroma"'
echo 'ZSH_COLORIZE_STYLE="colorful"'
echo 'ZSH_COLORIZE_CHROMA_FORMATTER="terminal16m"'
echo 'ZSH_COLORIZE_STYLE="base16-snazzy"'
echo
echo 'plugins=('
echo '	colored-man-pages'
echo '	colorize'
echo '	git'
echo '	zsh-syntax-highlighting'
echo '	jsontools'
echo '	macos'
echo ')'
echo
echo 'alias zshconfig="micro ~/.zshrc"'
echo 'alias ohmyzsh="micro ~/.oh-my-zsh"'
echo 'alias nano="micro"'
echo 'alias docker="podman"'
echo 'alias pd="podman"'
echo "alias ll='lsd -l --group-dirs=first'"
echo "alias la='lsd -l -A --group-dirs=first'"
echo 'alias cat=cat'
echo 'alias less=less'
