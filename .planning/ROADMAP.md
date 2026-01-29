# Roadmap: gsd-notify

**Created:** 2026-01-28
**Depth:** quick
**Phases:** 2

## Overview

A one-command installer that pings teammates on Discord when Claude Code needs attention. This roadmap delivers the installer script, notification mechanism, and documentation needed for users to get notified via Discord when Claude Code awaits input.

## Phases

### Phase 1: Core System

**Goal:** Users can install via single command and receive Discord pings when Claude Code needs attention.

**Requirements:**
- **INST-01**: User can install via `curl -fsSL .../install.sh | bash`
- **INST-02**: Installer prompts for Discord webhook URL
- **INST-03**: Installer prompts for Discord user ID
- **INST-04**: Installer creates `~/.claude/gsd-notify.sh`
- **INST-05**: Installer configures hooks in `~/.claude/settings.json`
- **INST-06**: Installer merges with existing hooks (doesn't replace)
- **INST-07**: Installer sends test ping to confirm setup
- **INST-08**: Re-running installer overwrites existing settings
- **NOTF-01**: Script triggers on Stop and SubagentStop hooks
- **NOTF-02**: Script checks 15-minute cooldown before pinging
- **NOTF-03**: Script sends `<@DISCORD_ID> It's time to GSD!` via webhook
- **NOTF-04**: Script fails silently if webhook fails

**Success Criteria:**
1. User can run single curl command and complete installation with prompts
2. User receives test Discord ping immediately after installation
3. User receives Discord ping when Claude Code stops and awaits input
4. User does not receive duplicate pings within 15 minutes
5. Re-running installer updates webhook/ID without breaking configuration

**Dependencies:** None (initial phase)

**Estimated Plans:** 2-3 plans
- Plan: Notification script with cooldown mechanism
- Plan: Installation script with hook merging
- Plan: Test ping verification

---

### Phase 2: Documentation & Publishing

**Goal:** Users can discover, install, and troubleshoot gsd-notify via clear documentation.

**Requirements:**
- **DOCS-01**: README.md with install command and setup steps
- **DOCS-02**: README.md notes WSL requirement for Windows
- **DOCS-03**: LICENSE file (MIT)

**Success Criteria:**
1. User can find install command in README within 5 seconds
2. User knows Windows requires WSL before attempting install
3. Project has MIT license clearly stated

**Dependencies:** Phase 1 (need working installer to document)

**Estimated Plans:** 1 plan
- Plan: Documentation and licensing

---

## Progress

| Phase | Status | Completed |
|-------|--------|-----------|
| 1 - Core System | Pending | 0/12 requirements |
| 2 - Documentation & Publishing | Pending | 0/3 requirements |

**Overall:** 0/15 requirements complete (0%)

---

## Requirement Coverage

| Requirement | Phase | Description |
|-------------|-------|-------------|
| INST-01 | 1 | User can install via curl command |
| INST-02 | 1 | Installer prompts for Discord webhook URL |
| INST-03 | 1 | Installer prompts for Discord user ID |
| INST-04 | 1 | Installer creates notification script |
| INST-05 | 1 | Installer configures hooks |
| INST-06 | 1 | Installer merges with existing hooks |
| INST-07 | 1 | Installer sends test ping |
| INST-08 | 1 | Re-running installer overwrites settings |
| NOTF-01 | 1 | Script triggers on Stop hooks |
| NOTF-02 | 1 | Script checks 15-minute cooldown |
| NOTF-03 | 1 | Script sends Discord message |
| NOTF-04 | 1 | Script fails silently on error |
| DOCS-01 | 2 | README with install instructions |
| DOCS-02 | 2 | README notes WSL requirement |
| DOCS-03 | 2 | MIT LICENSE file |

**Coverage:** 15/15 requirements mapped (100%)

---

## Notes

**Phase Structure Rationale:**
This project has a simple linear structure. Phase 1 delivers the complete functional system (installer + notification script). Phase 2 adds documentation for discoverability. The "quick" depth setting supports this minimal 2-phase approach.

**Post-Phase 2:**
After Phase 2 completion, user needs guidance on creating GitHub repo and pushing code (user has no git/GitHub experience).

---
*Last updated: 2026-01-28*
