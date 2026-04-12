#!/usr/bin/env bash
# Pull current pane into the managed tiling chain.
# Finds the first chain window with < 4 panes and joins there.
# If no chain window has room, marks the current window as a new chain member.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cur_pane=$(tmux display -p '#{pane_id}')
cur_win=$(tmux display -p '#{window_id}')
cur_session=$(tmux display -p '#{session_name}')

# walk managed windows in order, find first with room
target=""
while IFS=' ' read -r _ win_id managed; do
    [ "$managed" = "1" ] || continue
    count=$(tmux list-panes -t "$win_id" 2>/dev/null | wc -l)
    if [ "$count" -lt 4 ]; then
        target="$win_id"
    fi
done < <(tmux list-windows -t "$cur_session" \
    -F '#{window_index} #{window_id} #{@claude-managed}' 2>/dev/null | sort -n)

if [ -z "$target" ]; then
    # no room anywhere — mark current window as new chain member
    tmux set-window-option -t "$cur_win" @claude-managed 1
    tmux set-window-option -t "$cur_win" @claude-last-layout ""
    "$SCRIPT_DIR/relayout.sh" "$cur_win"
    tmux display-message "pulled window into chain"
    exit 0
fi

# join current pane into the target chain window
target_pane=$(tmux list-panes -t "$target" -F '#{pane_id}' 2>/dev/null | tail -1)
tmux join-pane -s "$cur_pane" -t "$target_pane"
tmux set-window-option -t "$target" @claude-last-layout "" 2>/dev/null || true
"$SCRIPT_DIR/relayout.sh" "$target"
tmux select-window -t "$target"
tmux display-message "pulled pane into chain"
