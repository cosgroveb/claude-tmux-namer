#!/usr/bin/env zsh
#
# tmux-namer.zsh - Rename tmux window based on Claude conversation context
#
# Uses Haiku in background to generate a 2-4 word phrase describing the work,
# then renames the tmux window where Claude is running.
#

# Exit silently if not in tmux
[[ -z $TMUX ]] && exit 0

# Capture the window ID now, before backgrounding
# Format: @session:window (e.g., "0:1" or "main:2")
window_target=$(tmux display-message -p '#{session_name}:#{window_id}')

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
