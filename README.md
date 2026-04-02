# Bidease SDK Agents

Claude Code commands for integrating Bidease SDK Custom adapter for AppLovin MAX mediation.

## Installation

Run from the root of your project:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bidease/bidease-sdk-agents/main/claude/install.sh) <platform>
```

Then launch the integration assistant:

```bash
claude /install-bidease-<platform>
```

## Supported platforms

| Platform | Command |
|----------|---------|
| Native Android | `android` |
| Unity (Android) | `unity` |

## Examples

```bash
# Native Android
bash <(curl -fsSL https://raw.githubusercontent.com/bidease/bidease-sdk-agents/main/claude/install.sh) android
claude /install-bidease-android

# Unity for Android build
bash <(curl -fsSL https://raw.githubusercontent.com/bidease/bidease-sdk-agents/main/claude/install.sh) unity
claude /install-bidease-unity
```

## Structure

```
claude/
├── install.sh
└── commands/
    ├── install-bidease-android.md
    ├── install-bidease-unity.md
    └── install-bidease-ios.md       (coming soon)
```
