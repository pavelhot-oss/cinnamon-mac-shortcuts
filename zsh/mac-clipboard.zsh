# mac-clipboard.zsh — Mac-style clipboard key bindings for the Zsh line editor.
#   Alt+C copy (line or selection)   Alt+X cut line   Alt+V paste   Alt+A select all
# Also defines `clipcopy` / `clippaste` commands (pipe-based).
# Requires xclip on X11. Source from ~/.zshrc:
#
#   [ -f ~/.local/bin/mac-clipboard.zsh ] && source ~/.local/bin/mac-clipboard.zsh
#
# These complements the OS-level translation (cmd-xlate) and act as a fallback
# when the global shortcut can't fire (e.g. inside a multiplexer).

if command -v xclip >/dev/null 2>&1; then
    _clipset()  { print -rn -- "$1" | xclip -selection clipboard -in &>/dev/null &|; }
    _clipget()  { xclip -selection clipboard -out 2>/dev/null; }

    # clipboard helpers for normal shell use:  something | clipcopy   /   clippaste
    clipcopy()  { xclip -selection clipboard -in &>/dev/null &|; }
    clippaste() { xclip -selection clipboard -out; }

    _mac-copy() {
        local text=$BUFFER
        if (( MARK > 0 )) && (( MARK != CURSOR )); then
            zle copy-region-as-kill 2>/dev/null
            (( $? == 0 )) && [[ -n $CUTBUFFER ]] && text=$CUTBUFFER
        fi
        _clipset "$text"
        zle -M "copied ${#text} char(s)"
    }

    _mac-cut() {
        _mac-copy
        zle kill-whole-line
        zle -M "cut to clipboard"
    }

    _mac-paste() {
        local txt=$(_clipget)
        [[ -z $txt ]] && return
        txt=${txt%$'\n'}        # drop one trailing newline for inline paste
        LBUFFER+=$txt
        zle -M "pasted ${#txt} char(s)"
    }

    _mac-select-all() {
        zle beginning-of-line
        zle set-mark-command
        zle end-of-buffer-or-history
        zle -M "all selected"
    }

    zle -N _mac-copy
    zle -N _mac-cut
    zle -N _mac-paste
    zle -N _mac-select-all

    bindkey '^[c' _mac-copy       # Alt+C
    bindkey '^[v' _mac-paste      # Alt+V
    bindkey '^[x' _mac-cut        # Alt+X
    bindkey '^[a' _mac-select-all # Alt+A
fi