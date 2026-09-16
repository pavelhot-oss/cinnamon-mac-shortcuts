#!/usr/bin/env bash
# backup-cm.sh — snapshot Cinnamon desktop config state (panels, applets,
# custom keybindings, monitor layout, helper scripts, dotfiles).
# Usage: backup-cm.sh [description]
set -euo pipefail

BASE="$HOME/.config/cm-backups"
PREFIX="${MAC_PREFIX:-$HOME/.local/bin}"
STAMP=$(date +%Y%m%d-%H%M%S)
DESC=${1:-snapshot}
DIR="$BASE/${STAMP}_${DESC}"
mkdir -p "$DIR/scripts"

dconf dump /org/cinnamon/ > "$DIR/cinnamon.dconf"
gsettings get org.cinnamon.desktop.keybindings custom-list > "$DIR/custom-list.gvariant"

if [ -f "$HOME/.config/monitors.xml" ]; then
    cp "$HOME/.config/monitors.xml" "$DIR/monitors.xml"
else
    echo "(no monitors.xml)" > "$DIR/monitors.xml"
fi

for f in "$HOME/.zshrc" "$PREFIX/cmd-xlate" "$PREFIX/setup-mac-shortcuts.sh"; do
    if [ -f "$f" ]; then
        cp "$f" "$DIR/scripts/"
        echo "included: ${f#$HOME/}"
    fi
done

{
    echo "Cinnamon desktop config-state snapshot"
    echo "created: $(date -Is)"
    echo "desc: $DESC"
    echo "--- files ---"
    find "$DIR" -type f | sed "s|$DIR/||" | sort
} > "$DIR/MANIFEST.txt"

ln -sfn "$DIR" "$BASE/latest"
echo
echo "backup -> $DIR"
echo "latest -> $BASE/latest"