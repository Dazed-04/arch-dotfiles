#############################
### Environment Variables ###
#############################

export FONTCONFIG_PATH=/etc/fonts
export PATH="$HOME/.local/bin:$PATH"
export QT_QPA_PLATFORMTHEME=qt6ct
export PGHOST=~/Applications/PostgreSQL_db/
export EDITOR="nvim"
export VISUAL="nvim"
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json

#####################
### Shell Options ###
#####################

### History related options ###
HISTFILE=~/.histfile
HISTSIZE=5000
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

### zsh behaviour ###

setopt extendedglob notify
unsetopt autocd beep nomatch

### Keybinds ###
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey ' ' magic-space
bindkey '^[-' undo
bindkey '^[]' redo
bindkey -s '^Xgc' 'git commit -m ""\C-b'

# Expand aliases inline before executing 
globalias() {
  zle _expand_alias
  zle expand-word
  zle self-insert 
}
zle -N globalias
bindkey '^[ ' globalias

# Ctrl+Z to toggle a background job back to forward 
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

# Inline command docs 
autoload -Uz run-help
autoload -Uz run-help-git run-help-ip run-help-sudo
bindkey '^[h' run-help

# Autopush - free directory stack navigation
# Use [ cd -n to move back n dirs ], or [ bd (popd) similar to cd .. ]
setopt autopushd pushdignoredups pushdsilent
alias bd='popd'
alias dirs='dirs -v'

# Smarter history expansion on enter instead of executing directly 
# setopt hist_verify

##################################
### Open buffer line in editor ###
##################################

# Load edit command line buffer 
autoload -Uz edit-command-line

kitty-edit-command-line() {
  # Create a temp file 
  local tmpfile=$(mktemp /tmp/zsh-edit-XXXXXX.sh)
 
  # Write the current buffer to file 
  print -rn -- "$BUFFER" > "$tmpfile"
  
  # Use sentinel file to detect nvim exit 
  local donefile=$(mktemp /tmp/zsh-edit-done-XXXXXX)
  rm -f "$donefile"
  
  # Save cursor position
  echoti sc 

  # Launch kitty window for nvim 
  kitty @ launch --type=window \
        --location=hsplit \
        --bias=40 \
        --window-title "Zsh Editor" \
        sh -c "nvim '$tmpfile'; touch '$donefile'"

  # Update zsh buffer after nvim closes 
  while [ ! -f "$donefile" ]; do 
    sleep 0.1
  done 
  rm -f "$donefile"
  
  # Restore cursor position
  echoti rc

  if [[ -f "$tmpfile" ]]; then 
    BUFFER=$(<$tmpfile)
    CURSOR=$#BUFFER
    rm -f "$tmpfile"
  fi 
  # Force redraw of prompt 
  zle reset-prompt 
  zle redisplay
}

zle -N kitty-edit-command-line
bindkey '^xe' kitty-edit-command-line

### chpwd hook ###
# Executes when changing dir #
# chpwd () {
#   lsd
# }

# chpwd hook for python 
chpwd () {
  if [[ -d .venv ]]; then
    source .venv/bin/activate
  elif [[ -d venv ]]; then 
    source venv/bin/activate
  elif [[ -n "$VIRTUAL_ENV" && ! -d .venv && ! -d venv ]]; then 
    deactivate
  fi
}

####################################
### Zinit Plugin Manager Options ###
####################################

### Directory for Zinit (plugin manager) and plugins ###
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

### Download Zinit if its not present ###

### make Zinit Directory ###
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
fi

### get Zinit from its git repo ###
if [ ! -d "$ZINIT_HOME/.git" ]; then
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

### Load/Source Zinit ###
source "${ZINIT_HOME}/zinit.zsh"


####################
### Load Plugins ###
####################

### Snippets ###
zinit snippet OMZP::command-not-found

### Zinit Plugins ###
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab


########################
### Completion Setup ###
########################

### Load Completions ###
autoload -Uz compinit && compinit

### Completion styling ###
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd -A --icon always $realpath' 


##########################
### Shell Integrations ###
##########################

eval "$(fzf --zsh)" # Using Ctrl+r #
zinit cdreplay -q

###########################
### zoxide Integrations ###
###########################

export _ZO_ECHO=1
export _ZO_EXCLUDE_DIRS=$HOME:$HOME/Projects/cllmm/*
eval "$(zoxide init --cmd cd zsh)"

##########################
### Yazi shell wrapper ###
##########################
function yazi() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}


###############
### Aliases ###
###############
alias ppd-start="sudo systemctl unmask power-profiles-daemon.service && sudo systemctl stop auto-cpufreq && sudo  systemctl enable --now power-profiles-daemon.service"
alias ppd-stop="sudo systemctl disable --now power-profiles-daemon.service"
alias auto-start="sudo systemctl stop power-profiles-daemon.service && sudo systemctl enable --now auto-cpufreq"
alias auto-stop="sudo systemctl disable --now auto-cpufreq"
alias ff="fastfetch"
alias lsda="lsd -A"
# CTF container management
alias ctf-start='docker compose -f ~/Code/CTF/docker-compose.yml up -d'
alias ctf-stop='docker compose -f ~/Code/CTF/docker-compose.yml down'
alias ctf-shell='docker compose -f ~/Code/CTF/docker-compose.yml exec tools bash'
alias ctf-logs='docker compose -f ~/Code/CTF/docker-compose.yml logs -f tools'
# VPN
alias ctf-vpn='docker exec -it -u root ctf-tools openvpn --config /home/ctf/ovpn/ap-south-1-Dazed04-regular.ovpn --daemon'
alias ctf-vpn-stop='docker exec -u root ctf-tools pkill openvpn'
# SOCKS5 proxy for FoxyProxy (browser → container VPN)
alias ctf-proxy='docker exec -d ctf-tools microsocks -p 1080 && echo "SOCKS5 proxy up → set FoxyProxy to 127.0.0.1:1080"'
alias ctf-proxy-stop='docker exec ctf-tools pkill microsocks && echo "SOCKS5 proxy stopped"'
# Metasploit
alias ctf-msf='docker exec -it ctf-tools bash -c "sudo service postgresql start && msfconsole"'

superparu() {
  command "$HOME/.local/bin/myScripts/utilities/superPackageManagers.sh" --paru
}

superpacman() {
  command "$HOME/.local/bin/myScripts/utilities/superPackageManagers.sh" --pacman
}

gm() {
  command "$HOME/.local/bin/myScripts/media/yt-media"
}

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export GOPATH=$HOME/go
[[ -d "$GOPATH/bin" ]] && path=("$GOPATH/bin" $path)

################################
### Run Pokemon-colorscripts ###
################################
pokemon-colorscripts -r --no-title

############################
### oh-my-posh execution ###
############################
# Moved to the bottom so it loads last and prevents the "zsh>" glitch
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"

# 1. Prevent duplicate entries in PATH automatically
typeset -U path

# 2. Add your specific script folder
[[ -d "$HOME/.local/bin/myScripts/media" ]] && path=("$HOME/.local/bin/myScripts/media" $path)

# 3. Add standard bins
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)

# 4. Finalize and Alias
export PATH


