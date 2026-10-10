###########################
### Environment & Paths ###
###########################

# Tie array $path to $PATH and deduplicate entries automatically
typeset -U path PATH

export EDITOR="nvim"
export VISUAL="nvim"
export FONTCONFIG_PATH=/etc/fonts
export QT_QPA_PLATFORMTHEME=qt6ct
export GOPATH="$HOME/go"
export _ZO_ECHO=1
# export NVM_DIR="$HOME/.config/nvm"

# Put the newest installed node's bin dir on PATH (no nvm load needed)
# () {
#   setopt local_options numeric_glob_sort
#   local bins=($NVM_DIR/versions/node/*/bin(N-/On[1]))
#   (( $#bins )) && path=($bins[1] $path)
# }

# Prepend/append directories to PATH
path=(
  "$HOME/.local/bin/myScripts/media"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$GOPATH/bin"
  $path
)
# Prune nonexistent dirs cleanly
path=($^path(N-/))

#####################
### Shell Options ###
#####################

HISTFILE=~/.histfile
HISTSIZE=5000
SAVEHIST=$HISTSIZE

setopt appendhistory sharehistory
setopt hist_ignore_space hist_ignore_all_dups hist_save_no_dups
setopt hist_find_no_dups extendedglob notify
unsetopt autocd beep nomatch

# Autopush - directory stack
setopt autopushd pushdignoredups pushdsilent
alias bd='popd'
alias dirs='dirs -v'

### Keybinds ###
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey ' ' magic-space
bindkey '^[-' undo
bindkey '^[]' redo

# Inline command docs
autoload -Uz run-help
autoload -Uz run-help-git run-help-ip run-help-sudo
bindkey '^[h' run-help

# Expand aliases inline
globalias() {
  zle _expand_alias
  zle expand-word
  zle self-insert
}
zle -N globalias
bindkey '^[ ' globalias

# Ctrl+Z toggle
fancy-ctrl-z() {
  if [[ $#BUFFER -eq 0 ]]; then
    fg
    zle redisplay
  else
    zle push-input
    zle clear-screen
  fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

###################################
### Open Buffer in Editor Split ###
###################################

kitty-edit-command-line() {
  local tmpfile=$(mktemp /tmp/zsh-edit-XXXXXX.sh)
  print -rn -- "$BUFFER" > "$tmpfile"

  # --wait-for-child-to-exit blocks until the window closes naturally
  kitty @ launch --type=window \
        --location=hsplit \
        --bias=40 \
        --window-title "Zsh Editor" \
        --wait-for-child-to-exit \
        nvim "$tmpfile" >/dev/null

  if [[ -f "$tmpfile" ]]; then
    BUFFER=$(<"$tmpfile")
    CURSOR=$#BUFFER
    rm -f "$tmpfile"
  fi
  zle reset-prompt
  zle redisplay
}
zle -N kitty-edit-command-line
bindkey '^xe' kitty-edit-command-line

###################
### chpwd Hooks ###
###################

chpwd() {
  if [[ -d .venv ]]; then
    source .venv/bin/activate
  elif [[ -d venv ]]; then
    source venv/bin/activate
  elif [[ -n "$VIRTUAL_ENV" && ! -d .venv && ! -d venv ]]; then
    deactivate
  fi
}

############################
### Zinit Plugin Manager ###
############################

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

### Plugins ###
zinit snippet OMZP::command-not-found

zinit ice depth=1
zinit light zsh-users/zsh-completions

zinit ice depth=1
zinit light zsh-users/zsh-autosuggestions

zinit ice depth=1
zinit light Aloxaf/fzf-tab

########################
### Completion Setup ###
########################

# Use -C to bypass slow stat checks on every subshell startup
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zinit cdreplay -q

# Syntax highlighting loaded AFTER completions & fzf-tab
zinit ice depth=1
zinit light zsh-users/zsh-syntax-highlighting

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd -A --icon always $realpath'

####################
### Integrations ###
####################

eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(oh-my-posh init zsh --config "$HOME/.config/ohmyposh/zen.toml")"

# Yazi wrapper
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

###############
### Aliases ###
###############

alias ff="fastfetch"
alias gm="$HOME/.local/bin/myScripts/media/yt-media"
alias lsda="lsd -A"
alias superparu="$HOME/.local/bin/myScripts/utilities/superPackageManagers.sh --paru"
alias superpacman="$HOME/.local/bin/myScripts/utilities/superPackageManagers.sh --pacman"

# CTF Aliases
alias ctf-start='docker compose -f ~/Code/CTF/docker-compose.yml up -d'
alias ctf-stop='docker compose -f ~/Code/CTF/docker-compose.yml down'
alias ctf-shell='docker compose -f ~/Code/CTF/docker-compose.yml exec tools bash'
alias ctf-logs='docker compose -f ~/Code/CTF/docker-compose.yml logs -f tools'
alias ctf-vpn='docker exec -it -u root ctf-tools openvpn --config /home/ctf/ovpn/ap-south-1-Dazed04-regular.ovpn --daemon'
alias ctf-vpn-stop='docker exec -u root ctf-tools pkill openvpn'
alias ctf-proxy='docker exec -d ctf-tools microsocks -p 1080 && echo "SOCKS5 proxy up → set FoxyProxy to 127.0.0.1:1080"'
alias ctf-proxy-stop='docker exec ctf-tools pkill microsocks && echo "SOCKS5 proxy stopped"'
alias ctf-msf='docker exec -it ctf-tools bash -c "sudo service postgresql start && msfconsole"'

############################
### Fast Lazy-Loaded NVM ###
############################

# load_nvm() {
#   unset -f nvm node npm npx
#   [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
#   [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
# }
# nvm()  { load_nvm; nvm "$@"; }
# node() { load_nvm; node "$@"; }
# npm()  { load_nvm; npm "$@"; }
# npx()  { load_nvm; npx "$@"; }

#####################
### Visual Banner ###
#####################

pokemon-colorscripts -r --no-title
