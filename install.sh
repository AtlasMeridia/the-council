#!/bin/bash
# install.sh - Install The Council for Claude Code
# Sets up the slash command and configures the script path

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

echo "The Council - Installer"
echo "======================="
echo ""
echo "Repo location: $REPO_DIR"
echo ""

# Create commands directory if needed
mkdir -p "$CLAUDE_COMMANDS_DIR"

# Symlink the command
if [ -L "$CLAUDE_COMMANDS_DIR/council.md" ]; then
  echo "Removing existing symlink..."
  rm "$CLAUDE_COMMANDS_DIR/council.md"
elif [ -f "$CLAUDE_COMMANDS_DIR/council.md" ]; then
  echo "Backing up existing council.md to council.md.bak..."
  mv "$CLAUDE_COMMANDS_DIR/council.md" "$CLAUDE_COMMANDS_DIR/council.md.bak"
fi

ln -s "$REPO_DIR/commands/council.md" "$CLAUDE_COMMANDS_DIR/council.md"
echo "Symlinked command: $CLAUDE_COMMANDS_DIR/council.md"

# Make script executable
chmod +x "$REPO_DIR/scripts/council_query.sh"

# Set COUNCIL_HOME in shell profile
SHELL_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_PROFILE="$HOME/.bashrc"
fi

EXPORT_LINE="export COUNCIL_HOME=\"$REPO_DIR\""

if [ -n "$SHELL_PROFILE" ]; then
  if grep -q "COUNCIL_HOME" "$SHELL_PROFILE" 2>/dev/null; then
    echo ""
    echo "COUNCIL_HOME already set in $SHELL_PROFILE"
    echo "Update it manually if the path has changed:"
    echo "  $EXPORT_LINE"
  else
    echo "" >> "$SHELL_PROFILE"
    echo "# The Council - multi-model AI assessment tool" >> "$SHELL_PROFILE"
    echo "$EXPORT_LINE" >> "$SHELL_PROFILE"
    echo ""
    echo "Added COUNCIL_HOME to $SHELL_PROFILE"
  fi
else
  echo ""
  echo "Could not detect shell profile. Add this manually:"
  echo "  $EXPORT_LINE"
fi

echo ""
echo "Required API keys (set in your shell profile):"
echo "  GEMINI_API_KEY  - Google Gemini"
echo "  OPENAI_API_KEY  - OpenAI GPT-4.1"
echo "  XAI_API_KEY     - xAI Grok"
echo ""
echo "Required tools:"
echo "  gemini CLI      - brew install gemini-cli (or see https://github.com/google-gemini/gemini-cli)"
echo "  curl, python3   - Usually pre-installed"
echo ""
echo "Done! Restart your shell or run: source $SHELL_PROFILE"
echo "Then use /council in Claude Code."
