# History configuration (merged from bash settings)
export HISTSIZE=1000
export SAVEHIST=2000
setopt HIST_IGNORE_SPACE        # ignore commands starting with space
setopt APPEND_HISTORY           # equivalent to bash histappend
setopt EXTENDED_GLOB            # equivalent to bash globstar

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set variable identifying the chroot you work in
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Enable color support of ls and add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Common ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(fc -ln -1 | sed -e '\''s/^\s*//;s/[;&|]\s*alert$//'\'')"'

# Source all custom functions
if [[ -d "$HOME/.bash_functions" ]]; then
  for file in "$HOME/.bash_functions"/*; do
    [[ -f "$file" ]] && source "$file"
  done
fi

# Alias definitions
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Git setup
export GITLAB_USER=andreas.johansson1
export GIT_NAME="Andreas Johansson"
export GIT_EMAIL="andreas.johansson@diffinder.se"

# Make common PATH variables idempotent
[[ -z "$PATH_ORIGINAL" ]] && export PATH_ORIGINAL=$PATH
[[ -z "$LD_ORIGINAL" ]] && export LD_ORIGINAL=$LD_LIBRARY_PATH
export PATH=$HOME/bin:/opt:$PATH_ORIGINAL
export LD_LIBRARY_PATH=$LD_ORIGINAL

# BEGIN ANSIBLE MANAGED BLOCK
export COMPUTE_REGION=europe-north1
export COMPUTE_ZONE=europe-north1-b
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
# END ANSIBLE MANAGED BLOCK

# pnpm
export PNPM_HOME="/home/andreas/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Cargo (Rust)
. "$HOME/.cargo/env"

# Additional PATH exports
export PATH=$PATH:/opt/gurobi/bin/
export PATH="$PATH:/home/andreas/.nsccli/bin"
