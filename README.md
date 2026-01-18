# claude-tmux-namer

A Claude Code plugin that automatically renames your tmux window with a short phrase describing your current work.

## How it works

After each Claude response, a Haiku agent reads the conversation context via `--continue` and generates a 2-4 word lowercase phrase (e.g., "fixing auth bug", "adding api endpoint"). The phrase becomes your tmux window name.

- **Cost-effective**: Uses Haiku instead of the main model
- **Context-aware**: Has full conversation history via `--continue`
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

## License

MIT
