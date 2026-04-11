# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal tmux configuration repository. The main config is `tmux.conf` at the root.

## Key Settings

- **Prefix**: `C-Space` (replaces default `C-b`)
- **Window/pane indexing**: starts at 1
- **Mouse support**: enabled
- **Window switching**: `M-H` / `M-L` (Alt+Shift+H/L)

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
