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
HOOK_CMD="$HOME/.claude/gsd-notify.sh"

if [ -f "$SETTINGS_FILE" ]; then
    # File exists - need to merge hooks
    TEMP_FILE=$(mktemp)

    # Use node if available, otherwise use basic approach
    if command -v node &> /dev/null; then
        node -e "
const fs = require('fs');
const settings = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));

if (!settings.hooks) settings.hooks = {};

// Helper to add hook if not present
function addHook(hookName) {
    if (!settings.hooks[hookName]) settings.hooks[hookName] = [];
    if (!Array.isArray(settings.hooks[hookName])) {
        settings.hooks[hookName] = [settings.hooks[hookName]];
    }
    // Remove old gsd-notify entries and add fresh one
    settings.hooks[hookName] = settings.hooks[hookName].filter(h => !h.includes('gsd-notify'));
    settings.hooks[hookName].push('$HOOK_CMD');
}

addHook('Stop');
addHook('SubagentStop');

fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(settings, null, 2));
"
    else
        # Fallback: create fresh settings with just hooks
        cat > "$SETTINGS_FILE" << EOF
{
  "hooks": {
    "Stop": ["$HOOK_CMD"],
    "SubagentStop": ["$HOOK_CMD"]
  }
}
EOF
    fi
else
    # Create new settings file
    cat > "$SETTINGS_FILE" << EOF
{
  "hooks": {
    "Stop": ["$HOOK_CMD"],
    "SubagentStop": ["$HOOK_CMD"]
  }
}
EOF
fi

echo ""
echo "Sending test ping..."

# Send test ping
curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"<@$DISCORD_ID> It's time to GSD!\"}" \
    > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Test ping sent! Check Discord."
    echo ""
    echo "Setup complete. You'll be pinged when Claude Code needs attention."
else
    echo "Warning: Test ping may have failed. Check your webhook URL."
fi
