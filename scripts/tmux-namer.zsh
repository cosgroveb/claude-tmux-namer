#!/usr/bin/env zsh
#
# tmux-namer.zsh - Rename tmux session based on Claude conversation context
#
# Uses Haiku in background to generate a 2-4 word phrase describing the work,
# then renames the current tmux session. Exits immediately to avoid blocking.
#

# Exit silently if not in tmux
[[ -z $TMUX ]] && exit 0

# Background the API call to avoid blocking
{
  name=$(
    timeout 30 claude --continue \
      --replay-user-messages \
      --input-format=stream-json \
      --output-format=stream-json \
      --model haiku \
      --verbose \
      --settings '{"disableAllHooks": true}' \
      -p "Generate a 2-4 word lowercase phrase describing this work session. Output ONLY the phrase, nothing else." \
      2>/dev/null |
    jq -r 'select(.type == "text") | .text' 2>/dev/null |
    paste -sd ' ' -
  )

  # Only rename if we got a non-empty result
  [[ -n $name ]] && tmux rename-session "$name" 2>/dev/null
} &>/dev/null &
disown $!
