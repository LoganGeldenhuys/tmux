#!/usr/bin/env bash
# fzf directory picker. Runs inside tmux display-popup.
# Navigate with alt-h (up) / alt-l (into), open shell with Enter,
# open the AI agent (controlled by $AI_AGENT) with alt-a.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Tokyo Night fzf colors
TN_COLORS='fg:#c0caf5,fg+:#c0caf5,bg+:#283457,hl:#bb9af7,hl+:#ff9e64'
TN_COLORS="$TN_COLORS,info:#7dcfff,prompt:#7aa2f7,pointer:#ff9e64,marker:#9ece6a"
TN_COLORS="$TN_COLORS,spinner:#bb9af7,header:#565f89,border:#565f89"

cwd=$(tmux display -p '#{pane_current_path}')
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || root="$cwd"

list_dirs() {
    if command -v fd &>/dev/null; then
        fd -t d --max-depth 4 . "$1" 2>/dev/null
    else
        find "$1" -maxdepth 4 -type d \
            ! -path '*/.*' \
            ! -path '*/node_modules/*' \
            2>/dev/null
    fi | sort
}

while :; do
    agent="${AI_AGENT:-$(tmux show-environment -g AI_AGENT 2>/dev/null | sed 's/^AI_AGENT=//;t;d')}"
    agent="${agent:-opencode}"

    out=$(list_dirs "$root" | fzf \
        --layout=reverse \
        --print-query \
        --expect=alt-h,alt-l,alt-a \
        --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up,alt-j:down,alt-k:up' \
        --color="$TN_COLORS" \
        --prompt="${root}/ > " \
        --header="alt-h:up  alt-l:into  enter:shell  alt-a:${agent}" \
        || true)

    [ -z "$out" ] && exit 0

    key=$(printf '%s\n' "$out" | sed -n '2p')
    match=$(printf '%s\n' "$out" | sed -n '3p')

    case "$key" in
        alt-h)
            root=$(dirname "$root")
            ;;
        alt-l)
            [ -n "$match" ] && [ -d "$match" ] && root="$match"
            ;;
        alt-a)
            [ -z "$match" ] && exit 0
            exec "$SCRIPT_DIR/ai-pane.sh" -c "$match"
            ;;
        "")
            [ -z "$match" ] && exit 0
            exec "$SCRIPT_DIR/ai-pane.sh" -c "$match" -C ''
            ;;
    esac
done
