# Contributing

This project was vibed into existence and it stays that way. Contributions work the same way.

## The One Sacred Rule

**All contributions must be AI-generated.**

Do not read the source code. Do not write code by hand. Do not think too hard. Describe what you want to an LLM and submit what it gives you.

This isn't a joke. It's the whole point. The tmux namer is the dumbest thing I could get working while barely trying — it is approximately 50 lines of zsh and vibes. If your contribution requires understanding the codebase, you have already failed.

## How to contribute

1. Find something broken or annoying.
2. Describe the problem to your AI of choice. ("It's broken, fix it" is a valid prompt.)
3. Let it generate a fix while you get a coffee.
4. Open a PR with whatever it gave you.

Include the prompt you used or a summary of the conversation. This is more useful than code comments, and way more honest.

## What's welcome

- **Bug reports.** Always welcome, no vibing required. Just complaining is fine.
- **Cost reduction ideas.** The tool calls Haiku via `--continue`, which sends the entire session context. Cached calls are ~$0.003 but uncached hits run ~$0.03-0.05. If you can make it cheaper, I want to hear it.
- **Robustness fixes.** It stops working sometimes. That's annoying. Make it not do that.
- **Better behavior during long context sessions.** Haiku doesn't support 1M context windows, so the namer dies with "Prompt is too long." Graceful degradation (any graceful degradation) would be a significant improvement over the current strategy of giving up.
- **A local model alternative.** Bigger lift, but would eliminate API costs entirely. Bragging rights included.

## What's not welcome

- **Hand-written code.** Seriously. I will know.
- **Refactors for the sake of refactoring.** It's ~50 lines of zsh. It doesn't need to be clean. It needs to rename windows.
- **Dependencies.** No. Absolutely not.
- **Scope creep.** It renames tmux windows. That's it. That's the whole thing. If you want a full session manager, start a new repo and name it something worse.

## Project structure

```
.claude-plugin/    # Plugin manifest (don't touch this if you don't know what it does)
scripts/           # The actual zsh script (50 lines, truly)
.github/workflows/ # CI (plugin validation, so the plugin doesn't silently break)
Makefile           # install/uninstall targets
```

## Validating changes

```
make install
```

The plugin validates via a GitHub Actions workflow. Cost data logs to `~/.local/share/claude-tmux-namer/cost.log` — check it if you're worried your fix is secretly running up a tab.

## PRs

I'll review PRs when I get to them. This is a side project I maintain in the margins of a life that contains other things. Slow responses are not personal. Silence is not rejection. It just means I'm busy and this renames tmux windows.
