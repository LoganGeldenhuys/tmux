#!/usr/bin/env bash
# Toggle the global AI_AGENT tmux env var between opencode and claude.
# New panes opened via M-a / M-S / M-D / etc. inherit the new value.
# Existing panes keep whatever was inherited at their launch time.

set -u

cur=$(tmux show-environment -g AI_AGENT 2>/dev/null | sed 's/^AI_AGENT=//;t;d')

case "$cur" in
    claude) next="opencode" ;;
    *)      next="claude" ;;
esac

tmux set-environment -g AI_AGENT "$next"
tmux display-message "AI agent: $next"
