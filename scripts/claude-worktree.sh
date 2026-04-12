#!/usr/bin/env bash
# Ensure a sibling worktree for the given branch, then open a pane there.
# Usage: claude-worktree.sh [-S] <branch>
#   -S  open a shell instead of claude

set -u

shell_mode=""
while getopts "S" opt; do
    case "$opt" in
        S) shell_mode=1 ;;
        *) ;;
    esac
done
shift $((OPTIND - 1))

branch="${1:-}"
if [ -z "$branch" ]; then
    tmux display-message "worktree: branch required"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cwd=$(tmux display -p '#{pane_current_path}')
repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || {
    tmux display-message "worktree: not in a git repo"
    exit 1
}

# If we're already inside a worktree, resolve the primary repo to hang
# new worktrees off of (so sibling paths are computed from the main checkout).
common_dir=$(git -C "$repo_root" rev-parse --git-common-dir 2>/dev/null)
if [ -n "$common_dir" ] && [ "$common_dir" != ".git" ]; then
    primary=$(cd "$repo_root" && cd "$common_dir/.." && pwd)
    [ -n "$primary" ] && repo_root="$primary"
fi

repo_name=$(basename "$repo_root")
safe_branch="${branch//\//-}"
worktree_path="$(dirname "$repo_root")/${repo_name}-${safe_branch}"

if [ ! -d "$worktree_path" ]; then
    if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
        git -C "$repo_root" worktree add "$worktree_path" "$branch" || {
            tmux display-message "worktree add failed"
            exit 1
        }
    else
        git -C "$repo_root" worktree add -b "$branch" "$worktree_path" || {
            tmux display-message "worktree add failed"
            exit 1
        }
    fi
fi

if [ -n "$shell_mode" ]; then
    exec "$SCRIPT_DIR/claude-pane.sh" -c "$worktree_path" -C ''
else
    exec "$SCRIPT_DIR/claude-pane.sh" -c "$worktree_path"
fi
