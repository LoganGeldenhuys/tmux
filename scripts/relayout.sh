#!/usr/bin/env bash
# Re-apply claude layout for a window. If managed and <4 panes, pull one
# from the next chain window (join-pane). The window-layout-changed hook
# then fires on that next window, cascading naturally.
#
# Two safeguards prevent infinite hook loops from our own select-layout:
#  1. Per-window flock — blocks concurrent reentry.
#  2. @claude-last-layout window option — skips select-layout when the
#     desired layout name is already current. Producers (split-window,
#     join-pane) clear this option to force re-application.
#
# Usage: relayout.sh [window_id]

set -u

target="${1:-}"
[ -z "$target" ] && target=$(tmux display -p '#{window_id}')

lockfile="/tmp/tmux-relayout-$(id -u)-${target//[@%]/_}.lock"
exec 9>"$lockfile"
flock -n 9 || exit 0

if ! tmux list-windows -a -F '#{window_id}' 2>/dev/null | grep -qx "$target"; then
    exit 0
fi

managed=$(tmux show-window-options -t "$target" -v @claude-managed 2>/dev/null || true)
[ "$managed" = "1" ] || exit 0

count=$(tmux list-panes -t "$target" 2>/dev/null | wc -l)
[ "$count" -eq 0 ] && exit 0

if [ "$count" -lt 4 ]; then
    cur_idx=$(tmux display -p -t "$target" '#{window_index}')
    cur_session=$(tmux display -p -t "$target" '#{session_name}')
    next=$(tmux list-windows -t "$cur_session" \
           -F '#{window_index} #{window_id} #{@claude-managed}' 2>/dev/null \
        | awk -v idx="$cur_idx" '$3 == "1" && $1+0 > idx+0 { print $2; exit }')
    if [ -n "$next" ]; then
        first_pane=$(tmux list-panes -t "$next" -F '#{pane_id}' 2>/dev/null | head -1)
        target_pane=$(tmux list-panes -t "$target" -F '#{pane_id}' 2>/dev/null | head -1)
        if [ -n "$first_pane" ] && [ -n "$target_pane" ]; then
            if tmux join-pane -s "$first_pane" -t "$target_pane" 2>/dev/null; then
                count=$(tmux list-panes -t "$target" 2>/dev/null | wc -l)
                tmux set-window-option -t "$target" @claude-last-layout "" 2>/dev/null || true
            fi
        fi
    fi
fi

case "$count" in
    1) desired=""
       tmux set-window-option -t "$target" @claude-last-layout "" 2>/dev/null || true
       ;;
    2) desired="even-horizontal" ;;
    3) desired="main-vertical" ;;
    *) desired="tiled" ;;
esac

[ -z "$desired" ] && exit 0

last=$(tmux show-window-options -t "$target" -v @claude-last-layout 2>/dev/null || true)
if [ "$last" != "$desired" ]; then
    tmux set-window-option -t "$target" @claude-last-layout "$desired"
    tmux select-layout -t "$target" "$desired"
fi
