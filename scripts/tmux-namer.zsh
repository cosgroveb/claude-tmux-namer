#!/usr/bin/env zsh
#
# tmux-namer.zsh - Rename tmux window based on Claude conversation context
#
# Uses Haiku in background to generate a 2-4 word phrase describing the work,
# then renames the tmux window where Claude is actually running.
#

# Exit silently if not in tmux
[[ -z $TMUX ]] && exit 0

# Find the window where Claude is running by tracing the process tree
# 1. Get parent PID (Claude process)
# 2. Get its TTY
# 3. Find which tmux pane has that TTY
# 4. Extract the window target

claude_tty=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' ')
[[ -z $claude_tty ]] && exit 0

# Normalize TTY path (Linux: pts/N, macOS: ttysNNN)
[[ $claude_tty != /* ]] && claude_tty="/dev/$claude_tty"

# Find the tmux pane with this TTY and get its window
window_target=$(tmux list-panes -a -F '#{pane_tty} #{session_name}:#{window_id}' 2>/dev/null | \
  awk -v tty="$claude_tty" '$1 == tty { print $2; exit }')

[[ -z $window_target ]] && exit 0

# Background the API call to avoid blocking
{
  name=$(
    claude --continue \
      --model haiku \
      --print \
      --settings '{"disableAllHooks": true}' \
      -p "Generate a 2-4 word lowercase phrase describing this work session. Output ONLY the phrase, nothing else." \
      2>&1
  )

  # Only rename if we got a non-empty, reasonable result
  [[ -n $name && ${#name} -lt 50 ]] && tmux rename-window -t "$window_target" "$name"
} &!
