#!/bin/bash
# council_query.sh - Query an external AI model for /council command
# Usage: council_query.sh <provider> <prompt_file> <output_file>
# Providers: opus, gemini, openai, grok

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

# Helper to extract content from OpenAI-compatible response
extract_content() {
  python3 -c "
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
"
}

case "$PROVIDER" in
  opus)
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
      echo "ERROR: OPENROUTER_API_KEY not set" > "$OUTPUT_FILE"
      exit 1
    fi
    PROMPT_JSON=$(python3 -c "import sys,json; print(json.dumps(open(sys.argv[1]).read()))" "$PROMPT_FILE")
    curl -s --max-time 240 https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer $OPENROUTER_API_KEY" \
      -H "Content-Type: application/json" \
      -H "HTTP-Referer: https://github.com/nadine-council" \
      -H "X-Title: The Council" \
      -d "{\"model\":\"anthropic/claude-opus-4.7\",\"messages\":[{\"role\":\"user\",\"content\":$PROMPT_JSON}],\"reasoning\":{\"effort\":\"high\"}}" \
    | extract_content > "$OUTPUT_FILE"
    ;;

  gemini)
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
      echo "ERROR: OPENROUTER_API_KEY not set" > "$OUTPUT_FILE"
      exit 1
    fi
    PROMPT_JSON=$(python3 -c "import sys,json; print(json.dumps(open(sys.argv[1]).read()))" "$PROMPT_FILE")
    curl -s --max-time 240 https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer $OPENROUTER_API_KEY" \
      -H "Content-Type: application/json" \
      -H "HTTP-Referer: https://github.com/nadine-council" \
      -H "X-Title: The Council" \
      -d "{\"model\":\"google/gemini-3.1-pro-preview\",\"messages\":[{\"role\":\"user\",\"content\":$PROMPT_JSON}]}" \
    | extract_content > "$OUTPUT_FILE"
    ;;

  openai)
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
      echo "ERROR: OPENROUTER_API_KEY not set" > "$OUTPUT_FILE"
      exit 1
    fi
    PROMPT_JSON=$(python3 -c "import sys,json; print(json.dumps(open(sys.argv[1]).read()))" "$PROMPT_FILE")
    curl -s --max-time 240 https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer $OPENROUTER_API_KEY" \
      -H "Content-Type: application/json" \
      -H "HTTP-Referer: https://github.com/nadine-council" \
      -H "X-Title: The Council" \
      -d "{\"model\":\"openai/gpt-5.5\",\"messages\":[{\"role\":\"user\",\"content\":$PROMPT_JSON}],\"reasoning_effort\":\"high\"}" \
    | extract_content > "$OUTPUT_FILE"
    ;;

  grok)
    if [[ -z "${XAI_API_KEY:-}" ]]; then
      echo "ERROR: XAI_API_KEY not set" > "$OUTPUT_FILE"
      exit 1
    fi
    PROMPT_JSON=$(python3 -c "import sys,json; print(json.dumps(open(sys.argv[1]).read()))" "$PROMPT_FILE")
    curl -s --max-time 240 https://api.x.ai/v1/chat/completions \
      -H "Authorization: Bearer $XAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"grok-4.20-0309-reasoning\",\"messages\":[{\"role\":\"user\",\"content\":$PROMPT_JSON}]}" \
    | extract_content > "$OUTPUT_FILE"
    ;;

  *)
    echo "ERROR: Unknown provider '$PROVIDER'. Use: opus, gemini, openai, grok" > "$OUTPUT_FILE"
    exit 1
    ;;
esac
