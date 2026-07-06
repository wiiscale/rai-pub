# RAi Code

AI-powered coding assistant — CLI agent for developers.

> **One command to install. Works on macOS, Linux, Windows.**

## Quick Install

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.ps1 | iex
```

### Windows (CMD)

```cmd
curl -fsSL https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.cmd -o install.cmd && install.cmd
```

### Install specific version

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.sh | bash -s -- --version v0.1.2

# PowerShell
irm https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.ps1 | iex -Version v0.1.2
```

### Custom install directory

```bash
RAI_INSTALL_DIR=/usr/local/bin curl -fsSL https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.sh | bash
```

Default install location: `~/.local/bin/rai` (macOS/Linux) or `%LOCALAPPDATA%\rai\rai.exe` (Windows).

> **Note:** Make sure `~/.local/bin` is in your `PATH`. Add this to your shell profile if needed:
> ```bash
> export PATH="$HOME/.local/bin:$PATH"
> ```

---

## Initial Setup

After installing, run the setup script to configure your API key:

```bash
curl -fsSL https://raw.githubusercontent.com/wiiscale/rai-pub/main/setup.sh | bash
```

The script will:
1. Create `~/.rai/` directory
2. Generate `~/.rai/settings.json` with default config
3. Let you select an AI provider and enter your API key
4. Generate `~/.rai/auth.json` with your key

**Supported providers:** Anthropic, OpenAI, Google Gemini, DeepSeek, Groq, OpenRouter, xAI, NVIDIA, DeepInfra, MiniMax, Xiaomi

### Manual setup (alternative)

If you prefer to configure manually:

```bash
mkdir -p ~/.rai
```

Create `~/.rai/auth.json`:
```json
{
  "DEEPSEEK_API_KEY": "YOUR_DEEPSEEK_API_KEY",
  "OPENAI_API_KEY": "YOUR_OPENAI_API_KEY",
  "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY",
  "OPENROUTER_API_KEY": "YOUR_OPENROUTER_API_KEY",
  "DEEPINFRA_API_KEY": "YOUR_DEEPINFRA_API_KEY",
  "XIAOMI_API_KEY": "YOUR_XIAOMI_API_KEY",
  "MINIMAX_API_KEY": "YOUR_MINIMAX_API_KEY",
  "XAI_API_KEY": "YOUR_XAI_API_KEY",
  "GROQ_API_KEY": "YOUR_GROQ_API_KEY",
  "NVIDIA_API_KEY": "YOUR_NVIDIA_API_KEY",
  "ANTHROPIC_API_KEY": "YOUR_ANTHROPIC_API_KEY"
}
```

> Fill in the key for your provider. See `docker/rai-config/auth.json.example` for all available keys.

Create `~/.rai/settings.json`:
```json
{
    "codebaseIndex":{
        "enabled":false,
        "chunk_max_chars":1200,
        "chunk_min_chars":80,
        "collection_name":"rai-codebase",
        "embedding_batch_size":100,
        "qdrant_api_key":"",
        "qdrant_url":"",
        "search_max_results":8,
        "search_min_score":0.4,
        "provider_configs":{
            "openai":{"model":"text-embedding-3-small","primary":false},
            "gemini":{"model":"gemini-embedding-001","primary":true}
        }
    },
    "companion":{"hatchedAt":10,"name":"Mochi","personality":"playful","species":"cat"},
    "companionMuted":false,
    "defaultModel":"deepseek-v4-pro",
    "permissions":{"defaultMode":"danger-full-access"},
    "userID":""
}
```

### Verify setup

```bash
rai doctor
```

---

## Quick Start

```bash
rai                    # Start interactive REPL
rai doctor             # Check environment & dependencies
rai --update           # Check for and install updates
rai --help             # Show all CLI options
```

### One-shot prompts (non-interactive)

```bash
rai prompt "explain this code"               # Run a single prompt
rai prompt "fix the failing test" --headless  # Headless mode (for CI/scripts)
```

### Common slash commands (inside REPL)

| Command | Description |
|---------|-------------|
| `/help` | Show all commands |
| `/model` | Switch AI model |
| `/compact` | Compress conversation to save tokens |
| `/memory` | View/manage long-term memory |
| `/session` | Manage sessions |
| `/update` | Check for updates |
| `/doctor` | Health check |
| `/clear` | Clear current conversation |
| `/undo` | Undo last tool operation |

### Keyboard shortcuts

| Key | Action |
|-----|--------|
| `Enter` | Send message |
| `Shift+Enter` | New line (multi-line) |
| `Ctrl+C` (1st) | Cancel current turn |
| `Ctrl+C` (2nd) | Exit REPL |
| `Tab` | Accept autocomplete |
| `Shift+Tab` | Switch Plan ↔ Agent mode |
| `Esc` | Cancel turn |

---

## Update

```bash
rai --update    # Downloads and installs latest version
```

Inside REPL:
```
/update
```

Both methods download the latest release binary from this public mirror — no authentication required.

---

## Supported Platforms

| Platform | Architecture | Status |
|----------|-------------|--------|
| Linux | x86_64 | ✅ |
| macOS | Apple Silicon (arm64) | ✅ |
| macOS | Intel (x86_64) | ✅ |
| Windows | x86_64 | ✅ |

---

## Troubleshooting

### `rai: command not found`

Add `~/.local/bin` to your PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### `rai doctor` reports issues

Run `rai doctor` to check:
- API key configured correctly
- Network connectivity
- Required dependencies

### Update fails

Make sure `gh` CLI is installed:
```bash
# macOS
brew install gh

# Linux (Debian/Ubuntu)
apt install gh

# Windows
choco install gh
```

---

## Links

- **Releases:** [GitHub Releases](https://github.com/wiiscale/rai-pub/releases)
