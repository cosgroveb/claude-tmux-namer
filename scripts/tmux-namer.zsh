#!/usr/bin/env zsh
#
# tmux-namer.zsh - Rename tmux window based on Claude conversation context
#
# Uses Haiku to generate a 2-4 word phrase describing the work, then renames
# the tmux window where Claude is actually running.
#
# Reads transcript_path from the Stop hook payload (stdin) and sends only a
# brief excerpt to Haiku, avoiding the expensive cache_create cost that
# --continue incurs on a cold or expired cache.
#

# Ensure standard tool locations are in PATH — the hook runs with a restricted
# PATH that may omit /usr/bin and /opt/homebrew/bin.
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

# Worker mode: the detached re-exec (see the handoff at the bottom of the file)
# lands here and does the actual API call and rename.
if [[ -n $TMUX_NAMER_WORKER ]]; then
  transcript_path=$TMUX_NAMER_TRANSCRIPT
  window_target=$TMUX_NAMER_WINDOW
  LOG_FILE=$TMUX_NAMER_LOG

  # Build a prompt from the first 3 user messages in the transcript (capped at
  # 300 chars each). This avoids the large cache_create cost that --continue
  # triggers by loading the full conversation into a cold cache.
  if [[ -z $transcript_path || ! -f $transcript_path ]]; then
    echo "$(date -Iseconds) error=\"no transcript available\"" >> "$LOG_FILE"
    exit 0
  fi

  context=$(grep -m 3 '"type":"user"' "$transcript_path" \
    | jq -r '
        .message.content |
        if type == "array" then
          map(select(.type == "text") | .text) | join(" ")
        elif type == "string" then .
        else empty
        end
      ' 2>/dev/null \
    | awk '{ print substr($0, 1, 300) }' \
    | tr '\n' ' ')

  if [[ -z $context ]]; then
    echo "$(date -Iseconds) error=\"empty transcript context\"" >> "$LOG_FILE"
    exit 0
  fi

  prompt="Work session transcript excerpt: ${context}

Generate a 2-4 word lowercase phrase describing this work. Output ONLY the phrase, nothing else."

  output=$(claude \
    --model haiku \
    --output-format=stream-json \
    --verbose \
    --print \
    --settings '{"disableAllHooks": true}' \
    -p "$prompt" \
    2>&1)

  # Check for API errors and skip rename
  if echo "$output" | grep -q '"type":"error"'; then
    error_msg=$(echo "$output" | grep '"type":"error"' | jq -r '.error.message // "unknown"' 2>/dev/null | head -1)
    echo "$(date -Iseconds) error=\"API error\" message=\"${error_msg}\"" >> "$LOG_FILE"
    exit 0
  fi

  # Extract name and log cost metrics
  result_line=$(echo "$output" | grep '"type":"result"' | head -1)
  name=$(echo "$result_line" | jq -r '.result // empty' | tr -d '\n')

  if [[ -n $result_line ]]; then
    cost=$(echo "$result_line" | jq -r '.total_cost_usd // 0')
    input_tokens=$(echo "$result_line" | jq -r '.usage.input_tokens // 0')
    output_tokens=$(echo "$result_line" | jq -r '.usage.output_tokens // 0')
    cache_read=$(echo "$result_line" | jq -r '.usage.cache_read_input_tokens // 0')
    cache_create=$(echo "$result_line" | jq -r '.usage.cache_creation_input_tokens // 0')
    safe_name=${name//\"/\\\"}
    echo "$(date -Iseconds) cost=\$${cost} input=${input_tokens} output=${output_tokens} cache_read=${cache_read} cache_create=${cache_create} name=\"${safe_name}\"" >> "$LOG_FILE"
  else
    echo "$(date -Iseconds) error=\"no result line found\"" >> "$LOG_FILE"
  fi

  # Sanitize and truncate, then rename
  name=${name//[^a-zA-Z0-9 ]/}
  (( ${#name} > 40 )) && name="${name:0:40}"
  [[ -n $name ]] && tmux rename-window -t "$window_target" "$name"
  exit 0
fi

# Hook entry point. Runs in the foreground under a 2s timeout, so it only finds
# the target window and hands off to the worker.

# Exit silently if not in tmux
[[ -z $TMUX ]] && exit 0

# Find the tmux window Claude is running in. Claude Code spawns the hook through
# an intermediate `sh` with no controlling TTY, so $PPID's TTY is unusable.
# Walk up the process tree and take the first ancestor whose TTY maps to a tmux
# pane — that's Claude's own pane.
window_target=""
pid=$PPID
while [[ -n $pid && $pid -gt 1 ]]; do
  anc_tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
  if [[ -n $anc_tty && $anc_tty != '?' ]]; then
    # Normalize TTY path (Linux: pts/N, macOS: ttysNNN)
    [[ $anc_tty != /* ]] && anc_tty="/dev/$anc_tty"
    window_target=$(tmux list-panes -a -F '#{pane_tty} #{session_name}:#{window_id}' 2>/dev/null | \
      awk -v tty="$anc_tty" '$1 == tty { print $2; exit }')
    [[ -n $window_target ]] && break
  fi
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
done
[[ -z $window_target ]] && exit 0

# Log file for cost tracking
LOG_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/claude-tmux-namer/cost.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Read the Stop hook payload from stdin. Claude Code pipes a JSON object
# containing transcript_path; cat returns immediately when the pipe closes.
hook_payload=$(cat 2>/dev/null)
transcript_path=$(jq -r '.transcript_path // empty' 2>/dev/null <<< "$hook_payload")

# Hand the work to a detached worker in its own session. Claude Code kills the
# hook's process group the moment the hook returns, and a plain background job
# (&!) stays in that group and dies before the API call finishes. setsid moves
# the worker into a new session so it survives. macOS has no setsid, so fall
# back to perl's POSIX::setsid there.
export TMUX_NAMER_WORKER=1
export TMUX_NAMER_TRANSCRIPT="$transcript_path"
export TMUX_NAMER_WINDOW="$window_target"
export TMUX_NAMER_LOG="$LOG_FILE"

if command -v setsid >/dev/null 2>&1; then
  setsid "$0" </dev/null >/dev/null 2>&1 &
else
  perl -MPOSIX -e 'setsid; exec @ARGV' "$0" </dev/null >/dev/null 2>&1 &
fi
disown 2>/dev/null

exit 0
