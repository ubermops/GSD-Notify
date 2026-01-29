# gsd-notify

Get pinged on Discord when Claude Code needs attention.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ubermops/gsd-notify/main/install.sh | bash
```

## Setup

1. Paste your Discord webhook URL (from pinned message in your channel)
2. Paste your Discord user ID (right-click your name → Copy User ID)

Done. You'll get pinged when Claude Code stops and awaits input.

## How it works

- Triggers on Claude Code's `Stop` and `SubagentStop` hooks
- 15-minute cooldown between pings (no spam)
- Message: `@you It's time to GSD!`

## Requirements

- macOS, Linux, or WSL (Windows users need WSL)
- curl (pre-installed on most systems)

## License

MIT
