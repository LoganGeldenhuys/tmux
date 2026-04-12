#!/usr/bin/env bash
# Move current pane left or right. Contextually swaps standalone windows,
# enters/exits pane groups, and traverses within groups.
# Usage: chain-move.sh -l|-r

set -u

direction=""
while getopts "lr" opt; do
    case "$opt" in
        l) direction="left" ;;
        r) direction="right" ;;
        *) exit 2 ;;
    esac
done
[ -z "$direction" ] && exit 2

cur_pane=$(tmux display -p '#{pane_id}')
cur_win=$(tmux display -p '#{window_id}')
cur_idx=$(tmux display -p '#{window_index}')
cur_session=$(tmux display -p '#{session_name}')
cur_managed=$(tmux show-window-options -t "$cur_win" -v @claude-managed 2>/dev/null || true)

# find adjacent window in direction
if [ "$direction" = "left" ]; then
    adj=$(tmux list-windows -t "$cur_session" -F '#{window_index} #{window_id}' \
        | awk -v idx="$cur_idx" '$1+0 < idx+0 { id=$2 } END { print id }')
else
    adj=$(tmux list-windows -t "$cur_session" -F '#{window_index} #{window_id}' \
        | awk -v idx="$cur_idx" '$1+0 > idx+0 { print $2; exit }')
fi

if [ "$cur_managed" = "1" ]; then
    # --- in a group ---
    panes=$(tmux list-panes -t "$cur_win" -F '#{pane_id}')
    first_pane=$(echo "$panes" | head -1)
    last_pane=$(echo "$panes" | tail -1)

    if [ "$direction" = "left" ]; then
        if [ "$cur_pane" != "$first_pane" ]; then
            # not at first position — swap within window
            tmux swap-pane -U
        else
            # at first position — cross-window swap or exit
            adj_managed=$([ -n "$adj" ] && tmux show-window-options -t "$adj" -v @claude-managed 2>/dev/null || true)
            if [ "$adj_managed" = "1" ]; then
                target=$(tmux list-panes -t "$adj" -F '#{pane_id}' | tail -1)
                tmux swap-pane -s "$cur_pane" -t "$target"
                tmux select-pane -t "$target"
                tmux select-window -t "$adj"
            else
                tmux break-pane -b
            fi
        fi
    else
        if [ "$cur_pane" != "$last_pane" ]; then
            tmux swap-pane -D
        else
            adj_managed=$([ -n "$adj" ] && tmux show-window-options -t "$adj" -v @claude-managed 2>/dev/null || true)
            if [ "$adj_managed" = "1" ]; then
                target=$(tmux list-panes -t "$adj" -F '#{pane_id}' | head -1)
                tmux swap-pane -s "$cur_pane" -t "$target"
                tmux select-pane -t "$target"
                tmux select-window -t "$adj"
            else
                tmux break-pane
            fi
        fi
    fi
else
    # --- standalone ---
    [ -z "$adj" ] && exit 0

    adj_managed=$(tmux show-window-options -t "$adj" -v @claude-managed 2>/dev/null || true)

    if [ "$adj_managed" = "1" ]; then
        # entering a group — join at the near edge
        if [ "$direction" = "left" ]; then
            target=$(tmux list-panes -t "$adj" -F '#{pane_id}' | tail -1)
            tmux join-pane -s "$cur_pane" -t "$target"
        else
            target=$(tmux list-panes -t "$adj" -F '#{pane_id}' | head -1)
            tmux join-pane -b -s "$cur_pane" -t "$target"
        fi
    else
        # both standalone — swap windows
        tmux swap-window -s "$cur_win" -t "$adj"
        tmux select-window -t "$cur_win"
    fi
fi
