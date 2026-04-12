#!/usr/bin/env bash
# Capture tokyo-night theme formats and create blue-tinted variants
# for pane group windows. Called after tpm loads.

fmt=$(tmux show -gv window-status-format)
cur=$(tmux show -gv window-status-current-format)

# Store originals
tmux set -g @_ws "$fmt"
tmux set -g @_wsc "$cur"

# Create group variants — shift bg toward blue
tmux set -g @_wsg "$(echo "$fmt" | sed 's/#1A1B26/#1a2240/g')"
tmux set -g @_wscg "$(echo "$cur" | sed 's/#1A1B26/#1e2d4d/g;s/#2A2F41/#253551/g')"

# Conditional format: managed windows get blue bg, others get theme default
tmux set -g window-status-format '#{?@claude-managed,#{T:#{@_wsg}},#{T:#{@_ws}}}'
tmux set -g window-status-current-format '#{?@claude-managed,#{T:#{@_wscg}},#{T:#{@_wsc}}}'
