# Bidease Unity SDK — AppLovin MAX Custom Adapter (iOS)

You are helping a developer integrate the Bidease SDK as a custom network in AppLovin MAX mediation inside a Unity project targeting iOS.

Reference docs — fetch and read before proceeding:
- https://devs.bidease.com/docs/ios-applovin
- https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/

---

## Step 1: Detect and validate the project

### 1.1 Confirm Unity project

Check for:
- `ProjectSettings/ProjectVersion.txt`
- `Assets/` directory

If not found — stop: "This command supports Unity projects only. Run it from the Unity project root."

### 1.2 Detect Unity version

```bash
cat ProjectSettings/ProjectVersion.txt 2>/dev/null \
  || grep "unityVersion" ProjectSettings/ProjectSettings.asset | head -1
```

Extract the major version and save it:

- `2022.x` → **UNITY_2022**
- `2023.x` or `6000.x` / `2024.x` → **UNITY_6**
- `2021.x` or older → not supported. Stop: "Unity 2021 and older are not supported. Please upgrade to Unity 2022 LTS or Unity 6."

### 1.3 Check AppLovin MAX SDK

```bash
find . -name "Dependencies.xml" | xargs grep -l -i "applovin" 2>/dev/null
find . -path "*/MaxSdk*" -name "AppLovinSettings.asset" 2>/dev/null | head -1
```

If MAX **not found** — stop: "AppLovin MAX SDK is required for Bidease adapter integration."
Share: https://support.axon.ai/en/max/unity/overview/integration/

If **found** — note the MAX SDK version. Bidease requires **AppLovin MAX ≥ 13**. Then detect active ad formats:

```bash
grep -r "MaxSdk.CreateBanner\|MaxBannerAd\|MaxSdkCallbacks.Banner" Assets/ --include="*.cs" 2>/dev/null
grep -r "MaxSdk.LoadInterstitial\|MaxInterstitialAd\|MaxSdkCallbacks.Interstitial" Assets/ --include="*.cs" 2>/dev/null
grep -r "MaxSdk.LoadRewardedAd\|MaxRewardedAd\|MaxSdkCallbacks.Rewarded" Assets/ --include="*.cs" 2>/dev/null
grep -r "MaxSdk.CreateMRec\|MaxMRecAd\|MaxSdkCallbacks.MRec" Assets/ --include="*.cs" 2>/dev/null
```

Report which formats are active — Bidease will be integrated for those.

---

## Step 2: Check Xcode version

Bidease SDK requires Xcode **16.4 or higher**:

```bash
xcodebuild -version
```

If below 16.4 — stop and ask the user to update Xcode before proceeding.

---

## Step 3: Add Bidease to EDM4U Dependencies

Unity iOS builds resolve pods through EDM4U (External Dependency Manager). Check if a `BideaseDependencies.xml` already exists:

```bash
find Assets/ -name "*Bidease*Dependencies*" 2>/dev/null
```

If not found — create `Assets/Plugins/Bidease/Editor/BideaseDependencies.xml`:

```xml
<dependencies>
  <iosPods>
    <iosPod name="BideaseSDK/AdapterApplovin" version="2.0.2" minTargetSdk="13.0"/>
  </iosPods>
</dependencies>
```

Then ask the user to open **Assets → External Dependency Manager → iOS Resolver → Resolve** in Unity Editor, or confirm that auto-resolve is enabled.

---

## Step 4: Set Bidease App Key

Bidease requires its own App Key set **before** AppLovin MAX is initialized.

Find the C# file where `MaxSdk.SetSdkKey()` or `MaxSdk.InitializeSdk()` is called. Add the following immediately before the MAX initialization call:

```csharp
// Set Bidease App Key before initializing AppLovin MAX
MaxSdk.SetCustomData("bidease_app_key", "YOUR_BIDEASE_APP_KEY");
```

Ask the user for their Bidease App Key if not already known — it is found in **monetize.bidease.com → Applications → [App] → App Key**.

---

## Step 5: Verify iOS build settings

### 5.1 Minimum iOS deployment target

Bidease SDK requires iOS **13.0** or higher:

```bash
grep "iPhoneTargetOSVersionString\|minimumOSVersion" ProjectSettings/ProjectSettings.asset | head -4
```

If below `13.0` — update in `ProjectSettings.asset`.

### 5.2 Architecture

Ensure the project targets `arm64` (not `armv7`) — required for modern iOS SDKs. Check in Unity: **Player Settings → iOS → Other Settings → Architecture**.

---

## Step 6: AppLovin MAX dashboard setup

Tell the user the following and wait for confirmation before proceeding:

```
Manual steps required in AppLovin MAX dashboard (dash.applovin.com):

1. Go to MAX → Mediation → Manage → Networks
   Scroll to the bottom → click "Click here to add a Custom Network"

2. Fill in:
   - Network Type: SDK
   - Name: Bidease
   - iOS Adapter Class Name: BideaseApplovinMediationAdapter

3. Click Save, then go to MAX → Mediation → Manage → Ad Units
   Select the ad unit → find Bidease in the custom networks list → enable it

4. Enter placement details:
   - App ID: your Bidease App Key
   - Placement ID: AdFormat_ecpm_X.X  (e.g. "Interstitial_ecpm_1.3" for $1.30 floor price)
   - CPM Price: same floor price value as in Placement ID

5. Click Save

Repeat for each ad unit and floor price tier.
Wait 30–60 minutes for changes to take effect.
In case of any questions please refer to the documentation: https://devs.bidease.com/docs/ios-applovin#3-configure-bidease-in-max-dashboard
```

---

## Step 7: Build and verify

### 7.1 Build Xcode project from Unity

Ask the user to build via **File → Build Settings → iOS → Build** in the Unity Editor, or use batch mode:

```bash
UNITY_VERSION=$(cat ProjectSettings/ProjectVersion.txt | grep "m_EditorVersion:" | awk '{print $2}')
UNITY_PATH=$(find /Applications/Unity/Hub/Editor -name "Unity" -path "*${UNITY_VERSION}*" -type f 2>/dev/null | head -1)

"$UNITY_PATH" \
  -batchmode \
  -nographics \
  -projectPath "$(pwd)" \
  -buildTarget iOS \
  -executeMethod BuildScript.BuildiOS \
  -logFile /tmp/unity_ios_build.log \
  -quit
echo "Exit code: $?"
```

On failure — read the log:
```bash
grep -E "error |Error |FAILED|Exception" /tmp/unity_ios_build.log | grep -v "^#" | tail -40
```

### 7.2 Open Xcode and build for device

After Unity generates the Xcode project:

```bash
open /tmp/ios_build/*.xcworkspace 2>/dev/null || open /tmp/ios_build/*.xcodeproj
```

Build and run on a real device from Xcode for the best test results.

### 7.3 Verify integration

If the build succeeded — tell the user:

```
Build succeeded. The project is ready for testing.

Run the app from Xcode on a real device and filter the console output
by the keyword "Bidease".

Expected log sequence for a working rewarded ad:

  Bidease init success
  BideaseAdapterApplovin Initialization end no error
  Bidease Rewarded creative loaded
  BideaseAdapterApplovin Rewarded loaded
  BideaseAdapterApplovin Rewarded bid success
  Bidease Rewarded call show
  Bidease Rewarded displayed
  BideaseAdapterApplovin Rewarded displayed
  Bidease Rewarded close
  BideaseAdapterApplovin Rewarded closed
  BideaseAdapterApplovin Rewarded rewarded

The same pattern applies to other formats (Interstitial, Banner) —
replace "Rewarded" with the corresponding format name.
```

Known issues:
- `bid failure 204` — no fill, normal behavior.
- SSL proxy (Charles/Proxyman) active — disable when testing.

### 7.4 Test mode (optional)

Add test mode pod to `BideaseDependencies.xml` and re-resolve:

```xml
<iosPod name="BideaseSDK/TestMode" version="2.0.2" minTargetSdk="13.0"/>
```

Or enable via **monetize.bidease.com → Applications → [App] → Test Devices** — add the device by IDFA.

**Disable test mode before submitting to the App Store.**

---

## Step 8: Report results

Summarize to the user:

1. Unity version detected
2. Files created/modified — list each file and what was changed
3. Dependencies added
4. Build result
5. Log status: init success or failure, which bid formats are active

Only report issues that require action. Skip harmless log entries.
