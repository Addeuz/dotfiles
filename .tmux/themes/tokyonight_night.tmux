#!/usr/bin/env bash

# TokyoNight colors for Tmux

set -g mode-style "fg=#7aa2f7,bg=#3b4261"

set -g message-style "fg=#7aa2f7,bg=#3b4261"
set -g message-command-style "fg=#7aa2f7,bg=#3b4261"

set -g pane-border-style "fg=#3b4261"
set -g pane-active-border-style "fg=#7aa2f7"

set -g status "on"
set -g status-justify "left"

set -g status-style "fg=#7aa2f7,bg=#16161e"

set -g status-left-length "100"
set -g status-right-length "100"

set -g status-left-style NONE
set -g status-right-style NONE

set -g status-left "#[fg=#15161e,bg=#7aa2f7,bold] #S #[fg=#7aa2f7,bg=#16161e,nobold,nounderscore,noitalics]"
set -g status-right "#[fg=#16161e,bg=#16161e,nobold,nounderscore,noitalics]#[fg=#7aa2f7,bg=#16161e]#{prefix_highlight}#{?#{||:#{client_prefix},#{pane_in_mode}},#[fg=#7aa2f7]#[bg=#9ece6a],#[fg=#7aa2f7]#[bg=#16161e]}#[fg=#15161e,bg=#7aa2f7,bold] %Y-%m-%d  %H:%M "

setw -g window-status-activity-style "underscore,fg=#a9b1d6,bg=#16161e"
setw -g window-status-separator ""
setw -g window-status-style "NONE,fg=#a9b1d6,bg=#16161e"
setw -g window-status-format "#[fg=#16161e,bg=#16161e,nobold,nounderscore,noitalics]#[default] #I  #W #{?window_last_flag,󰌑,#{?window_zoomed_flag,Z,#{?window_bell_flag,!,}}} #[fg=#16161e,bg=#16161e,nobold,nounderscore,noitalics]"
setw -g window-status-current-format "#[fg=#16161e,bg=#3b4261,nobold,nounderscore,noitalics]#[fg=#7aa2f7,bg=#3b4261,bold] #I  #W #{?window_last_flag,󰌑,#{?window_zoomed_flag,Z,#{?window_bell_flag,!,}}} #[fg=#3b4261,bg=#16161e,nobold,nounderscore,noitalics]"

# tmux-plugins/tmux-prefix-highlight support
set -g @prefix_highlight_fg '#15161e'
set -g @prefix_highlight_bg '#9ece6a'
set -g @prefix_highlight_output_prefix "#[fg=#9ece6a]#[bg=#16161e]#[fg=#15161e]#[bg=#9ece6a]"
set -g @prefix_highlight_output_suffix ""
