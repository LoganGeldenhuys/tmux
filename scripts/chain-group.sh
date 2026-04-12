#!/usr/bin/env bash
# Mark current window as a pane group.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cur=$(tmux display -p '#{window_id}')

managed=$(tmux show-window-options -t "$cur" -v @claude-managed 2>/dev/null || true)
if [ "$managed" = "1" ]; then
    tmux display-message "already a pane group"
    exit 0
fi

tmux set-window-option -t "$cur" @claude-managed 1
tmux set-window-option -t "$cur" @claude-last-layout ""
"$SCRIPT_DIR/relayout.sh" "$cur"
tmux display-message "started pane group"
