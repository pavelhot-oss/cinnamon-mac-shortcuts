# cinnamon-mac-shortcuts

Put your Mac muscle memory to work on Linux. `Alt+<key>` behaves like macOS `Cmd+<key>` — **in every app** — by transparently translating the keypress into the shortcut each app actually understands.

```
Alt+C  ────►  Ctrl+C    (copy)
Alt+V  ────►  Ctrl+V    (paste)
Alt+A  ────►  Ctrl+A    (select all)
Alt+W  ────►  Ctrl+W    (close tab / window)
…
```

In terminals it special-cases `gnome-terminal`/`kitty`/etc. so `Alt+C/V/A` send `Ctrl+Shift+C/V/A` (the terminal's real copy/paste/select-all) instead of shell control characters.

## How it works

1. **`setup-mac-shortcuts.sh`** registers combos in Cinnamon's own shortcut manager (native `dconf`-backed custom shortcuts — no daemon).
2. Each combo fires **`cmd-xlate`**, a tiny dispatcher that checks the focused window's class and re-sends the key as `Ctrl+<key>` (or `Ctrl+Shift+<key>` in terminals) via `xdotool`.
3. **`zsh/mac-clipboard.zsh`** adds the same copy/paste keys to the Zsh line editor as a fallback (e.g. inside multiplexers).

## Requirements

- Cinnamon desktop on **X11** (the dispatcher relies on X grabs + `xdotool`)
- `xdotool`, `xclip` (installed automatically by `install.sh` on apt/pacman/dnf)
- optional: `xbindkeys` for thumb-button tab switching (also installed automatically)
- optional: `zsh` for the line-editor bindings

## Install

```bash
git clone <this repo> && cd cinnamon-mac-shortcuts
./install.sh
```

Then **log out/in** (or restart Cinnamon's shell) so the new grabs activate, and open a new terminal.

Shortcut table (`Alt=Cmd` unless `MAC_MOD=Super`):

| Keys | Action | Keys | Action |
|---|---|---|---|
| `Alt C` | Copy | `Alt Z` / `Alt Shift-Z` | Undo / Redo |
| `Alt V` | Paste | `Alt F` / `Alt G` | Find / Find next |
| `Alt Shift-V` | Paste plain | `Alt S` | Save |
| `Alt X` | Cut | `Alt W` / `Alt Shift-W` | Close tab / window |
| `Alt A` | Select all | `Alt T` / `Alt N` | New tab / window |
| `Alt Q` | Quit app | `Alt P` / `Alt R` | Print / Reload |
| `Alt ←/→/↑/↓` | Line/Page nav | `Alt 1-9` | Switch tab |
| `Alt ,` | Preferences | | |

`Alt+Tab`, `Alt+F4`, `Alt+F2` and other window-manager combos are untouched.

## Thumb-button tab switching

A second set of bindings maps the two Logitech thumb side-buttons (`BTN_SIDE` / `BTN_EXTRA`) to `Ctrl+Tab` / `Ctrl+Shift+Tab` globally via `xbindkeys` — the X11 equivalent of `mouse:275` / `mouse:276` in the Hyprland/omarchy version:

| Mouse button | X code | Evdev code | Sends |
|---|---|---|---|
| Thumb-back (`BTN_SIDE`) | `b:8` | `275` | `Ctrl+Tab` (next tab) |
| Thumb-fwd (`BTN_EXTRA`) | `b:9` | `276` | `Ctrl+Shift+Tab` (previous tab) |

Config lives in `~/.xbindkeysrc`; autostart file in `~/.config/autostart/xbindkeys.desktop`. If the buttons feel reversed, swap `b:8` ↔ `b:9` in the config.

## Configuration (env vars)

| Env | Default | Purpose |
|---|---|---|
| `MAC_MOD` | `Alt` | The "Cmd" modifier, e.g. `MAC_MOD=Super` for the Win key |
| `MAC_PREFIX` | `~/.local/bin` | Where scripts are installed |
| `MAC_TERMINALS_GLOB` | `*gnome-terminal*|…` | Focused windows treated as terminals |
| `SKIP_DEPS` | `0` | `SKIP_DEPS=1` — don't touch the package manager |

## Backup / restore

```bash
backup-cm.sh "before-tweak"     # snapshot panels, applets, keybindings, monitors, dotfiles
restore-cm.sh --list
restore-cm.sh --dry-run         # preview
restore-cm.sh                   # restore latest snapshot
restore-cm.sh --rescue          # boot failsafe: clears only custom shortcuts
```

## Troubleshooting

- **Cinnamon fails to start / no taskbars after login** — almost always a malformed shortcut list. Fix: `restore-cm.sh --rescue`, which empties the custom-shortcut list while leaving panels intact.
- **Shortcuts don't fire yet** — the grabs register at shell start; log out/in once.
- **Wayland?** The global translation is X11-only. On Wayland Cinnamon the zsh bindings still work; for a global layer you'd need an input-level tool such as `keyd` instead.

## Security / privacy

Backups (`~/.config/cm-backups`) contain personal state (wallpaper paths, monitor layouts, applet settings). **Never commit them.** The repo `.gitignore` keeps them out automatically.

## License

MIT — see `LICENSE`.