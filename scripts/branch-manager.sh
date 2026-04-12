#!/usr/bin/env bash
# fzf branch manager with vim-modal navigation. Runs inside tmux display-popup.
#
# Nav mode (default): j/k navigate, l/Enter open, h/q exit, / or i to search
# Search mode: type to filter, Esc back to nav, Enter select
# ctrl-n: create new branch from search query   ctrl-x: delete selected branch

set -u

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

list_branches() {
    git -C "$repo_root" for-each-ref \
        --format='%(refname:short)|%(objectname:short)|%(committerdate:relative)' \
        refs/heads/ --sort=-committerdate \
    | while IFS='|' read -r br sha when; do
        wt=$(worktree_for_branch "$br")
        if [ -n "$wt" ]; then
            printf '%-30s  %s  %s  [%s]\n' "$br" "$sha" "$when" "$wt"
        else
            printf '%-30s  %s  %s\n' "$br" "$sha" "$when"
        fi
    done
}

while :; do
    out=$(list_branches | fzf \
        --layout=reverse \
        --print-query \
        --expect=ctrl-x,ctrl-n,ctrl-s \
        --disabled \
        --bind 'j:down,k:up,l:accept,h:abort,q:abort' \
        --bind '/:enable-search,i:enable-search' \
        --bind 'esc:disable-search' \
        --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up' \
        --color="$TN_COLORS" \
        --prompt='> ' \
        --header='j/k:nav  l/enter:claude  ctrl-s:shell  /,i:search  ctrl-n:new  ctrl-x:del' \
        || true)

    [ -z "$out" ] && exit 0

    query=$(printf '%s\n' "$out" | sed -n '1p')
    key=$(printf '%s\n' "$out" | sed -n '2p')
    line=$(printf '%s\n' "$out" | sed -n '3p')
    branch=$(printf '%s' "$line" | awk '{print $1}')

    case "$key" in
        "")
            [ -z "$branch" ] && continue
            exec "$SCRIPT_DIR/claude-worktree.sh" "$branch"
            ;;
        ctrl-s)
            [ -z "$branch" ] && continue
            exec "$SCRIPT_DIR/claude-worktree.sh" -S "$branch"
            ;;
        ctrl-n)
            [ -z "$query" ] && continue
            exec "$SCRIPT_DIR/claude-worktree.sh" "$query"
            ;;
        ctrl-x)
            [ -z "$branch" ] && continue
            printf "delete branch '%s' and its worktree? [y/N] " "$branch"
            read -r confirm
            [ "$confirm" = "y" ] || continue
            wt=$(worktree_for_branch "$branch")
            if [ -n "$wt" ]; then
                git -C "$repo_root" worktree remove --force "$wt" 2>&1 || true
            fi
            git -C "$repo_root" branch -D "$branch" 2>&1 || true
            printf "\n(press any key to continue)\n"
            read -rn 1
            ;;
    esac
done
