#!/bin/bash
set -e

TARGET=${1:-}
COMMANDS_DIR=".claude/commands"
BASE_URL="https://raw.githubusercontent.com/bidease/bidease-sdk-agents/main/claude/commands"

VALID_TARGETS=(
  ios-max
  ios-admob
  android-max
  android-admob
  unity-ios-max
  unity-ios-admob
  unity-android-max
  unity-android-admob
)

if [[ -z "$TARGET" ]]; then
  echo "Usage: install.sh <target>"
  echo ""
  echo "Available targets:"
  for t in "${VALID_TARGETS[@]}"; do
    echo "  $t"
  done
  exit 1
fi

VALID=false
for t in "${VALID_TARGETS[@]}"; do
  [[ "$TARGET" == "$t" ]] && VALID=true && break
done

if [[ "$VALID" == false ]]; then
  echo "Unknown target: $TARGET"
  echo "Run without arguments to see available targets."
  exit 1
fi

mkdir -p "$COMMANDS_DIR"

curl -fsSL "$BASE_URL/bidease-$TARGET.md" \
  -o "$COMMANDS_DIR/bidease-$TARGET.md"

echo "✓ Bidease $TARGET integration command installed"
echo "  Run: claude /bidease-$TARGET"
