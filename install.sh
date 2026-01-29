#!/usr/bin/env bash
set -e

# Ensure we're running in bash, not sh
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires bash. Run with: bash install.sh"
    exit 1
fi

echo "gsd-notify installer"
echo "===================="
echo ""

# When running via "curl | bash", stdin is the script, not the terminal.
# We must read from /dev/tty to get user input.
if [ ! -t 0 ]; then
    # stdin is not a terminal (likely piped from curl)
    exec < /dev/tty
fi

# Prompt for webhook URL
read -p "Webhook URL: " WEBHOOK_URL
if [ -z "$WEBHOOK_URL" ]; then
    echo "Error: Webhook URL is required"
    exit 1
fi

# Validate webhook URL format
if [[ ! "$WEBHOOK_URL" =~ ^https://discord(app)?\.com/api/webhooks/ ]]; then
    echo "Error: Invalid webhook URL. Should start with https://discord.com/api/webhooks/"
    exit 1
fi

# Prompt for Discord ID
read -p "Your Discord ID: " DISCORD_ID
if [ -z "$DISCORD_ID" ]; then
    echo "Error: Discord ID is required"
    exit 1
fi

# Validate Discord ID is numeric
if [[ ! "$DISCORD_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: Discord ID should be a number (e.g., 123456789012345678)"
    exit 1
fi

# Determine the correct home path
# On Windows Git Bash, $HOME is /c/Users/... but we need C:/Users/... for Claude Code
get_claude_path() {
    local unix_path="$1"
    # Check if we're in Git Bash/MSYS on Windows
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin" ]]; then
        # Convert /c/Users/... to C:/Users/...
        echo "$unix_path" | sed 's|^/\([a-zA-Z]\)/|\1:/|'
    else
        echo "$unix_path"
    fi
}

CLAUDE_DIR="$HOME/.claude"
CLAUDE_DIR_FOR_HOOK=$(get_claude_path "$CLAUDE_DIR")

# Create ~/.claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Clean up old files from previous versions
rm -f "$CLAUDE_DIR/.last_ping" 2>/dev/null

# Write the notification script (called by delayed check)
cat > "$CLAUDE_DIR/gsd-notify.sh" << 'SCRIPT'
#!/usr/bin/env bash

WEBHOOK_URL="__WEBHOOK_URL__"
DISCORD_ID="__DISCORD_ID__"
WAIT_FILE="$HOME/.claude/.waiting_since"
NOTIFIED_FILE="$HOME/.claude/.notified"
DELAY=300  # 5 minutes in seconds

# If no wait file, user already responded - exit silently
[ ! -f "$WAIT_FILE" ] && exit 0

# If already notified for this wait period, exit silently
[ -f "$NOTIFIED_FILE" ] && exit 0

# Check if we've been waiting long enough
NOW=$(date +%s)
WAIT_START=$(cat "$WAIT_FILE" 2>/dev/null || echo "0")
if [[ "$WAIT_START" =~ ^[0-9]+$ ]]; then
    ELAPSED=$((NOW - WAIT_START))
    if [ "$ELAPSED" -lt "$DELAY" ]; then
        exit 0  # Not long enough yet
    fi
fi

# Send ping (fail silently)
curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"<@$DISCORD_ID> It's time to GSD!\"}" \
    > /dev/null 2>&1 || true

# Mark as notified (so we don't ping again until user responds)
touch "$NOTIFIED_FILE"
SCRIPT

# Write the wait-start script (called on Stop)
cat > "$CLAUDE_DIR/gsd-wait.sh" << 'SCRIPT'
#!/usr/bin/env bash

WAIT_FILE="$HOME/.claude/.waiting_since"
NOTIFY_SCRIPT="$HOME/.claude/gsd-notify.sh"

# Always update timestamp to most recent stop
# (SubagentStop may fire before main agent finishes)
date +%s > "$WAIT_FILE"

# Spawn delayed notification check (5 min + small buffer)
(sleep 305 && bash "$NOTIFY_SCRIPT") &
SCRIPT

# Write the activity script (called on user input - clears wait state)
cat > "$CLAUDE_DIR/gsd-activity.sh" << 'SCRIPT'
#!/usr/bin/env bash

# User is active - clear wait state
rm -f "$HOME/.claude/.waiting_since" 2>/dev/null
rm -f "$HOME/.claude/.notified" 2>/dev/null
SCRIPT

# Escape & for sed replacement (& means "matched pattern" in sed)
# Discord URLs and numeric IDs won't have other special chars
escape_for_sed() {
    printf '%s' "$1" | sed 's/&/\\&/g'
}

WEBHOOK_ESCAPED=$(escape_for_sed "$WEBHOOK_URL")
DISCORD_ESCAPED=$(escape_for_sed "$DISCORD_ID")

# Cross-platform sed -i (macOS vs Linux)
sed_inplace() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Replace placeholders with actual values
sed_inplace "s|__WEBHOOK_URL__|$WEBHOOK_ESCAPED|g" "$CLAUDE_DIR/gsd-notify.sh"
sed_inplace "s|__DISCORD_ID__|$DISCORD_ESCAPED|g" "$CLAUDE_DIR/gsd-notify.sh"

# Make all scripts executable
chmod +x "$CLAUDE_DIR/gsd-notify.sh"
chmod +x "$CLAUDE_DIR/gsd-wait.sh"
chmod +x "$CLAUDE_DIR/gsd-activity.sh"

# Update settings.json with hooks
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Claude Code requires this nested hook structure:
# { "hooks": { "Stop": [{ "hooks": [{ "type": "command", "command": "..." }] }] } }

if [ -f "$SETTINGS_FILE" ]; then
    # File exists - need to merge hooks
    if command -v node &> /dev/null; then
        # Try to parse and merge, fall back to fresh file if JSON is corrupt
        if node -e "
const fs = require('fs');
let settings;
try {
    settings = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));
} catch (e) {
    console.error('Warning: Existing settings.json is corrupt, creating fresh file.');
    settings = {};
}

if (!settings.hooks) settings.hooks = {};

// Helper to add hook
function addHook(hookName, scriptName) {
    const hookEntry = {
        hooks: [{ type: 'command', command: 'bash \"$CLAUDE_DIR_FOR_HOOK/' + scriptName + '\"' }]
    };
    if (!settings.hooks[hookName]) {
        settings.hooks[hookName] = [];
    }
    // Remove old gsd- entries for this hook
    settings.hooks[hookName] = settings.hooks[hookName].filter(h => {
        if (h.hooks && Array.isArray(h.hooks)) {
            return !h.hooks.some(inner => inner.command && inner.command.includes('gsd-'));
        }
        return true;
    });
    // Add new entry
    settings.hooks[hookName].push(hookEntry);
}

// Stop/SubagentStop: start the 5-min timer
addHook('Stop', 'gsd-wait.sh');
addHook('SubagentStop', 'gsd-wait.sh');

// User input: clear the timer (user is active)
addHook('UserPromptSubmit', 'gsd-activity.sh');

// Session start: clear stale files from previous sessions
addHook('SessionStart', 'gsd-activity.sh');

fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(settings, null, 2));
" 2>&1; then
            : # Success
        else
            echo "Warning: Failed to update settings.json with Node.js."
        fi
    else
        echo "Warning: Node.js not found. Creating fresh settings.json (existing settings will be lost)."
        cat > "$SETTINGS_FILE" << EOF
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_DIR_FOR_HOOK/gsd-wait.sh\"" }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_DIR_FOR_HOOK/gsd-wait.sh\"" }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_DIR_FOR_HOOK/gsd-activity.sh\"" }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_DIR_FOR_HOOK/gsd-activity.sh\"" }
        ]
      }
    ]
  }
}
EOF
    fi
else
    # Create new settings file
    cat > "$SETTINGS_FILE" << EOF
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_DIR_FOR_HOOK/gsd-wait.sh\"" }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_DIR_FOR_HOOK/gsd-wait.sh\"" }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_DIR_FOR_HOOK/gsd-activity.sh\"" }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_DIR_FOR_HOOK/gsd-activity.sh\"" }
        ]
      }
    ]
  }
}
EOF
fi

echo ""
echo "Sending test ping..."

# Send test ping using a temp file to avoid escaping issues
TEMP_JSON=$(mktemp)
cat > "$TEMP_JSON" << EOF
{"content": "<@$DISCORD_ID> It's time to GSD!"}
EOF

# Disable set -e for curl so we can handle errors gracefully
set +e
curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d @"$TEMP_JSON" \
    > /dev/null 2>&1
RESULT=$?
set -e

rm -f "$TEMP_JSON"

if [ $RESULT -eq 0 ]; then
    echo "Test ping sent! Check Discord."
    echo ""
    echo "Setup complete. You'll be pinged when Claude Code needs attention."
else
    echo "Warning: Test ping may have failed (network error). Check your webhook URL."
fi
