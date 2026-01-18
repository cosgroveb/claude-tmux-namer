# claude-tmux-namer

A Claude Code plugin that automatically renames your tmux window with a short phrase describing your current work.

<img width="519" height="117" alt="image" src="https://github.com/user-attachments/assets/a99c14ee-aef7-43a6-8dee-5169a7886b18" />

## How it works

After each Claude response, a Haiku agent reads the conversation context via `--continue` and generates a 2-4 word lowercase phrase (e.g., "fixing auth bug", "adding api endpoint"). The phrase becomes your tmux window name.

- **Asynchronous**: Fires off another claude and uses haiku
- **Context-aware**: Has full conversation history via `--continue`
- **Graceful**: Silently skips if not in tmux or if anything fails

## Installation

Using Claude Code slash commands:

```
/plugin marketplace add git@github.com:cosgroveb/claude-tmux-namer.git
/plugin install tmux-window-namer@claude-tmux-namer
```

Or clone and install manually:

```bash
git clone git@github.com:cosgroveb/claude-tmux-namer.git
cd claude-tmux-namer
make install
```

## Uninstallation

```
/plugin uninstall tmux-window-namer
/plugin marketplace remove claude-tmux-namer
```

Or manually:

```bash
cd claude-tmux-namer
make uninstall
```

## Requirements

- Claude Code CLI
- tmux

## License

MIT
