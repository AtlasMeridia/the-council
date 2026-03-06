#!/bin/bash
# council_query.sh - Query an external AI model for /council command
# Usage: council_query.sh <provider> <prompt_file> <output_file>

set -uo pipefail

# Load .env if present (project-local API keys)
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

PROVIDER="${1:?Usage: council_query.sh <provider> <prompt_file> <output_file>}"
PROMPT_FILE="${2:?Missing prompt file}"
OUTPUT_FILE="${3:?Missing output file}"

case "$PROVIDER" in
  gemini)
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
      echo "ERROR: OPENROUTER_API_KEY not set" > "$OUTPUT_FILE"
      exit 1
    fi
    PROMPT_JSON=$(python3 -c "import sys,json; print(json.dumps(open(sys.argv[1]).read()))" "$PROMPT_FILE")
    curl -s --max-time 180 https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer $OPENROUTER_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"google/gemini-3.1-pro-preview\",\"messages\":[{\"role\":\"user\",\"content\":$PROMPT_JSON}]}" \
    | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'choices' in data:
        print(data['choices'][0]['message']['content'])
    elif 'error' in data:
        print(f'ERROR: {data[\"error\"][\"message\"]}')
    else:
        print('ERROR: Unexpected response format')
except Exception as e:
    print(f'ERROR: Failed to parse response: {e}')
" > "$OUTPUT_FILE"
    ;;

  openai)
    # codex CLI authenticates via OpenAI OAuth — no API key needed
    if ! codex exec --sandbox read-only --ephemeral --skip-git-repo-check \
      -m gpt-5.4 -c reasoning_effort=high \
      -o "$OUTPUT_FILE" "$(cat "$PROMPT_FILE")" 2>/dev/null; then
      echo "ERROR: Codex CLI failed" > "$OUTPUT_FILE"
    fi
    ;;

  grok)
    if [[ -z "${XAI_API_KEY:-}" ]]; then
      echo "ERROR: XAI_API_KEY not set" > "$OUTPUT_FILE"
      exit 1
    fi
    # JSON-encode prompt for API call
    PROMPT_JSON=$(python3 -c "import sys,json; print(json.dumps(open(sys.argv[1]).read()))" "$PROMPT_FILE")
    curl -s --max-time 180 https://api.x.ai/v1/chat/completions \
      -H "Authorization: Bearer $XAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"grok-4-fast-reasoning\",\"messages\":[{\"role\":\"user\",\"content\":$PROMPT_JSON}]}" \
    | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'choices' in data:
        print(data['choices'][0]['message']['content'])
    elif 'error' in data:
        print(f'ERROR: {data[\"error\"][\"message\"]}')
    else:
        print('ERROR: Unexpected response format')
except Exception as e:
    print(f'ERROR: Failed to parse response: {e}')
" > "$OUTPUT_FILE"
    ;;

  *)
    echo "ERROR: Unknown provider '$PROVIDER'. Use: gemini, openai, grok" > "$OUTPUT_FILE"
    exit 1
    ;;
esac
