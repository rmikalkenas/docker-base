#! /bin/bash

alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'

alias sfcc='bin/console cache:clear --no-warmup && bin/console cache:warmup'
alias sfstart='symfony server:start --no-tls -d'
alias sfstop='symfony server:stop'

alias cat='pygmentize -g'
