if [ "$XDG_SESSION_TYPE" = "x11" ]; then
  alias c='xclip -sel clip'
  alias v='xclip -o -selection clipboard'
  alias p='xclip -o -selection clipboard'
else
  alias c='wl-copy'
  alias v='wl-paste'
  alias p='wl-paste'
fi

# Alias for updating rust
alias rupdate='rustup update && cargo clean && cargo update && cargo fmt && cargo clippy --tests --all-features'
# Alias for pnpm
alias pn='pnpm'