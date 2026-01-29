# gsd-notify

## What This Is

A one-command installer that pings teammates on Discord when Claude Code needs attention. Users run a curl command, paste their Discord webhook URL and user ID, and get notified whenever Claude stops and awaits input.

## Core Value

Teammates get pinged on Discord when Claude Code needs attention — no missed prompts, no wasted time.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] User can install via single curl command
- [ ] Installer prompts for Discord webhook URL
- [ ] Installer prompts for Discord user ID
- [ ] Installer creates ~/.claude/gsd-notify.sh notification script
- [ ] Installer configures Stop and SubagentStop hooks in ~/.claude/settings.json
- [ ] Installer merges with existing hooks (doesn't replace them)
- [ ] Notification script checks 15-minute cooldown before pinging
- [ ] Notification script sends "<@DISCORD_ID> It's time to GSD!" via webhook
- [ ] Installer sends test ping to confirm setup works
- [ ] Notification script fails silently if webhook fails
- [ ] Re-running installer overwrites existing settings

### Out of Scope

- Multiple Discord IDs — single user per install, keep it simple
- Configurable cooldown — 15 minutes is hardcoded
- Configurable message — message is fixed
- Uninstall script — manual removal via README instructions
- Windows native support — requires WSL (bash-only)
- Discord bot or server — webhook-only, no infrastructure

## Context

**Discord webhooks:** User gets webhook URL from a pinned message in their Discord channel. Format: `https://discord.com/api/webhooks/...`

**Discord user ID:** Right-click user → Copy User ID. Format: 18-digit number.

**Claude Code hooks:** Configured in `~/.claude/settings.json` under `hooks.Stop` and `hooks.SubagentStop` arrays. Each hook is a shell command string.

**Cooldown mechanism:** Timestamp stored in `~/.claude/.last_ping`. Script compares current time to last ping time. If >= 15 minutes (900 seconds), send ping and update timestamp.

## Constraints

- **Language**: Pure bash — no Python, Node, or other runtimes
- **Dependencies**: curl only — pre-installed on macOS/Linux
- **No infrastructure**: Webhook-only, no bot token, no server
- **Compatibility**: macOS, Linux, WSL (bash required)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Merge hooks, don't replace | Preserve user's existing hook configurations | — Pending |
| Overwrite on reinstall | Simpler UX, no detection/confirmation prompts needed | — Pending |
| Silent failure on webhook error | Don't break Claude Code if webhook fails | — Pending |
| 15-minute cooldown hardcoded | Keep it simple, no config files beyond settings.json | — Pending |

## Deliverables

- `install.sh` — the one-command installer
- `README.md` — short, shows the two steps
- `LICENSE` — MIT

## Post-Build

Walk user through creating a new public GitHub repo and pushing the code. User has no git/GitHub experience.

---
*Last updated: 2026-01-28 after initialization*
