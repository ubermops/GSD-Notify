# Requirements: gsd-notify

**Defined:** 2026-01-28
**Core Value:** Teammates get pinged on Discord when Claude Code needs attention

## v1 Requirements

### Installation

- [ ] **INST-01**: User can install via `curl -fsSL .../install.sh | bash`
- [ ] **INST-02**: Installer prompts for Discord webhook URL
- [ ] **INST-03**: Installer prompts for Discord user ID
- [ ] **INST-04**: Installer creates `~/.claude/gsd-notify.sh`
- [ ] **INST-05**: Installer configures hooks in `~/.claude/settings.json`
- [ ] **INST-06**: Installer merges with existing hooks (doesn't replace)
- [ ] **INST-07**: Installer sends test ping to confirm setup
- [ ] **INST-08**: Re-running installer overwrites existing settings

### Notification

- [ ] **NOTF-01**: Script triggers on Stop and SubagentStop hooks
- [ ] **NOTF-02**: Script checks 15-minute cooldown before pinging
- [ ] **NOTF-03**: Script sends `<@DISCORD_ID> It's time to GSD!` via webhook
- [ ] **NOTF-04**: Script fails silently if webhook fails

### Documentation

- [ ] **DOCS-01**: README.md with install command and setup steps
- [ ] **DOCS-02**: README.md notes WSL requirement for Windows
- [ ] **DOCS-03**: LICENSE file (MIT)

## v2 Requirements

### Enhanced Features

- **FEAT-01**: Support multiple Discord IDs per install
- **FEAT-02**: Configurable cooldown period
- **FEAT-03**: Uninstall script

## Out of Scope

| Feature | Reason |
|---------|--------|
| Discord bot | Adds complexity, webhooks are sufficient |
| Server infrastructure | No backend needed, runs locally |
| Windows native support | Bash-only by design, WSL works |
| Configurable message | Keep it simple, fixed message |
| GUI installer | One curl command is simpler |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INST-01 | Phase 1 | Pending |
| INST-02 | Phase 1 | Pending |
| INST-03 | Phase 1 | Pending |
| INST-04 | Phase 1 | Pending |
| INST-05 | Phase 1 | Pending |
| INST-06 | Phase 1 | Pending |
| INST-07 | Phase 1 | Pending |
| INST-08 | Phase 1 | Pending |
| NOTF-01 | Phase 1 | Pending |
| NOTF-02 | Phase 1 | Pending |
| NOTF-03 | Phase 1 | Pending |
| NOTF-04 | Phase 1 | Pending |
| DOCS-01 | Phase 2 | Pending |
| DOCS-02 | Phase 2 | Pending |
| DOCS-03 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15 (100%)
- Unmapped: 0

---
*Requirements defined: 2026-01-28*
*Last updated: 2026-01-28 with phase mappings*
