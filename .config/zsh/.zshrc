# File: .zshrc
# Description: personal configuration file used with zsh4humans
# Author: Pavle Batuta <pavle@batuta.xyz>

zstyle ':z4h:' auto-update no
zstyle ':z4h:' start-tmux no
zstyle ':z4h' term-shell-integration yes

zstyle ':z4h:' propagate-cwd yes

zstyle ':z4h:*' channel stable

zstyle ':z4h:autosuggestions' accept

zstyle ':z4h:fzf-complete' fzf-command my-fzf
zstyle ':z4h:(fzf-complete|fzf-dir-history|fzf-history)' fzf-flags --no-exact --color=hl:14,hl+:14
zstyle ':z4h:(fzf-complete|fzf-dir-history)' fzf-bindings 'tab:repeat'
zstyle ':z4h:fzf-complete' find-flags -name '.git' -prune -print -o -print

zstyle ':z4h:ssh:*' enable no
zstyle ':z4h:ssh:*' ssh-command kitty command ssh
zstyle ':z4h:ssh:*' term 'xterm-256-color'
zstyle ':z4h:ssh:*' send-extra-files '~/.zsh-aliases'

zstyle ':zle:(up|down)-line-or-beginning-search' leave-cursor yes

zstyle ':z4h:term-title:ssh' preexec '%* | %n@%m: ${1//\%/%%}'
zstyle ':z4h:term-title:local' preexec '%* | ${1//\%/%%}'

zstyle ':z4h:direnv' enable yes

zstyle ':completion:*:ssh:argument-1:' tag-order hosts users
zstyle ':completion:*:scp:argument-rest:' tag-order hosts files users
zstyle ':completion:*:(ssh|scp|rdp):*:hosts' hosts

if ! (( P9K_SSH )); then
    zstyle ':z4h:sudo' term ''
fi

###

z4h install romkatv/archive || return
# Uncomment this if there are bugs when using tmux (see: https://github.com/romkatv/zsh4humans/issues/135)
#z4h tty-wait --timeout-seconds 1.0 --lines-columns-pattern '<70-> <->'
z4h init || return

###

zstyle ':completion:*' matcher-list "m:{a-z}={A-Z}" "l:|=* r:|=*"

###

fpath+=("$Z4H"/romkatv/archive)
autoload -Uz archive lsarchive unarchive edit-command-line

zle -N edit-command-line

my-fzf () {
    emulate -L zsh -o extended_glob
    local MATCH MBEGIN MEND
    fzf "${@:/(#m)--query=?*/$MATCH }"
}

my-ctrl-z() {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER="fg"
        zle accept-line -w
    else
        zle push-input -w
        zle clear-screen -w
    fi
}
zle -N my-ctrl-z

###

z4h bindkey z4h-backward-kill-word  Ctrl+Backspace
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace
z4h bindkey z4h-kill-zword          Ctrl+Alt+Delete

z4h bindkey backward-kill-line      Ctrl+U
z4h bindkey kill-line               Alt+U
z4h bindkey kill-whole-line         Alt+I

z4h bindkey z4h-forward-zword       Ctrl+Alt+Right
z4h bindkey z4h-backward-zword      Ctrl+Alt+Left

z4h bindkey z4h-cd-back             Alt+H
z4h bindkey z4h-cd-forward          Alt+L
z4h bindkey z4h-cd-up               Alt+K
z4h bindkey z4h-fzf-dir-history     Alt+J

z4h bindkey my-ctrl-z               Ctrl+Z
z4h bindkey edit-command-line       Alt+E

z4h bindkey z4h-exit                Ctrl+D

###

setopt GLOB_DOTS
setopt IGNORE_EOF

###

[ -z "$EDITOR" ] && export EDITOR='nvim'
[ -z "$VISUAL" ] && export VISUAL='nvim'

export DIRENV_LOG_FORMAT=
export FZF_DEFAULT_OPTS="--reverse --multi"
export SYSTEMD_LESS="${LESS}S"

###

export NVM_DIR="$HOME/.config/nvm"

###

z4h source -- /usr/share/LS_COLORS/dircolors.sh
z4h source -- "$ZDOTDIR"/.zsh-aliases
