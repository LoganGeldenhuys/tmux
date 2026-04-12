#!/usr/bin/env bash
# fzf branch picker with vim-modal navigation. Runs inside tmux display-popup.
#
# Nav mode (default): j/k navigate, l/Enter select, h/q exit, / or i to search
# Search mode: type to filter, Esc back to nav, Enter select
# New branch: search for a non-existing name, press Enter — query becomes branch name.

set -u

shell_mode=""
while getopts "S" opt; do
    case "$opt" in
        S) shell_mode=1 ;;
        *) ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Tokyo Night fzf colors
TN_COLORS='fg:#c0caf5,fg+:#c0caf5,bg+:#283457,hl:#bb9af7,hl+:#ff9e64'
TN_COLORS="$TN_COLORS,info:#7dcfff,prompt:#7aa2f7,pointer:#ff9e64,marker:#9ece6a"
TN_COLORS="$TN_COLORS,spinner:#bb9af7,header:#565f89,border:#565f89"

cwd=$(tmux display -p '#{pane_current_path}')
repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || {
    echo "not in a git repo"
    read -rn 1 -p "press any key..."
    exit 1
}

branches=$(git -C "$repo_root" for-each-ref --format='%(refname:short)' refs/heads/ --sort=-committerdate)

out=$(printf '%s\n' "$branches" | fzf \
    --layout=reverse \
    --print-query \
    --disabled \
    --bind 'j:down,k:up,l:accept,h:abort,q:abort' \
    --bind '/:enable-search,i:enable-search' \
    --bind 'esc:disable-search' \
    --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up' \
    --color="$TN_COLORS" \
    --prompt='> ' \
    --header='j/k:nav  l/enter:select  /,i:search  esc:nav  h/q:quit' \
    || true)

[ -z "$out" ] && exit 0

query=$(printf '%s\n' "$out" | sed -n '1p')
match=$(printf '%s\n' "$out" | sed -n '2p')

if [ -n "$match" ]; then
    branch="$match"
elif [ -n "$query" ]; then
    branch="$query"
else
    exit 0
fi

if [ -n "$shell_mode" ]; then
    exec "$SCRIPT_DIR/claude-worktree.sh" -S "$branch"
else
    exec "$SCRIPT_DIR/claude-worktree.sh" "$branch"
fi
