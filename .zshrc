export ZSH="/home/laradock/.oh-my-zsh"
export VISUAL=vim
export EDITOR="$VISUAL"
export SHELL=/bin/zsh
eval `dircolors /home/laradock/.dir_colors`

ZSH_THEME="robbyrussell"
plugins=(
  zsh-autosuggestions git
)

source $ZSH/oh-my-zsh.sh

source $HOME/aliases.sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="$HOME/.symfony/bin:$PATH"

SAVEHIST=10000
HISTFILE="$HOME/shared/.zsh_history"
