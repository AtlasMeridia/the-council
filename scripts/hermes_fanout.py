#!/usr/bin/env python3
"""
hermes_fanout.py — Hermes-native parallel council fan-out.

Queries Opus 4.7, Gemini 3.1 Pro, GPT-5.5, and Grok 4.20 concurrently.
Writes individual response files to the session directory.

Usage:
    python3 hermes_fanout.py <prompt_file> <session_dir>

Reads API keys from the-council/.env next to this scripts/ dir (override with COUNCIL_ENV)
Uses only stdlib (urllib, json, concurrent.futures) — no pip deps.
"""

import json
import os
import sys
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ENV_PATH = Path(os.environ.get("COUNCIL_ENV", Path(__file__).resolve().parent.parent / ".env"))

# Reasoning effort: "high" (default) or "xhigh" (full council, irreversible decisions)
# Set via REASONING_EFFORT env var or default to "high"
REASONING_EFFORT = os.environ.get("REASONING_EFFORT", "high")

MODELS = {
    "opus": {
        "url": "https://openrouter.ai/api/v1/chat/completions",
        "model": "anthropic/claude-opus-4.7",
        "key_env": "OPENROUTER_API_KEY",
        "label": "CLAUDE OPUS 4.7 (Anthropic via OpenRouter)",
        "extra_body": {
            "reasoning": {"effort": "high"},  # Opus 4.7 adaptive reasoning
        },
    },
    "gemini": {
        "url": "https://openrouter.ai/api/v1/chat/completions",
        "model": "google/gemini-3.1-pro-preview",
        "key_env": "OPENROUTER_API_KEY",
        "label": "GEMINI 3.1 PRO (Google via OpenRouter)",
        "extra_body": {},
    },
    "openai": {
        "url": "https://openrouter.ai/api/v1/chat/completions",
        "model": "openai/gpt-5.5",
        "key_env": "OPENROUTER_API_KEY",
        "label": f"GPT-5.5 (OpenAI via OpenRouter, {REASONING_EFFORT} reasoning)",
        "extra_body": {
            "reasoning_effort": REASONING_EFFORT,
        },
    },
    "grok": {
        "url": "https://api.x.ai/v1/chat/completions",
        "model": "grok-4.20-0309-reasoning",
        "key_env": "XAI_API_KEY",
        "label": "GROK 4.20 (xAI)",
        "extra_body": {},
    },
}


def load_env(path):
    """Parse a .env file into a dict."""
    env = {}
    if not path.exists():
        print(f"WARNING: .env not found at {path}", file=sys.stderr)
        return env
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip()
    return env


def query_model(name, config, prompt, keys):
    """Send a chat completion request. Returns (name, response_text, label)."""
    api_key = keys.get(config["key_env"])
    if not api_key:
        return name, f"ERROR: {config['key_env']} not set in .env", config["label"]

    body = {
        "model": config["model"],
        "messages": [{"role": "user", "content": prompt}],
    }
    # Merge any extra body params (reasoning effort, etc.)
    body.update(config.get("extra_body", {}))

    payload = json.dumps(body).encode("utf-8")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    # OpenRouter recommends HTTP-Referer and X-Title headers
    if "openrouter.ai" in config["url"]:
        headers["HTTP-Referer"] = "https://github.com/nadine-council"
        headers["X-Title"] = "The Council"

    req = urllib.request.Request(
        config["url"],
        data=payload,
        headers=headers,
    )

    try:
        with urllib.request.urlopen(req, timeout=240) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if "choices" in data:
                text = data["choices"][0]["message"]["content"]
                return name, text, config["label"]
            elif "error" in data:
                msg = data["error"].get("message", "Unknown error")
                return name, f"ERROR: {msg}", config["label"]
            else:
                return name, "ERROR: Unexpected response format", config["label"]
    except urllib.error.HTTPError as e:
        body = ""
        try:
            body = e.read().decode("utf-8")[:500]
        except Exception:
            pass
        return name, f"ERROR: HTTP {e.code} — {body}", config["label"]
    except urllib.error.URLError as e:
        return name, f"ERROR: Connection failed — {e.reason}", config["label"]
    except Exception as e:
        return name, f"ERROR: {type(e).__name__}: {e}", config["label"]


def main(prompt_file=None, session_dir=None):
    """Run the fan-out. Can be called from CLI or imported."""
    if prompt_file is None:
        if len(sys.argv) < 3:
            print("Usage: hermes_fanout.py <prompt_file> <session_dir>")
            sys.exit(1)
        prompt_file = Path(sys.argv[1])
        session_dir = Path(sys.argv[2])
    else:
        prompt_file = Path(prompt_file)
        session_dir = Path(session_dir)

    session_dir.mkdir(parents=True, exist_ok=True)
    prompt = prompt_file.read_text()
    keys = load_env(ENV_PATH)

    succeeded = 0
    failed = 0
    results = {}

    with ThreadPoolExecutor(max_workers=4) as pool:
        futures = {
            pool.submit(query_model, name, cfg, prompt, keys): name
            for name, cfg in MODELS.items()
        }
        for future in as_completed(futures):
            name, response, label = future.result()
            results[name] = (response, label)

            # Write individual file
            out_path = session_dir / f"{name}.txt"
            out_path.write_text(response)

            if response.startswith("ERROR"):
                failed += 1
                print(f"[FAIL] {label} — {response[:100]}", file=sys.stderr)
            else:
                succeeded += 1
                print(f"[ OK ] {label} — {len(response)} chars", file=sys.stderr)

    # Print results to stdout in canonical order
    for name in ["opus", "gemini", "openai", "grok"]:
        response, label = results.get(name, ("ERROR: No response", name.upper()))
        print(f"\n{'=' * 64}")
        print(f"  {label}")
        print(f"{'=' * 64}")
        print(response)

    print(f"\n--- {succeeded}/4 models responded, {failed} failed ---")
    print(f"Session archived: {session_dir}")

    return results


if __name__ == "__main__":
    main()
