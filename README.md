# claude-tmux-namer

A Claude Code plugin that automatically renames your tmux session with a short phrase describing your current work.

## How it works

After each Claude response, a background Haiku agent reads the conversation context and generates a 2-4 word lowercase phrase (e.g., "fixing auth bug", "adding api endpoint"). The phrase becomes your tmux session name.

- **Non-blocking**: The hook exits immediately; naming happens in background
- **Cost-effective**: Uses Haiku (~$0.0001 per rename) instead of the main model
- **Context-aware**: Has full conversation history via `--continue --replay-user-messages`
- **Graceful**: Silently skips if not in tmux or if anything fails

## Installation

```bash
git clone git@github.com:cosgroveb/claude-tmux-namer.git
cd claude-tmux-namer
make install
```

## Uninstallation

```bash
cd claude-tmux-namer
make uninstall
```

## Requirements

- Claude Code CLI
- tmux
- jq

## License

MIT
