---
allowed-tools:
  - Bash
  - Read
  - Write
---

# The Council

Convene 4 major AI models to independently assess a problem, idea, or project. Each model provides its own perspective, then you synthesize where they agree, diverge, and what everyone missed.

## Usage

```
/council <problem, idea, or project description>
```

## Models

| Model | Provider | Method |
|-------|----------|--------|
| **Claude Opus** | Anthropic | You (direct reasoning) |
| **Gemini** | Google | `gemini` CLI |
| **GPT-4.1** | OpenAI | API |
| **Grok 4** | xAI | API |

## Workflow

### Step 1: Prepare the Prompt

Write the following to `/tmp/council-prompt.txt`, replacing `{PROBLEM}` with $ARGUMENTS:

```
You are participating in a council of AI models. Each model provides an independent assessment of the same problem. Your perspective will be compared alongside assessments from Claude, Gemini, GPT, and Grok.

PROBLEM:
{PROBLEM}

Provide your assessment in this exact structure:

## Initial Reaction
Your gut-level assessment in 2-3 sentences. What stands out immediately?

## Strengths
What's strong about this idea/approach? (bullet points)

## Risks & Weaknesses
Potential problems, blind spots, or failure modes (bullet points)

## Suggested Approach
How you would tackle this — concrete, actionable steps (numbered list)

## Key Insight
One non-obvious angle, connection, or consideration that adds unique value. This is your chance to differentiate. (1-2 paragraphs)

Be direct and opinionated. Don't hedge excessively. Your unique perspective is what matters.
```

### Step 2: Generate Your Own Assessment

**BEFORE launching external queries**, generate YOUR OWN independent assessment using the same structure above. Think through the problem thoroughly. Write your assessment to `/tmp/council-claude.txt` using the Write tool.

This ensures your perspective is truly independent — not influenced by reading other models' responses.

### Step 3: Fan Out to External Models

Resolve the script path first:

```bash
COUNCIL_SCRIPT="${COUNCIL_HOME:-$HOME/.council}/scripts/council_query.sh"
```

Launch all 3 queries in parallel using `run_in_background: true`:

```bash
bash "$COUNCIL_SCRIPT" gemini /tmp/council-prompt.txt /tmp/council-gemini.txt
```

```bash
bash "$COUNCIL_SCRIPT" openai /tmp/council-prompt.txt /tmp/council-openai.txt
```

```bash
bash "$COUNCIL_SCRIPT" grok /tmp/council-prompt.txt /tmp/council-grok.txt
```

### Step 4: Collect Responses

Wait for all background tasks to complete using TaskOutput. Then read all output files:

- `/tmp/council-gemini.txt`
- `/tmp/council-openai.txt`
- `/tmp/council-grok.txt`

If a model returned an ERROR line, note the failure and proceed with the remaining models.

### Step 5: Present the Council Report

Output the complete report in this format:

```
═══════════════════════════════════════════════════════════════
                         THE COUNCIL
═══════════════════════════════════════════════════════════════
Problem: [1-line restatement of the problem]
Models: Claude Opus · Gemini · GPT-4.1 · Grok 4
═══════════════════════════════════════════════════════════════

CLAUDE OPUS (Anthropic)
────────────────────────────────────────
[Your assessment from Step 2]

GEMINI (Google)
────────────────────────────────────────
[Gemini's response]

GPT-4.1 (OpenAI)
────────────────────────────────────────
[GPT's response]

GROK 4 (xAI)
────────────────────────────────────────
[Grok's response]

═══════════════════════════════════════════════════════════════
                        SYNTHESIS
═══════════════════════════════════════════════════════════════

## Consensus
Points where most or all models agree:
- [point]

## Divergence
Where models meaningfully disagree:
- [topic] — [who says what, why it matters]

## Blind Spots
Important considerations that NO model adequately addressed:
- [point]

## Recommended Path Forward
The strongest composite strategy, drawing from each model's best insights:
1. [step]
2. [step]
3. [step]

═══════════════════════════════════════════════════════════════
```

## Rules

1. **Independence first**: Complete Step 2 (your own assessment) BEFORE launching Step 3. Do not read other models' output until you've committed your own perspective.
2. **Full substance**: Present each model's complete assessment. Don't truncate key reasoning.
3. **Honest synthesis**: Analyze real agreement and disagreement. Don't manufacture consensus or exaggerate differences.
4. **Failure resilience**: If 1-2 models fail, produce the report with available responses and note which models were unavailable.
5. **No editorializing within assessments**: Present each model's words faithfully. Save your comparative analysis for the Synthesis section.
