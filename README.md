# gsd-notify

Get pinged on Discord when Claude Code needs attention.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ubermops/gsd-notify/main/install.sh | bash
```

## Setup

1. Paste your Discord webhook URL (from pinned message in your channel)
2. Paste your Discord user ID (right-click your name → Copy User ID)

Done. You'll get pinged when Claude Code needs your attention.

## How it works

- When Claude stops and waits for input, a 5-minute timer starts
- If you respond within 5 minutes, no notification
- If 5 minutes pass with no activity, you get pinged once
- No spam: you won't be pinged again until you respond

## Requirements

- **Claude Code CLI** (`claude` command) - hooks don't work in VSCode extension ([known issue](https://github.com/anthropics/claude-code/issues/16114))
- macOS, Linux, or Windows (Git Bash/WSL)
- curl (pre-installed on most systems)

## Known Limitations

- **VSCode extension not supported** - Claude Code's VSCode extension doesn't fire hooks ([issue #16114](https://github.com/anthropics/claude-code/issues/16114)). Use the CLI instead.
- **Triggers on any response** - Currently pings after any Claude response, not just questions. Waiting on upstream fix ([issue #12048](https://github.com/anthropics/claude-code/issues/12048)).

## Uninstall

```bash
rm ~/.claude/gsd-notify.sh ~/.claude/gsd-wait.sh ~/.claude/gsd-activity.sh
rm ~/.claude/.waiting_since ~/.claude/.notified
```

Then manually remove the `Stop`, `SubagentStop`, `UserPromptSubmit`, and `SessionStart` hooks from `~/.claude/settings.json`.

## License

MIT
