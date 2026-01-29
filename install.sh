#!/bin/bash
set -e

echo "gsd-notify installer"
echo "===================="
echo ""

# Prompt for webhook URL
read -p "Webhook URL: " WEBHOOK_URL
if [ -z "$WEBHOOK_URL" ]; then
    echo "Error: Webhook URL is required"
    exit 1
fi

# Prompt for Discord ID
read -p "Your Discord ID: " DISCORD_ID
if [ -z "$DISCORD_ID" ]; then
    echo "Error: Discord ID is required"
    exit 1
fi

# Create ~/.claude directory if it doesn't exist
mkdir -p ~/.claude

# Write the notification script
cat > ~/.claude/gsd-notify.sh << 'SCRIPT'
#!/bin/bash

WEBHOOK_URL="__WEBHOOK_URL__"
DISCORD_ID="__DISCORD_ID__"
PING_FILE="$HOME/.claude/.last_ping"
COOLDOWN=900  # 15 minutes in seconds

# Get current timestamp
NOW=$(date +%s)

# Check cooldown
if [ -f "$PING_FILE" ]; then
    LAST_PING=$(cat "$PING_FILE")
    ELAPSED=$((NOW - LAST_PING))
    if [ "$ELAPSED" -lt "$COOLDOWN" ]; then
        exit 0  # Still in cooldown, stay silent
    fi
fi

# Send ping (fail silently)
curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"<@$DISCORD_ID> It's time to GSD!\"}" \
    > /dev/null 2>&1 || true

# Update timestamp
echo "$NOW" > "$PING_FILE"
SCRIPT

# Replace placeholders with actual values
sed -i.bak "s|__WEBHOOK_URL__|$WEBHOOK_URL|g" ~/.claude/gsd-notify.sh
sed -i.bak "s|__DISCORD_ID__|$DISCORD_ID|g" ~/.claude/gsd-notify.sh
rm -f ~/.claude/gsd-notify.sh.bak

# Make executable
chmod +x ~/.claude/gsd-notify.sh

# Update settings.json with hooks
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOK_CMD="bash $HOME/.claude/gsd-notify.sh"

# Claude Code requires this nested hook structure:
# { "hooks": { "Stop": [{ "hooks": [{ "type": "command", "command": "..." }] }] } }

if [ -f "$SETTINGS_FILE" ]; then
    # File exists - need to merge hooks
    if command -v node &> /dev/null; then
        node -e "
const fs = require('fs');
const settings = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));

if (!settings.hooks) settings.hooks = {};

const hookEntry = {
    hooks: [{ type: 'command', command: '$HOOK_CMD' }]
};

// Helper to add hook
function addHook(hookName) {
    if (!settings.hooks[hookName]) {
        settings.hooks[hookName] = [];
    }
    // Remove old gsd-notify entries
    settings.hooks[hookName] = settings.hooks[hookName].filter(h => {
        if (h.hooks && Array.isArray(h.hooks)) {
            return !h.hooks.some(inner => inner.command && inner.command.includes('gsd-notify'));
        }
        return true;
    });
    // Add new entry
    settings.hooks[hookName].push(hookEntry);
}

addHook('Stop');
addHook('SubagentStop');

fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(settings, null, 2));
"
    else
        echo "Warning: Node.js not found. Creating fresh settings.json (existing settings will be lost)."
        cat > "$SETTINGS_FILE" << EOF
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "$HOOK_CMD" }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          { "type": "command", "command": "$HOOK_CMD" }
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
          { "type": "command", "command": "$HOOK_CMD" }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          { "type": "command", "command": "$HOOK_CMD" }
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

curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d @"$TEMP_JSON" \
    > /dev/null 2>&1

RESULT=$?
rm -f "$TEMP_JSON"

if [ $RESULT -eq 0 ]; then
    echo "Test ping sent! Check Discord."
    echo ""
    echo "Setup complete. You'll be pinged when Claude Code needs attention."
else
    echo "Warning: Test ping may have failed. Check your webhook URL."
fi
