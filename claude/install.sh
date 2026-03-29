#!/bin/bash
set -e

PLATFORM=${1:-android}
COMMANDS_DIR=".claude/commands"
BASE_URL="https://raw.githubusercontent.com/bidease/bidease-sdk-agents/main/claude/commands"

mkdir -p "$COMMANDS_DIR"

curl -fsSL "$BASE_URL/install-bidease-$PLATFORM.md" \
  -o "$COMMANDS_DIR/install-bidease-$PLATFORM.md"

echo "✓ Bidease $PLATFORM integration command installed"
echo "  Run: claude /install-bidease-$PLATFORM"
