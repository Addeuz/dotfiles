#!/usr/bin/env bash

# Cobalt2 colors for Tmux

set -g mode-style "fg=#0088ff,bg=#3b5364"

set -g message-style "fg=#0088ff,bg=#3b5364"
set -g message-command-style "fg=#0088ff,bg=#3b5364"

set -g pane-border-style "fg=#3b5364"
set -g pane-active-border-style "fg=#0088ff"

set -g status "on"
set -g status-justify "left"

set -g status-style "fg=#0088ff,bg=#15232d"

set -g status-left-length "100"
set -g status-right-length "100"

set -g status-left-style NONE
set -g status-right-style NONE

set -g status-left "#[fg=#142a3a,bg=#0088ff,bold] #S #[fg=#0088ff,bg=#15232d,nobold,nounderscore,noitalics]"
set -g status-right "#[fg=#15232d,bg=#15232d,nobold,nounderscore,noitalics]#[fg=#0088ff,bg=#15232d]#{prefix_highlight}#{?#{||:#{client_prefix},#{pane_in_mode}},#[fg=#0088ff]#[bg=#a5ff90],#[fg=#0088ff]#[bg=#15232d]}#[fg=#142a3a,bg=#0088ff,bold] %Y-%m-%d  %H:%M "

setw -g window-status-activity-style "underscore,fg=#e1efff,bg=#15232d"
setw -g window-status-separator ""
setw -g window-status-style "NONE,fg=#e1efff,bg=#15232d"
setw -g window-status-format "#[fg=#15232d,bg=#15232d,nobold,nounderscore,noitalics]#[default] #I  #W #{?window_last_flag,󰌑,#{?window_zoomed_flag,Z,#{?window_bell_flag,!,}}} #[fg=#15232d,bg=#15232d,nobold,nounderscore,noitalics]"
setw -g window-status-current-format "#[fg=#15232d,bg=#3b5364,nobold,nounderscore,noitalics]#[fg=#0088ff,bg=#3b5364,bold] #I  #W #{?window_last_flag,󰌑,#{?window_zoomed_flag,Z,#{?window_bell_flag,!,}}} #[fg=#3b5364,bg=#15232d,nobold,nounderscore,noitalics]"

# tmux-plugins/tmux-prefix-highlight support
set -g @prefix_highlight_fg '#142a3a'
set -g @prefix_highlight_bg '#a5ff90'
set -g @prefix_highlight_output_prefix "#[fg=#a5ff90]#[bg=#15232d]#[fg=#142a3a]#[bg=#a5ff90]"
set -g @prefix_highlight_output_suffix ""
