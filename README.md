# The Council

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) slash command that convenes 4 major AI models to independently assess any problem, idea, or project.

Each model provides its own perspective using a structured format, then Claude synthesizes where they agree, diverge, and what everyone missed.

## Models

| Model | Provider | Method |
|-------|----------|--------|
| Claude Opus | Anthropic | Direct (you're already in Claude Code) |
| Gemini | Google | `gemini` CLI |
| GPT-4.1 | OpenAI | API |
| Grok 4 | xAI | API |

## How It Works

1. You describe a problem: `/council Should I rewrite this monolith as microservices?`
2. Claude generates its own independent assessment first
3. Gemini, GPT, and Grok are queried in parallel
4. Each model responds with: Initial Reaction, Strengths, Risks, Suggested Approach, and a Key Insight
5. Claude synthesizes a final report showing Consensus, Divergence, Blind Spots, and a Recommended Path Forward

The independence constraint is key — Claude commits its own perspective before seeing any other model's response.

## Install

```bash
git clone https://github.com/AtlasMeridia/the-council.git
cd the-council
bash install.sh
```

The installer:
- Symlinks the `/council` command into `~/.claude/commands/`
- Sets `COUNCIL_HOME` in your shell profile
- Makes the query script executable

### Prerequisites

**Claude Code** — this is a slash command for Claude Code.

**API Keys** — set these in your shell profile:
```bash
export GEMINI_API_KEY="..."   # Google AI Studio
export OPENAI_API_KEY="..."   # OpenAI Platform
export XAI_API_KEY="..."      # xAI Console
```

**Gemini CLI** — used for the Gemini query:
```bash
npm install -g @anthropic-ai/gemini-cli
# or see https://github.com/google-gemini/gemini-cli
```

Missing a key? The Council still works — it gracefully degrades when models are unavailable and reports which ones failed.

## Usage

In any Claude Code session:

```
/council <your question, problem, or idea>
```

### Examples

```
/council Should I use PostgreSQL or MongoDB for a multi-tenant SaaS app?
```

```
/council I'm considering quitting my job to start a company in the AI dev tools space. What should I consider?
```

```
/council Review this architecture: [paste or describe your system design]
```

## Customization

### Changing Models

Edit `scripts/council_query.sh` to swap models:
- Change the `model` field in the API calls (e.g., `gpt-4.1` → `gpt-4o`)
- Add new providers by following the existing pattern

### Changing the Prompt Structure

Edit the prompt template in `commands/council.md` (Step 1) to change what each model produces.

## How It's Built

Two files:
- `commands/council.md` — A Claude Code slash command (markdown with YAML frontmatter) that orchestrates the workflow
- `scripts/council_query.sh` — A shell script that handles API calls to each provider

The slash command is essentially a prompt that tells Claude how to run the council session. Claude reads it, follows the steps, and uses Bash to execute the external queries.

## License

MIT
