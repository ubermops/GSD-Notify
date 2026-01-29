# Changelog

All notable changes to GSD Notify will be documented in this file.

## [Unreleased]

### Changed
- **Simplified timer architecture** - First Stop wins, subsequent Stops are ignored until user responds
  - Eliminates race conditions between Stop and SubagentStop hooks
  - Only one background timer runs per wait cycle
  - Predictable 5-minute countdown from first stop

## [1.0.0] - 2025-01-28

### Fixed
- Clear stale files on session start
- Always update timestamp on stop (superseded by simplified architecture)
- Only notify after 5 minutes of inactivity
- Simplify sed escape function for special characters
- Enable interactive prompts when running via `curl | bash`
- Bulletproof the installer with better error handling
- Improve cross-platform compatibility (macOS/Linux/Windows)
- Correct hook format for Claude Code settings.json

### Added
- Initial release with Discord webhook notifications
- 5-minute inactivity timer before pinging
- Support for Stop, SubagentStop, UserPromptSubmit, and SessionStart hooks
- One-line install: `curl -fsSL https://raw.githubusercontent.com/omd-ai/gsd-notify/main/install.sh | bash`
