# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and OpenCode when working with code in this repository.

## Overview

This is a personal tmux configuration repository. The main config is `tmux.conf` at the root.

## Key Settings

- **Prefix**: `C-Space` (replaces default `C-b`)
- **Window/pane indexing**: starts at 1
- **Mouse support**: enabled
- **Window switching**: `M-H` / `M-L` (Alt+Shift+H/L)

## AI agent integration

A global tmux env var, `AI_AGENT` (default `opencode`), controls which CLI
the AI-pane scripts launch. Values: `opencode` or `claude`.

- `M-a` — new AI pane in current dir (chain-aware, overflows past 4 panes).
- `M-s` — new shell pane in current dir (same tiling, no AI).
- `M-S` — fzf branch picker; `enter` opens shell, `alt-a` opens AI agent.
- `M-D` — fzf dir picker; `alt-h` up, `alt-l` into, `enter` shell, `alt-a` AI.
- `M-[` / `M-]` — move pane left/right across pane groups.
- `M-g` — mark window as a pane group.
- `prefix + !@#$` — promote current pane to slot 1/2/3/4.
- `prefix + a` — toggle `AI_AGENT` between `opencode` and `claude`.

Scripts under `scripts/`:

- `ai-pane.sh` — opens a new pane running the current AI agent.
- `ai-worktree.sh` — creates/uses a sibling git worktree, then hands off to `ai-pane.sh`.
- `ai-toggle.sh` — flips `AI_AGENT` and notifies via `tmux display-message`.
- `branch-picker.sh`, `dir-picker.sh` — fzf popups that feed `ai-*.sh`.
- `chain-*`, `relayout.sh`, `setup-status.sh` — managed-window layout logic.

The `@claude-managed` window option name is preserved for backwards
compatibility with windows already managed across a config reload.

## Plugin Management (TPM)

Plugins are managed by [TPM](https://github.com/tmux-plugins/tpm) installed at `plugins/tpm/`.

- **Install plugins**: `prefix + I` (inside tmux), or `plugins/tpm/bin/install_plugins`
- **Update plugins**: `prefix + U`, or `plugins/tpm/bin/update_plugins`
- **Remove unused**: `prefix + alt+u`, or `plugins/tpm/bin/clean_plugins`

To add a plugin, append `set -g @plugin 'owner/repo'` before the `run '~/.config/tmux/plugins/tpm/tpm'` line.

## Active Plugins

- `tmux-plugins/tmux-sensible` — sane defaults
- `christoomey/vim-tmux-navigator` — seamless vim/tmux pane navigation
- `janoamaral/tokyo-night-tmux` — Tokyo Night theme

## Applying Changes

Reload config without restarting tmux:
```
tmux source ~/.config/tmux/tmux.conf
```
Or from within tmux: `prefix + :source ~/.config/tmux/tmux.conf`
