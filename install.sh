#!/usr/bin/env bash
# Install cinnamon-mac-shortcuts: global Mac-style shortcuts for Cinnamon (X11).
#   ./install.sh            full install (packages, scripts, keybindings, zsh)
#   ./install.sh --no-zsh   skip zsh line-editor bindings
#   SKIP_DEPS=1 ./install.sh  don't touch the package manager
set -euo pipefail

MOD="${MAC_MOD:-Alt}"
PREFIX="${MAC_PREFIX:-$HOME/.local/bin}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARN:\033[0m %s\n' "$*"; }

# --- deps ---------------------------------------------------------------
if [ "${SKIP_DEPS:-0}" != "1" ]; then
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
    else
        SUDO="sudo"
    fi
    case "${MAC_PKGMGR:-}" in
        apt)   $SUDO apt-get install -y xdotool xclip ;;
        pacman) $SUDO pacman -S --noconfirm xdotool xclip ;;
        dnf)   $SUDO dnf install -y xdotool xclip ;;
        "")
            if command -v apt-get >/dev/null; then
                $SUDO apt-get install -y xdotool xclip
            elif command -v pacman >/dev/null; then
                $SUDO pacman -S --noconfirm xdotool xclip
            elif command -v dnf >/dev/null; then
                $SUDO dnf install -y xdotool xclip
            else
                warn "unknown package manager — install 'xdotool' and 'xclip' manually"
            fi
            ;;
    esac
fi

# --- environment sanity -------------------------------------------------
if [ -z "${DISPLAY:-}" ]; then
    warn "no DISPLAY set — are you running inside an X session? keybindings won't register."
fi
if ! gsettings list-schemas 2>/dev/null | grep -q org.cinnamon; then
    warn "Cinnamon not detected (no org.cinnamon schemas). This targets Cinnamon on X11."
fi

# --- install scripts ----------------------------------------------------
mkdir -p "$PREFIX"
for f in cmd-xlate setup-mac-shortcuts.sh backup-cm.sh restore-cm.sh zsh/mac-clipboard.zsh; do
    cp "$HERE/$f" "$PREFIX/$(basename "$f")"
    chmod +x "$PREFIX/$(basename "$f")"
done
log "installed scripts into $PREFIX"

# --- register shortcuts with Cinnamon -----------------------------------
"$PREFIX/setup-mac-shortcuts.sh"
log "keybindings registered (grab becomes active after a Cinnamon shell restart / re-login)"

# --- zsh line-editor bindings -------------------------------------------
if [ "${1:-}" != "--no-zsh" ]; then
    if command -v zsh >/dev/null 2>&1; then
        if [ -f "$HOME/.zshrc" ] && grep -q 'mac-clipboard.zsh' "$HOME/.zshrc"; then
            log "zshrc already sources mac-clipboard.zsh"
        else
            { echo ""; echo "# mac-style clipboard (cinnamon-mac-shortcuts)"; \
              echo "[ -f \"\$HOME/.local/bin/mac-clipboard.zsh\" ] && source \"\$HOME/.local/bin/mac-clipboard.zsh\""; \
            } >> "$HOME/.zshrc"
            log "added source line to ~/.zshrc (remember the \$.local/bin path matches MAC_PREFIX)"
        fi
    else
        warn "zsh not installed — skipping line-editor bindings (they complement the global ones)"
    fi
fi

log "done. Open a NEW terminal; global shortcuts activate after a Cinnamon restart / re-login."
echo
echo "  modifier : $MOD    (change with MAC_MOD=Super)"
echo "  prefix   : $PREFIX (change with MAC_PREFIX=/usr/local/bin)"
echo "  rescue   : $PREFIX/restore-cm.sh --rescue   (if Cinnamon ever fails to boot)"