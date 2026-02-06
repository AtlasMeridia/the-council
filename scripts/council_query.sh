#!/bin/bash
# council_query.sh - Query an external AI model for /council command
# Usage: council_query.sh <provider> <prompt_file> <output_file>

set -uo pipefail

PROVIDER="${1:?Usage: council_query.sh <provider> <prompt_file> <output_file>}"
PROMPT_FILE="${2:?Missing prompt file}"
OUTPUT_FILE="${3:?Missing output file}"

# JSON-encode prompt for API calls
PROMPT_JSON=$(python3 -c "import sys,json; print(json.dumps(open(sys.argv[1]).read()))" "$PROMPT_FILE")

case "$PROVIDER" in
  gemini)
    if [[ -z "${GEMINI_API_KEY:-}" ]]; then
      echo "ERROR: GEMINI_API_KEY not set" > "$OUTPUT_FILE"
      exit 1
    fi
    if ! gemini -p "$(cat "$PROMPT_FILE")" > "$OUTPUT_FILE" 2>&1; then
      echo "ERROR: Gemini CLI failed" > "$OUTPUT_FILE"
    fi
    ;;

  openai)
    if [[ -z "${OPENAI_API_KEY:-}" ]]; then
      echo "ERROR: OPENAI_API_KEY not set" > "$OUTPUT_FILE"
      exit 1
    fi
    curl -s --max-time 120 https://api.openai.com/v1/chat/completions \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"gpt-4.1\",\"messages\":[{\"role\":\"user\",\"content\":$PROMPT_JSON}]}" \
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

  grok)
    if [[ -z "${XAI_API_KEY:-}" ]]; then
      echo "ERROR: XAI_API_KEY not set" > "$OUTPUT_FILE"
      exit 1
    fi
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
