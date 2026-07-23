# AGENTS.md — TaianDotFiles

CachyOS (Arch) dotfiles for a Hyprland desktop, managed with **GNU Stow**.

## Stow layout convention

Root-level directories are stow packages. Each maps to a target under `$HOME`:

| Package root | Dest path | Note |
|---|---|---|
| `<name>/` | `~/.config/<name>/` | Default for most packages — the directory contains a `.config/<name>/` tree |
| `zsh/` | `~/.zshrc` | Exception — contains the rc file directly (no `.config/` nesting) |

The `install.sh` script iterates a hardcoded list of packages and calls `stow <name>`. If a config dir already exists (not a symlink), it is backed up to `<name>.bak` first.

## Key packages

- **hypr/** — Hyprland config is **Lua-based** (`hyprland.lua`), not `.conf`. Modules live in `TaianDotfiles2M/` (env, autostart, keybinds, general, monitors, rules, animations, input, plugins). `OLD/` contains archived historical configs.
- **quickshell/** — QML-based desktop shell using the Quickshell Qt framework. `shell.qml` is the entrypoint. Subdirs: `components/`, `core/`, `modules/`, `services/`, `scripts/`.
- **waybar/** — Modules defined in `modules.json`. Theme colors in `colors.css` / `colorsw.css` (likely pywal-generated). Custom scripts in `scripts/`.
- **nvim/** — LazyVim-based Neovim config. Plugin lockfile at `lazy-lock.json`. Uses `stylua` for Lua formatting.
- **zsh/** — Uses **zinit** plugin manager with oh-my-zsh snippets. Prompt is **starship** (preset applied in install.sh).

## Installation

```bash
./install.sh
```

- Only runs on CachyOS (checks for `cachy` in `uname -r` output).
- Installs official packages from `.official_pkgs.txt` (pacman) and AUR packages from `.aur_pkgs.txt` (yay).
- Then runs `stow` for each dotfile package, installs zinit, starship prompt, and changes the default shell to zsh.
- Also installs nitch (`setup.sh`).

## Theme / color flow

- **pywal** generates color schemes from wallpapers.
- `~/Personal_Scripts/pywal_global_update.sh` updates all themed configs (waybar, kitty, hypr, etc.).
- **matugen** (AUR: `matugen-bin`) is also available — likely used by quickshell theming.

## Non-obvious tooling

- `.qmlls.ini` in quickshell config configures the QML language server for the quickshell build dir and import paths.
- `.luarc.json` in hypr/ and nvim/ configs provide LuaLS workspace libraries for Hyprland stubs and Neovim APIs.
- Hyprland submodule directory is named `TaianDotfiles2M` — this is the Lua module prefix used in `hyprland.lua`.
