#!/usr/bin/env bash
# rai setup — configure API keys for RAi Code
# Usage: ./setup.sh
set -euo pipefail

RAI_DIR="${RAI_CONFIG_DIR:-$HOME/.rai}"
AUTH_FILE="$RAI_DIR/auth.json"
SETTINGS_FILE="$RAI_DIR/settings.json"

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     RAi Code — Initial Setup         ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# 1. Create .rai directory
mkdir -p "$RAI_DIR"

# 2. Copy settings.json if not exists
if [ ! -f "$SETTINGS_FILE" ]; then
    cat > "$SETTINGS_FILE" <<'SETTINGS'
{
    "codebaseIndex": {
        "enabled": false
    },
    "permissions": {
        "defaultMode": "danger-full-access"
    }
}
SETTINGS
    echo "✓ Created $SETTINGS_FILE"
else
    echo "• $SETTINGS_FILE already exists, skipping"
fi

# 3. If auth.json already exists, ask before overwriting
if [ -f "$AUTH_FILE" ]; then
    echo ""
    echo "• $AUTH_FILE already exists."
    read -rp "  Overwrite? (y/N): " OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo "  Skipped auth config."
        echo ""
        echo "Setup complete. Run 'rai doctor' to verify."
        exit 0
    fi
fi

# 4. Provider selection
echo ""
echo "Select your AI provider:"
echo ""
echo "  1) Anthropic (Claude)        — ANTHROPIC_API_KEY"
echo "  2) OpenAI (GPT)              — OPENAI_API_KEY"
echo "  3) Google (Gemini)           — GEMINI_API_KEY"
echo "  4) DeepSeek                  — DEEPSEEK_API_KEY"
echo "  5) Groq                      — GROQ_API_KEY"
echo "  6) OpenRouter                — OPENROUTER_API_KEY"
echo "  7) xAI (Grok)               — XAI_API_KEY"
echo "  8) NVIDIA                    — NVIDIA_API_KEY"
echo "  9) DeepInfra                 — DEEPINFRA_API_KEY"
echo " 10) MiniMax                   — MINIMAX_API_KEY"
echo " 11) Xiaomi                    — XIAOMI_API_KEY"
echo " 12) Custom (enter key name)"
echo ""

read -rp "Choice [1-12]: " CHOICE

declare -A KEY_MAP=(
    [1]="ANTHROPIC_API_KEY"
    [2]="OPENAI_API_KEY"
    [3]="GEMINI_API_KEY"
    [4]="DEEPSEEK_API_KEY"
    [5]="GROQ_API_KEY"
    [6]="OPENROUTER_API_KEY"
    [7]="XAI_API_KEY"
    [8]="NVIDIA_API_KEY"
    [9]="DEEPINFRA_API_KEY"
    [10]="MINIMAX_API_KEY"
    [11]="XIAOMI_API_KEY"
)

if [ "$CHOICE" = "12" ]; then
    read -rp "Enter API key env var name (e.g. MY_API_KEY): " CUSTOM_KEY
    KEY_NAME="$CUSTOM_KEY"
elif [[ -n "${KEY_MAP[$CHOICE]+x}" ]]; then
    KEY_NAME="${KEY_MAP[$CHOICE]}"
else
    echo "Invalid choice."
    exit 1
fi

echo ""
read -rp "Enter your API key for $KEY_NAME: " API_KEY

if [ -z "$API_KEY" ]; then
    echo "Error: API key cannot be empty."
    exit 1
fi

# 5. Generate auth.json with ALL provider keys (empty except selected one)
cat > "$AUTH_FILE" <<EOF
{
  "DEEPSEEK_API_KEY": "",
  "OPENAI_API_KEY": "",
  "GEMINI_API_KEY": "",
  "OPENROUTER_API_KEY": "",
  "DEEPINFRA_API_KEY": "",
  "XIAOMI_API_KEY": "",
  "MINIMAX_API_KEY": "",
  "XAI_API_KEY": "",
  "GROQ_API_KEY": "",
  "NVIDIA_API_KEY": "",
  "ANTHROPIC_API_KEY": ""
}
EOF

# 6. Use a temp file to inject the actual key value
# (sed can't handle all key patterns safely, so we use a small Python/Node or awk)
if command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('$AUTH_FILE') as f:
    data = json.load(f)
data['$KEY_NAME'] = '''$API_KEY'''
with open('$AUTH_FILE', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
elif command -v python &>/dev/null; then
    python -c "
import json
with open('$AUTH_FILE') as f:
    data = json.load(f)
data['$KEY_NAME'] = '''$API_KEY'''
with open('$AUTH_FILE', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
else
    # Fallback: simple sed replacement (works for most API key formats)
    # Escape special chars for sed
    ESCAPED_KEY=$(printf '%s\n' "$API_KEY" | sed 's/[&/\]/\\&/g')
    sed -i.bak "s/\"$KEY_NAME\": \"\"/\"$KEY_NAME\": \"$ESCAPED_KEY\"/" "$AUTH_FILE"
    rm -f "$AUTH_FILE.bak"
fi

echo ""
echo "✓ Created $AUTH_FILE"
echo "✓ API key configured: $KEY_NAME"
echo ""
echo "Setup complete! Run 'rai doctor' to verify your configuration."
echo ""
