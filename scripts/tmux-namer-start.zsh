#!/usr/bin/env zsh
#
# tmux-namer-start.zsh - Lock the current tmux window name when a Claude session starts
#
# Prevents the Claude CLI version number from appearing as the window name.
# tmux's allow-rename picks up whatever terminal title Claude sets on startup
# (which includes its version, e.g. "2.1.84"). This script races ahead of that
# by re-setting the current window name via a tmux command (which allow-rename
# cannot override), preserving the original name until the Stop hook replaces
# it with a descriptive one.
#

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

[[ -z $TMUX ]] && exit 0

# Find Claude's tmux window. Claude Code spawns the hook through an intermediate
# `sh` with no controlling TTY, so walk up the process tree and take the first
# ancestor whose TTY maps to a tmux pane.
window_target=""
pid=$PPID
while [[ -n $pid && $pid -gt 1 ]]; do
  anc_tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
  if [[ -n $anc_tty && $anc_tty != '?' ]]; then
    [[ $anc_tty != /* ]] && anc_tty="/dev/$anc_tty"
    window_target=$(tmux list-panes -a -F '#{pane_tty} #{session_name}:#{window_id}' 2>/dev/null | \
      awk -v tty="$anc_tty" '$1 == tty { print $2; exit }')
    [[ -n $window_target ]] && break
  fi
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
done
[[ -z $window_target ]] && exit 0

current_name=$(tmux display-message -t "$window_target" -p '#{window_name}' 2>/dev/null)
[[ -n $current_name ]] && tmux rename-window -t "$window_target" "$current_name"
