#!/usr/bin/env bash
# Register the Cmd-shortcut translation layer with Cinnamon's shortcut manager.
# Each combo fires the cmd-xlate dispatcher, which re-sends the keypress as the
# app-level shortcut (Ctrl+<key>, or Ctrl+Shift+<key> in terminals).
set -euo pipefail

# Config: which modifier acts as "Cmd", and where scripts are installed.
#   MOD=Super to use the Windows/Win key instead of Alt.
#   MAC_PREFIX=/usr/local/bin if you install system-wide.
MOD="${MAC_MOD:-Alt}"
PREFIX="${MAC_PREFIX:-$HOME/.local/bin}"

SCHEMA=org.cinnamon.desktop.keybindings.custom-keybinding
BASE=/org/cinnamon/desktop/keybindings/custom-keybindings
CMD="$PREFIX/cmd-xlate"
NAMES=()

while IFS='|' read -r name binding action; do
    [[ -n $name ]] || continue
    path="$BASE/$name/"
    # swap the default Alt marker for the configured modifier, e.g. <Super>
    binding="${binding//<Alt>/<$MOD>}"
    gsettings set "$SCHEMA:$path" name "$name"
    gsettings set "$SCHEMA:$path" binding "$binding"
    gsettings set "$SCHEMA:$path" command "$CMD $action"
    NAMES+=("$name")
done <<'EOF'
mac-copy|['<Alt>c']|copy
mac-paste|['<Alt>v']|paste
mac-paste-plain|['<Shift><Alt>v']|paste-plain
mac-cut|['<Alt>x']|cut
mac-select-all|['<Alt>a']|select-all
mac-undo|['<Alt>z']|undo
mac-redo|['<Shift><Alt>z']|redo
mac-find|['<Alt>f']|find
mac-find-next|['<Alt>g']|find-next
mac-save|['<Alt>s']|save
mac-close|['<Alt>w']|close
mac-close-all|['<Shift><Alt>w']|close-all
mac-new-tab|['<Alt>t']|new-tab
mac-new-window|['<Alt>n']|new-window
mac-quit|['<Alt>q']|quit
mac-print|['<Alt>p']|print
mac-reload|['<Alt>r']|reload
mac-line-start|['<Alt>Left']|line-start
mac-line-end|['<Alt>Right']|line-end
mac-page-top|['<Alt>Up']|page-top
mac-page-bottom|['<Alt>Down']|page-bottom
mac-pref|['<Alt>comma']|pref
mac-tab-1|['<Alt>1']|tab-1
mac-tab-2|['<Alt>2']|tab-2
mac-tab-3|['<Alt>3']|tab-3
mac-tab-4|['<Alt>4']|tab-4
mac-tab-5|['<Alt>5']|tab-5
mac-tab-6|['<Alt>6']|tab-6
mac-tab-7|['<Alt>7']|tab-7
mac-tab-8|['<Alt>8']|tab-8
mac-tab-9|['<Alt>9']|tab-9
EOF

fmt=$(printf ', "%s"' "${NAMES[@]}")
arr="[${fmt#, }]"
gsettings set org.cinnamon.desktop.keybindings custom-list "$arr"
echo "registered ${#NAMES[@]} shortcuts"
gsettings get org.cinnamon.desktop.keybindings custom-list