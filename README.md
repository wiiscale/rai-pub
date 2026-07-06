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

After installing, you need an **auth config** file to connect to an AI provider.

1. Download the auth config template:
   **[Google Drive — rai auth config](https://drive.google.com/drive/folders/1B9XbMIrUJ_WhE_YKbTlZMFWrnQ0L9e7W?usp=drive_link)**

2. Place it at `~/.rai/auth.json`:
   ```bash
   mkdir -p ~/.rai
   # Copy the downloaded auth.json to ~/.rai/auth.json
   cp ~/Downloads/auth.json ~/.rai/auth.json
   ```

3. Edit `~/.rai/auth.json` and fill in your API key:
   ```json
   {
     "provider": "anthropic",
     "api_key": "sk-ant-..."
   }
   ```

4. Verify your setup:
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

- **Auth config template:** [Google Drive](https://drive.google.com/drive/folders/1B9XbMIrUJ_WhE_YKbTlZMFWrnQ0L9e7W?usp=drive_link)
- **Releases:** [GitHub Releases](https://github.com/wiiscale/rai-pub/releases)
