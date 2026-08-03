# RAi Code

<p align="center">
  <img src="https://raw.githubusercontent.com/wiiscale/rai-pub/main/assets/logo.png" alt="RAi Logo" width="200">
</p>

**Reasonary AI Code** — a terminal-based AI coding agent with full tool access.

[![Release](https://img.shields.io/github/v/release/wiiscale/rai-pub?label=latest)](https://github.com/wiiscale/rai-pub/releases)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE.md)

RAi is an AI coding assistant that runs in your terminal. It connects to LLMs and gives them tools to read, write, and execute code — supporting multiple providers and integrating with LSPs for code intelligence.

---

## Features

- **Multi-Model** — choose from a wide range of LLMs or add your own via OpenAI- or Anthropic-compatible APIs
- **Flexible** — switch LLMs mid-session while preserving context
- **Session-Based** — maintain multiple work sessions and contexts per project
- **LSP-Enhanced** — RAi uses LSPs for additional context, just like you do
- **Extensible** — add capabilities via MCPs (`http`, `stdio`, and `sse`), agent skills, hooks, and custom commands
- **Headless Runner** — run RAi non-interactively for CI/CD, super-agents, and scripted workflows
- **Reasoning Control** — steer effort levels or thinking with one key (`ctrl+e`) or one CLI flag (`--reasoning`), with automatic clamping to each model's capabilities
- **Cost-Aware Output** — every headless run reports token usage and estimated USD cost in its result
- **Cross-Platform** — macOS, Linux, Windows (PowerShell & WSL), FreeBSD, OpenBSD, NetBSD

---

## Installation

### Via curl (macOS / Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.sh | bash
```

### Via PowerShell (Windows)

```powershell
irm https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.ps1 | iex
```

### Via CMD (Windows)

```cmd
powershell -c "irm https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.ps1 | iex"
```

### Manual download

Pre-built binaries for all platforms: [GitHub Releases](https://github.com/wiiscale/rai-pub/releases)

SHA256 checksums are included with every release. Installer scripts automatically verify the checksum.

---

## Quick Start

```bash
# Start interactive session
rai

# One-shot prompt (non-interactive)
rai run "Explain this codebase to me"
```

On first run, RAi walks you through provider setup. Press <kbd>ctrl+m</kbd> at any time to open the model picker, choose your provider, and paste your API key.

---

## API Keys

You can also set environment variables for preferred providers:

| Variable | Provider |
|----------|----------|
| `ANTHROPIC_API_KEY` | Anthropic |
| `OPENAI_API_KEY` | OpenAI |
| `GEMINI_API_KEY` | Google Gemini |
| `VERCEL_API_KEY` | Vercel AI Gateway |
| `ZAI_API_KEY` | Z.ai |
| `MINIMAX_API_KEY` | MiniMax |
| `HF_TOKEN` | Hugging Face Inference |
| `CEREBRAS_API_KEY` | Cerebras |
| `OPENROUTER_API_KEY` | OpenRouter |
| `GROQ_API_KEY` | Groq |
| `MOONSHOT_API_KEY` | Moonshot |
| `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` | Amazon Bedrock |
| `VERTEXAI_PROJECT` + `VERTEXAI_LOCATION` | Google Cloud VertexAI |
| `AZURE_OPENAI_API_KEY` + `AZURE_OPENAI_API_ENDPOINT` | Azure OpenAI |
| `SYNTHETIC_API_KEY` | Synthetic |
| `ALIBABA_SINGAPORE_API_KEY` | Alibaba (Singapore) |
| `ALIBABA_US_API_KEY` | Alibaba (United States) |

RAi supports nearly any provider, including local models. See [Custom Providers](#custom-providers) below.

---

## Agent Runner (Headless / Non-Interactive)

RAi can run headlessly — perfect for super-agents, CI/CD pipelines, and scripted workflows. In headless mode, all permissions are automatically approved and interactive-only tools are disabled.

### `rai run` — Single prompt

```bash
# Basic prompt
rai run "Fix the lint errors in this project"

# Pipe input from stdin
curl https://code.reasonary.ai | rai run "Summarize this website"

# Read from a file
rai run "What is this code doing?" < code.go

# Redirect output to a file
rai run "Generate a README" > README.md

# Run in quiet mode (no spinner)
rai run --quiet "Generate test stubs for all packages"

# Run in verbose mode (show internal logs)
rai run --verbose "Debug the failing integration test"
```

### Model selection

```bash
# Use a specific large model
rai run --model "Claude Opus 4.1" "Design the architecture"

# Use a specific small model (for tool-to-agent routing)
rai run --small-model "Claude Haiku 4.1" "Review this diff"

# Override both
rai run --model "gpt-5.2" --small-model "gpt-oss-120b" "Refactor this module"
```

### Reasoning control

Super-agents can steer the model's reasoning with one flag — an effort level or a thinking toggle:

```bash
# Request an effort level (clamped to the model's supported levels)
rai run --reasoning high "Design the architecture"

# Disable reasoning
rai run --reasoning none "Quick factual question"

# Toggle thinking on/off (models without effort levels)
rai run --reasoning on "Solve this step by step"
```

Effort requests are **clamped** to the closest supported level of the actual
model — `--reasoning low` on a model that only supports `[high, max]` uses
`high`, and the clamp is reported in the result. Requests the model cannot
satisfy at all (effort on a toggle-only model, thinking on an effort model,
reasoning on a non-reasoning model) fail with a clear error so super-agents
never get silent behavior changes.

In interactive mode, <kbd>ctrl+e</kbd> cycles the reasoning control: effort
models advance through their levels, toggle-only models flip thinking.

### Structured JSONL output

For super-agents and CI/CD, use `--output-format json` for JSONL streaming:

```bash
# JSONL streaming (one JSON object per line)
rai run --output-format json "Explain the architecture"

# Pipe to file for later processing
rai run --output-format json "Generate tests" > result.jsonl
```

Each line is a standalone JSON object:

```jsonl
{"type":"thinking","text":"Analyzing the codebase..."}
{"type":"text","text":"Here's the overview..."}
{"type":"tool_use","id":"t1","name":"bash","input":{"command":"ls"}}
{"type":"tool_result","tool_use_id":"t1","tool_name":"bash","output":"...","is_error":false}
{"type":"result","session_id":"ses_xxx","status":"completed","usage":{"input_tokens":14965,"output_tokens":3},"cost_usd":0.00001904,"model_id":"deepseek-v4-flash","provider_id":"deepseek","duration_ms":949}
```

| Event type | Description |
|-----------|-------------|
| `text` | Coalesced assistant text |
| `thinking` | Coalesced reasoning block |
| `tool_use` | Tool invocation with parsed JSON input |
| `tool_result` | Tool execution result |
| `error` | Error event |
| `result` | Terminal event with session_id |

The `result` event carries a usage/cost summary for super-agents to report
back accurate figures: `usage` (`input_tokens`/`output_tokens`), `cost_usd`
(estimated from model.dev pricing), `model_id`/`provider_id`, `duration_ms`,
and `warning` (e.g. reasoning effort clamps). Text mode prints the same
summary as a footer line:

```
── 14978 in / 47 out, $0.000015, 1.5s · deepseek-v4-flash ──
```

Text/thinking deltas are coalesced. Tool calls pass through one-for-one.

### Inline settings override

Override any config value at runtime via `--settings` (highest precedence, above all file-based config):

```bash
# Override permission mode
rai run --settings '{"permission_mode":"accept_all"}' "Refactor this module"

# Enable debug logging for this run
rai run --settings '{"options":{"debug":true}}' "Debug the failing test"
```

### Custom system prompt

Inject persona or policy instructions into the model's system prompt via `--append-system-prompt`:

```bash
# Persona injection
rai run --append-system-prompt "You are a senior Rust engineer. Be terse." "Review this PR"

# Policy enforcement
rai run --append-system-prompt "Never modify *.env files. Always use conventional commits." "Refactor auth"
```

### Session management

Sessions persist between runs. Use session flags to continue conversations:

```bash
# Create a new session (returns session ID on stderr)
rai run --session-name "refactor-auth" "Start refactoring the auth module"
# # session: ses_abc123

# Continue a specific session by ID
rai run --session ses_abc123 "Continue the refactoring"

# Continue the most recent session
rai run --continue "Pick up where we left off"
rai run -C "Short flag for continue"

# List all sessions
rai sessions
```

### Session ID in output

Headless runs print the session ID to **stderr** before the agent output begins:

```
# session: ses_abc123

(agent output on stdout...)
```

Super-agents can capture the session ID from stderr for later continuation:
```bash
SESSION_ID=$(rai run --session-name "ci-review" "Review this PR" 2>&1 | grep '^# session:' | awk '{print $3}')
# ... do other work ...
rai run --session "$SESSION_ID" "Apply the fix you suggested"
```

### Exit codes

- **0** — Success (agent completed the task)
- **>0** — Error (check stderr for details)

### Agent-as-a-Tool for Super-Agents

RAi is designed to be invoked programmatically by a **super-agent** (another AI running in a parent process):

```bash
# Super-agent calls RAi as a sub-agent for code generation
rai run --model "Claude Haiku 4.1" --quiet "Fix the type errors in src/auth/login.ts"

# Super-agent pipes diff context
git diff HEAD~1 | rai run --quiet "Review this diff for security issues"

# Super-agent chains multiple sessions
SESSION=$(rai run --session-name "ci-fix" --quiet "Fix the failing tests" 2>&1 | tail -1 | awk '{print $NF}')
rai run --session "$SESSION" --quiet "Did that resolve the CI failure?"
```

### How it works

1. `rai run` starts the agent in non-interactive mode
2. Interactive-only tools (question prompts) are disabled
3. All permissions are auto-approved — no human-in-the-loop
4. Agent output streams to stdout; session metadata to stderr
5. The process exits with the agent's completion status

### Security model

In headless mode, **all permissions are auto-approved**. The agent executes autonomously.

For **interactive mode** (`rai` without `run`), RAi offers fine-grained permission control:

| Mode | Behavior |
|------|----------|
| `AcceptEdits` | Auto-approve edit/write tools. Ask for everything else |
| `AcceptAll` | Auto-approve everything. No prompts |
| `Prompt` | Ask for every action |

Set via <kbd>ctrl+p</kbd> in interactive mode, or configure in `rai.json`:

```json
{
  "options": {
    "permission_mode": "accept_edits"
  }
}
```

You can also allowlist specific tools:

```json
{
  "permissions": {
    "allowed_tools": ["view", "ls", "grep", "edit"]
  }
}
```

---

## Configuration

RAi runs great with no configuration. Customization is stored as JSON:

```json
{
  "option-name": "value",
  "another-option": ["array", "of", "values"]
}
```

### Priority (highest to lowest)

1. `.rai.json` (hidden project config)
2. `rai.json` (visible project config)
3. `~/.rai/rai.json` (global config)

Application data is stored at:
- **Unix**: `~/.local/share/rai/`
- **Windows**: `%LOCALAPPDATA%\rai\`

You can override locations via `RAI_GLOBAL_CONFIG` and `RAI_GLOBAL_DATA`.

### Global context files

RAi automatically includes two files for cross-project instructions:
- `~/.rai/RAI.md` — RAi-specific rules
- `~/.rai/AGENTS.md` — generic instructions shared with other coding tools

Customize paths:
```json
{
  "options": {
    "global_context_paths": [
      "~/path/to/custom/file.md",
      "/full/path/to/folder/"
    ]
  }
}
```

### Ignoring files

RAi respects `.gitignore` by default. Create a `.raiignore` file (same syntax as `.gitignore`) to exclude additional files from context.

### Disabling built-in tools

```json
{
  "options": {
    "disabled_tools": ["bash", "sourcegraph"]
  }
}
```

### Disabling skills

```json
{
  "options": {
    "disabled_skills": ["rai-config"]
  }
}
```

---

## LSP Integration

RAi can use LSPs for code intelligence (diagnostics, references, completions):

```json
{
  "lsp": {
    "gopls": { "command": "gopls" },
    "rust-analyzer": { "command": "rust-analyzer" },
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"]
    },
    "nix": { "command": "nil" }
  }
}
```

RAi auto-discovers LSP servers based on project root markers (e.g., `go.mod` → gopls, `Cargo.toml` → rust-analyzer).

---

## MCP Servers

RAi supports Model Context Protocol (MCP) servers through `stdio`, `http`, and `sse` transports.

Shell-style expansion (`$VAR`, `${VAR:-default}`, `$(command)`) works in `command`, `args`, `env`, `headers`, and `url`:

```json
{
  "mcp": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/dir"],
      "timeout": 120
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "timeout": 120,
      "headers": {
        "Authorization": "Bearer $GH_PAT"
      },
      "disabled_tools": ["create_issue"]
    },
    "streaming": {
      "type": "sse",
      "url": "https://example.com/mcp/sse",
      "headers": {
        "API-Key": "$(echo $API_KEY)"
      }
    }
  }
}
```

> **Security note:** `rai.json` is trusted code. Any `$(...)` in it runs at load time with your shell's privileges. Don't launch RAi in a directory whose `rai.json` you haven't reviewed.

---

## Hooks

Hooks run shell commands before tool execution. Define in `rai.json`:

```json
{
  "hooks": {
    "write": [
      { "command": "gofumpt -w {{.Path}}" }
    ],
    "bash": [
      {
        "command": "./scripts/guard.sh {{.Command}}",
        "timeout": "5s"
      }
    ]
  }
}
```

For details, see [hooks documentation](./docs/hooks/).

---

## Agent Skills

RAi supports the [Agent Skills](https://agentskills.io) open standard. Skills are folders containing a `SKILL.md` file:

```bash
# Global skills
mkdir -p ~/.rai/skills

# Project skills
mkdir -p .rai/skills
```

RAi discovers skills from (priority order, highest first):

**Global:**
- `~/.rai/skills/`
- `~/.agents/skills/`
- `~/.claude/skills/`
- `~/.cursor/skills/`
- `~/.codex/skills/`

**Project:**
- `.rai/skills/`
- `.agents/skills/`
- `.claude/skills/`
- `.cursor/skills/`
- `.codex/skills/`

Additional paths via `options.skills_paths`.

### User-invocable skills

Add `user-invocable: true` to the skill's YAML frontmatter to make it available from the command palette:

```yaml
---
name: my-skill
description: Review a pull request for common issues
user-invocable: true
---
```

### Getting started

```bash
mkdir -p ~/.rai/skills
cd ~/.rai/skills
git clone https://github.com/anthropics/skills.git _temp
mv _temp/skills/* . && rm -rf _temp
```

---

## Custom Commands

Commands are reusable prompts discovered from:

```
~/.rai/commands/    ← global
.rai/commands/      ← project
```

Create a command:
```markdown
# Review PR
You are a code reviewer. Analyze the diff for bugs, security issues,
and code smells. Suggest improvements and highlight good patterns.
```

Invoke from the command palette (<kbd>ctrl+p</kbd>).

---

## Logging

Logs are stored in `.rai/logs/rai.log` relative to the project:

```bash
# Last 1000 lines
rai logs

# Last 500 lines
rai logs --tail 500

# Follow in real time
rai logs --follow
```

Enable debug logging:
```json
{ "options": { "debug": true, "debug_lsp": true } }
```

---

## Custom Providers

### OpenAI-compatible

```json
{
  "providers": {
    "deepseek": {
      "type": "openai-compat",
      "base_url": "https://api.deepseek.com/v1",
      "api_key": "$DEEPSEEK_API_KEY",
      "models": [
        {
          "id": "deepseek-chat",
          "name": "Deepseek V3",
          "cost_per_1m_in": 0.27,
          "cost_per_1m_out": 1.1,
          "cost_per_1m_in_cached": 0.07,
          "context_window": 64000,
          "default_max_tokens": 5000
        }
      ]
    }
  }
}
```

### Anthropic-compatible

```json
{
  "providers": {
    "custom-anthropic": {
      "type": "anthropic",
      "base_url": "https://api.anthropic.com/v1",
      "api_key": "$ANTHROPIC_API_KEY",
      "models": [
        {
          "id": "claude-sonnet-4-20250514",
          "name": "Claude Sonnet 4",
          "cost_per_1m_in": 3,
          "cost_per_1m_out": 15,
          "context_window": 200000,
          "default_max_tokens": 50000,
          "can_reason": true,
          "supports_attachments": true
        }
      ]
    }
  }
}
```

### Local models

RAi auto-discovers models from Ollama, llama.cpp, LM Studio, LiteLLM, and OMLX:

```json
{
  "providers": {
    "ollama": {
      "type": "ollama",
      "base_url": "http://localhost:11434/v1/"
    }
  }
}
```

---

## Provider auto-updates

By default, RAi auto-checks for the latest provider/models list. Disable with:

```json
{ "options": { "disable_provider_auto_update": true } }
```

Or: `export RAI_DISABLE_PROVIDER_AUTO_UPDATE=1`

Manually update:
```bash
rai update-providers                # from Catwalk
rai update-providers embedded       # reset to built-in
```

---

## Metrics

RAi records pseudonymous usage metrics (device hash, no prompts/responses collected). Opt out:

```bash
export RAI_DISABLE_METRICS=1
```

Or configure: `{ "options": { "disable_metrics": true } }`

RAi also respects `DO_NOT_TRACK=1`.

---

## Shell completions

```bash
# Bash:   source <(rai completion bash)
# Zsh:    source <(rai completion zsh)
# Fish:   rai completion fish | source
# PowerShell: rai completion powershell | Out-String | Invoke-Expression
```

---

## Attribution

By default, RAi adds attribution to Git commits and PRs. Customize:

```json
{
  "options": {
    "attribution": {
      "trailer_style": "co-authored-by",
      "generated_with": true
    }
  }
}
```

- `assisted-by` — `Assisted-by: RAi:[ModelID]`
- `co-authored-by` — `Co-Authored-By: RAi <rai@reasonary.ai>`
- `none` — No attribution
- `generated_with` — `Generated with RAi` line in commits/PRs

---

## Clipboard

| OS | Tool |
|----|------|
| Windows, macOS | Native |
| Linux+Wayland | `wl-copy`, `wl-paste` |
| Linux+X11 | `xclip` or `xsel` |

---

## License

[MIT](LICENSE.md)
