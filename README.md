# Bidease SDK Agents

Claude Code commands for integrating Bidease SDK with AppLovin MAX and Google AdMob mediation.

## Installation

Run from the root of your project:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bidease/bidease-sdk-agents/main/claude/install.sh) <target>
```

Then launch the integration assistant:

```bash
claude /bidease-<target>
```

## Supported platforms

| Platform | Mediation | Target | Command |
|----------|-----------|--------|---------|
| Native iOS | AppLovin MAX | `ios-max` | `/bidease-ios-max` _(coming soon)_ |
| Native iOS | Google AdMob | `ios-admob` | `/bidease-ios-admob` |
| Native Android | AppLovin MAX | `android-max` | `/bidease-android-max` |
| Native Android | Google AdMob | `android-admob` | `/bidease-android-admob` |
| Unity (iOS build) | AppLovin MAX | `unity-ios-max` | `/bidease-unity-ios-max` _(coming soon)_ |
| Unity (iOS build) | Google AdMob | `unity-ios-admob` | `/bidease-unity-ios-admob` |
| Unity (Android build) | AppLovin MAX | `unity-android-max` | `/bidease-unity-android-max` |
| Unity (Android build) | Google AdMob | `unity-android-admob` | `/bidease-unity-android-admob` |

## Examples

```bash
# Native iOS with AppLovin MAX
bash <(curl -fsSL https://raw.githubusercontent.com/bidease/bidease-sdk-agents/main/claude/install.sh) ios-max
claude /bidease-ios-max

# Native Android with Google AdMob
bash <(curl -fsSL https://raw.githubusercontent.com/bidease/bidease-sdk-agents/main/claude/install.sh) android-admob
claude /bidease-android-admob

# Unity targeting Android with AppLovin MAX
bash <(curl -fsSL https://raw.githubusercontent.com/bidease/bidease-sdk-agents/main/claude/install.sh) unity-android-max
claude /bidease-unity-android-max
```

## Structure

```
claude/
├── install.sh
└── commands/
    ├── bidease-ios-max.md
    ├── bidease-ios-admob.md
    ├── bidease-android-max.md
    ├── bidease-android-admob.md
    ├── bidease-unity-ios-max.md
    ├── bidease-unity-ios-admob.md
    ├── bidease-unity-android-max.md
    └── bidease-unity-android-admob.md
```
