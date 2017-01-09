#!/usr/bin/env bash

tmux_enable_mouse () {
    tmux_version="$(tmux -V | cut -c 6-)"

    if [[ $(echo "$tmux_version >= 2.1" | bc) -eq 1 ]]; then
        tmux set -g mouse on
        tmux set -g mouse-utf on
    else
        tmux set -g mode-mouse on
    fi
}

tmux_enable_mouse
