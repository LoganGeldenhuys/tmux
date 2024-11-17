# tmux config

Personal tmux configuration using [TPM](https://github.com/tmux-plugins/tpm) for plugin management and the [Catppuccin](https://github.com/catppuccin/tmux) theme.

## Setup

**1. Clone into your tmux config directory:**

```sh
git clone https://github.com/LoganGeldenhuys/tmux.git ~/.config/tmux
```

**2. Install TPM:**

```sh
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

**3. Start tmux, then install plugins:**

```
prefix + I
```

(Prefix is `C-Space`)

## Key bindings

| Key | Action |
|-----|--------|
| `C-Space` | Prefix (replaces `C-b`) |
| `M-H` / `M-L` | Previous / next window |
| `C-h/j/k/l` | Navigate panes (vim-tmux-navigator) |

## Plugins

- [tmux-plugins/tpm](https://github.com/tmux-plugins/tpm) — plugin manager
- [tmux-plugins/tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) — sane defaults
- [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) — seamless vim/tmux navigation
- [dreamsofcode-io/catppuccin-tmux](https://github.com/dreamsofcode-io/catppuccin-tmux) — Catppuccin theme
