#!/usr/bin/env bash
# Add a new AI pane. Starts from the current window, walks the managed
# chain, and overflows into a new adjacent window at >4 panes.
# Dispatches on $AI_AGENT (default: opencode). Override via env or -C.
# Usage: ai-pane.sh [-c dir] [-C cmd]

set -u

# Resolve agent: env first, then tmux global env, then default.
agent="${AI_AGENT:-$(tmux show-environment -g AI_AGENT 2>/dev/null | sed 's/^AI_AGENT=//;t;d')}"
agent="${agent:-opencode}"

# Wrap in `bash -lc` so the new pane sources .bashrc (via .profile) and
# inherits a fresh PATH. tmux's server env can otherwise be stale relative
# to the user's shell if bashrc was edited after tmux started.
case "$agent" in
    opencode) default_cmd='bash -lc opencode' ;;
    claude)   default_cmd="bash -lc 'claude /model\\ opus'" ;;
    *)        default_cmd="bash -lc $(printf %q "$agent")" ;;
esac

dir=""
cmd="$default_cmd"

while getopts "c:C:" opt; do
    case "$opt" in
        c) dir="$OPTARG" ;;
        C) cmd="$OPTARG" ;;
        *) exit 2 ;;
    esac
done

[ -z "$dir" ] && dir=$(tmux display -p '#{pane_current_path}')

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

is_managed() {
    local m
    m=$(tmux show-window-options -t "$1" -v @claude-managed 2>/dev/null || true)
    [ "$m" = "1" ]
}

pane_count() {
    tmux list-panes -t "$1" 2>/dev/null | wc -l
}

next_managed_window() {
    local cur_idx cur_session
    cur_idx=$(tmux display -p -t "$1" '#{window_index}')
    cur_session=$(tmux display -p -t "$1" '#{session_name}')
    tmux list-windows -t "$cur_session" -F '#{window_index} #{window_id} #{@claude-managed}' 2>/dev/null \
        | awk -v idx="$cur_idx" '$3 == "1" && $1+0 > idx+0 { print $2; exit }'
}

cur=$(tmux display -p '#{window_id}')

split_pane() {
    if [ -n "$cmd" ]; then
        tmux split-window -t "$1" -h -c "$dir" "$cmd"
    else
        tmux split-window -t "$1" -h -c "$dir"
    fi
}

create_window() {
    if [ -n "$cmd" ]; then
        tmux new-window -a -t "$1" -c "$dir" "$cmd"
    else
        tmux new-window -a -t "$1" -c "$dir"
    fi
}

if ! is_managed "$cur"; then
    tmux set-window-option -t "$cur" @claude-managed 1
    tmux set-window-option -t "$cur" @claude-last-layout ""
    split_pane "$cur"
    "$SCRIPT_DIR/relayout.sh" "$cur"
    exit 0
fi

target="$cur"
while :; do
    count=$(pane_count "$target")
    if [ "$count" -lt 4 ]; then
        break
    fi
    next=$(next_managed_window "$target")
    if [ -z "$next" ]; then
        create_window "$target"
        new_win=$(tmux display -p '#{window_id}')
        tmux set-window-option -t "$new_win" @claude-managed 1
        exit 0
    fi
    target="$next"
done

tmux set-window-option -t "$target" @claude-last-layout ""
split_pane "$target"
"$SCRIPT_DIR/relayout.sh" "$target"
if [ "$target" != "$cur" ]; then
    tmux select-window -t "$target"
fi
