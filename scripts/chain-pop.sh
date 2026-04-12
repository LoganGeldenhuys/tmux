#!/usr/bin/env bash
# Pop current pane out of the managed tiling chain into its own window.

set -u

cur_win=$(tmux display -p '#{window_id}')
cur_session=$(tmux display -p '#{session_name}')

managed=$(tmux show-window-options -t "$cur_win" -v @claude-managed 2>/dev/null || true)
if [ "$managed" != "1" ]; then
    tmux display-message "window is not in a chain"
    exit 0
fi

# break current pane into a new window (focus follows)
tmux break-pane

# move new window to end of window list
last_idx=$(tmux list-windows -t "$cur_session" -F '#{window_index}' | sort -n | tail -1)
new_idx=$(tmux display -p '#{window_index}')
if [ "$new_idx" -lt "$last_idx" ]; then
    tmux move-window -t "$cur_session:$((last_idx + 1))"
fi

tmux display-message "popped pane from chain"
# relayout cascades automatically via window-layout-changed hook
