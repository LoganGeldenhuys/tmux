#!/usr/bin/env bash
# fzf branch picker. Runs inside tmux display-popup.
# Type to search, Enter to select, ctrl-x to delete. If the typed name
# doesn't match an existing branch it is created automatically.
#
# Usage: branch-picker.sh [-S]
#   -S  open a shell instead of claude

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

worktree_for_branch() {
    git -C "$repo_root" worktree list --porcelain | awk -v b="$1" '
        /^worktree / { w = substr($0, 10) }
        /^branch / {
            br = substr($0, 8)
            sub(/^refs\/heads\//, "", br)
            if (br == b) { print w; exit }
        }
    '
}

while :; do
    branches=$(git -C "$repo_root" for-each-ref \
        --format='%(refname:short)' refs/heads/ --sort=-committerdate)

    out=$(printf '%s\n' "$branches" | fzf \
        --layout=reverse \
        --print-query \
        --expect=ctrl-x \
        --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up' \
        --color="$TN_COLORS" \
        --prompt='> ' \
        --header='enter:select  ctrl-x:del' \
        || true)

    [ -z "$out" ] && exit 0

    query=$(printf '%s\n' "$out" | sed -n '1p')
    key=$(printf '%s\n' "$out" | sed -n '2p')
    match=$(printf '%s\n' "$out" | sed -n '3p')

    case "$key" in
        ctrl-x)
            [ -z "$match" ] && continue
            printf "delete branch '%s' and its worktree? [y/N] " "$match"
            read -r confirm
            [ "$confirm" = "y" ] || continue
            wt=$(worktree_for_branch "$match")
            if [ -n "$wt" ]; then
                git -C "$repo_root" worktree remove --force "$wt" 2>&1 || true
            fi
            git -C "$repo_root" branch -D "$match" 2>&1 || true
            ;;
        "")
            branch="${match:-$query}"
            [ -z "$branch" ] && exit 0
            if [ -n "$shell_mode" ]; then
                exec "$SCRIPT_DIR/claude-worktree.sh" -S "$branch"
            else
                exec "$SCRIPT_DIR/claude-worktree.sh" "$branch"
            fi
            ;;
    esac
done
