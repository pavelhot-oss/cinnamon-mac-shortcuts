#!/usr/bin/env bash
# restore-cm.sh — restore a backup-cm.sh snapshot.
#   restore-cm.sh [backup_dir]   default: latest snapshot
#   restore-cm.sh --list         list available snapshots
#   restore-cm.sh --dry-run      show what would change, apply nothing
#   restore-cm.sh --rescue       make Cinnamon boot-safe (clears custom shortcuts)
#   restore-cm.sh --help
set -uo pipefail

BASE="$HOME/.config/cm-backups"
PREFIX="${MAC_PREFIX:-$HOME/.local/bin}"
DRY=0

usage() {
    echo "usage: restore-cm.sh [--list|--dry-run|--rescue|backup_dir]"
    echo "  (no arg)  restore the latest snapshot"
    exit 0
}

apply() { # log a restore action; run it unless --dry-run
    local msg=$1; shift
    if (( DRY )); then
        echo "dry-run: $msg"
    else
        echo "restored: $msg"
        "$@"
    fi
}

case "${1:-}" in
    --list)
        ls -1 "$BASE" 2>/dev/null | grep -v '^latest$'
        exit 0
        ;;
    --dry-run)
        DRY=1
        shift
        ;;
    --rescue)
        gsettings set org.cinnamon.desktop.keybindings custom-list "[]" 2>/dev/null
        echo "rescue: cleared custom-shortcut list. Cinnamon will boot shell-only."
        exit 0
        ;;
    -h|--help)
        usage
        ;;
    "")
        if [ -L "$BASE/latest" ]; then
            DIR=$(readlink -f "$BASE/latest")
        else
            echo "no backups found in $BASE" >&2
            exit 1
        fi
        ;;
    *)
        DIR="${1%/}"
        ;;
esac

[ -d "$DIR" ] || { echo "backup dir not found: $DIR" >&2; exit 1; }

if [ -f "$DIR/cinnamon.dconf" ]; then
    apply "/org/cinnamon/ (panels, applets, keybindings)" bash -c "dconf load /org/cinnamon/ < '$DIR/cinnamon.dconf'"
fi

if [ -f "$DIR/monitors.xml" ] && ! grep -q "no monitors.xml" "$DIR/monitors.xml"; then
    apply "monitors.xml (applies at next login)" cp "$DIR/monitors.xml" "$HOME/.config/monitors.xml"
fi

for f in "$DIR"/scripts/*; do
    [ -e "$f" ] || continue
    case "$(basename "$f")" in
        .zshrc) dest="$HOME/.zshrc" ;;
        cmd-xlate) dest="$PREFIX/cmd-xlate" ;;
        setup-mac-shortcuts.sh) dest="$PREFIX/setup-mac-shortcuts.sh" ;;
        *) continue ;;
    esac
    apply "$dest" bash -c "cp '$f' '$dest'; chmod +x '$dest'"
done

echo
echo "NOTE: custom shortcuts register when Cinnamon's shell restarts / after re-login."
echo "If Cinnamon ever fails to boot after a restore, run:  restore-cm.sh --rescue"