#!/usr/bin/env bash
# Uninstall cinnamon-mac-shortcuts: remove shortcuts & scripts.
#   ./uninstall.sh --keep-scripts   leave files in place, only undo keybindings/zsh
set -uo pipefail

PREFIX="${MAC_PREFIX:-$HOME/.local/bin}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEEP_SCRIPTS=0
[ "${1:-}" = "--keep-scripts" ] && KEEP_SCRIPTS=1

log() { printf '\033[1;33m==>\033[0m %s\n' "$*"; }

# --- remove custom shortcuts --------------------------------------------
BASE=/org/cinnamon/desktop/keybindings/custom-keybindings
CURLIST=$(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null)
REMAIN=()
for name in $(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null | tr -d '[],\047'); do
    [ -z "$name" ] && continue
    if [[ $name == mac-* ]]; then
        dconf reset -f "$BASE/$name/"
        log "removed shortcut: $name"
    else
        REMAIN+=("$name")
    fi
done
if [ "$(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null)" = "[]" ] || [ ${#REMAIN[@]} -eq 0 ]; then
    gsettings set org.cinnamon.desktop.keybindings custom-list "[]"
else
    fmt=$(printf ', "%s"' "${REMAIN[@]}")
    gsettings set org.cinnamon.desktop.keybindings custom-list "[${fmt#, }]"
fi

# --- remove thumb-button bindings (xbindkeys) ---------------------------
pkill -x xbindkeys 2>/dev/null && log "stopped xbindkeys"
rm -f "$HOME/.config/autostart/xbindkeys.desktop"
restored=0
for b in "$HOME"/.xbindkeysrc.bak.*; do
    [ -e "$b" ] || continue
    mv "$b" "$HOME/.xbindkeysrc"
    log "restored previous ~/.xbindkeysrc"
    restored=1
done
if [ "$restored" -eq 0 ] && [ -f "$HOME/.xbindkeysrc" ] && grep -q 'ctrl+Tab' "$HOME/.xbindkeysrc"; then
    rm -f "$HOME/.xbindkeysrc"
    log "removed our ~/.xbindkeysrc"
fi

# --- strip zsh integration line ------------------------------------------
if [ -f "$HOME/.zshrc" ]; then
    sed -i '/mac-clipboard.zsh/d; /mac-style clipboard (cinnamon-mac-shortcuts)/d' "$HOME/.zshrc"
    log "removed mac-clipboard source line from ~/.zshrc"
fi

# --- remove installed scripts --------------------------------------------
if [ "$KEEP_SCRIPTS" -eq 0 ]; then
    for f in cmd-xlate setup-mac-shortcuts.sh backup-cm.sh restore-cm.sh mac-clipboard.zsh; do
        rm -f "$PREFIX/$f"
    done
    log "removed scripts from $PREFIX"
fi

log "done. Custom shortcuts go inactive after a Cinnamon shell restart / re-login."
echo "Tip: undo a bad snapshot with: $PREFIX/restore-cm.sh --rescue (if still installed)"