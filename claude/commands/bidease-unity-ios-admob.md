# Bidease Unity SDK — AdMob Custom Event (iOS)

You are helping a developer integrate the Bidease SDK as a custom event in Google AdMob mediation inside a Unity project targeting iOS.

Reference docs — fetch and read before proceeding:
- https://devs.bidease.com/docs/ios-admob
- https://developers.google.com/admob/unity/quick-start

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

### 1.3 Check Google Mobile Ads SDK

```bash
find . -name "Dependencies.xml" | xargs grep -l -i "google-mobile-ads\|GoogleMobileAds" 2>/dev/null
find . -name "GoogleMobileAdsSettings.asset" 2>/dev/null | head -1
```

If AdMob **not found** — stop: "Google Mobile Ads SDK is required for Bidease adapter integration."
Share: https://developers.google.com/admob/unity/quick-start

If **found** — note the AdMob SDK version. Bidease requires **AdMob ≥ 12** (iOS). Then detect active ad formats:

```bash
grep -r "BannerView\|AdView" Assets/ --include="*.cs" 2>/dev/null
grep -r "InterstitialAd" Assets/ --include="*.cs" 2>/dev/null
grep -r "RewardedAd" Assets/ --include="*.cs" 2>/dev/null
grep -r "AppOpenAd" Assets/ --include="*.cs" 2>/dev/null
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
    <iosPod name="BideaseSDK/AdapterAdmob" version="2.0.2" minTargetSdk="13.0"/>
  </iosPods>
</dependencies>
```

Then ask the user to open **Assets → External Dependency Manager → iOS Resolver → Resolve** in Unity Editor, or confirm that auto-resolve is enabled.

---

## Step 4: Set Bidease App Key

Bidease requires its own App Key set **before** AdMob is initialized.

`BideaseMobileSDK` is a **native iOS framework** — there is no Unity C# package for it. You must create a native bridge manually.

Ask the user for their Bidease App Key if not already known — it is found in **monetize.bidease.com → Applications → [App] → App Key**.

### 4.1 Create native Objective-C++ bridge

Create `Assets/Plugins/iOS/BideaseNativeBridge.mm`:

```objc
#import <Foundation/Foundation.h>

// BideaseAdmobSetAppKey is a C-function exported by BideaseAdapterAdmob.xcframework.
// Do NOT call [BideaseMediationAdapter setAppKey:] — that Swift method is not bridged to Obj-C.
extern "C" void BideaseAdmobSetAppKey(const char* _Nullable appKey);

extern "C" {
    void _BideaseSetAppKey(const char* appKey) {
        BideaseAdmobSetAppKey(appKey);
    }
}
```

> **Why `extern "C"`?** `BideaseAdmobSetAppKey` is a C symbol. The `.mm` file compiles as Objective-C++, so without `extern "C"` the compiler looks for a C++-mangled symbol and the build fails with `Undefined symbol`.

### 4.2 Create C# wrapper

Create `Assets/Plugins/Bidease/BideaseMobileSDK.cs`:

```csharp
using System.Runtime.InteropServices;

namespace BideaseMobileSDK
{
    public static class BideaseMediationAdapter
    {
#if UNITY_IOS && !UNITY_EDITOR
        [DllImport("__Internal")]
        private static extern void _BideaseSetAppKey(string appKey);

        public static void SetAppKey(string appKey) => _BideaseSetAppKey(appKey);
#else
        public static void SetAppKey(string appKey) =>
            UnityEngine.Debug.Log("[Bidease] SetAppKey (no-op on this platform): " + appKey);
#endif
    }
}
```

### 4.3 Call SetAppKey before AdMob initialization

Find the C# file where `MobileAds.Initialize()` is called. Add immediately before that call:

```csharp
using BideaseMobileSDK;

BideaseMediationAdapter.SetAppKey("YOUR_BIDEASE_APP_KEY");
```

---

## Step 5: Verify iOS build settings

### 5.1 Minimum iOS deployment target

Bidease SDK requires iOS **13.0** or higher:

```bash
grep "iPhoneTargetOSVersionString\|minimumOSVersion" ProjectSettings/ProjectSettings.asset | head -4
```

If below `13.0` — update in `ProjectSettings.asset`.

### 5.2 Architecture

Ensure the project targets `arm64`. Check in Unity: **Player Settings → iOS → Other Settings → Architecture**.

---

## Step 6: AdMob mediation setup

Tell the user the following and wait for confirmation before proceeding:

```
Manual steps required in AdMob dashboard (admob.google.com):

1. Go to Mediation → select an existing mediation group or create a new one
   for the ad format you want to integrate.

2. In the Waterfall ad sources table → click "Add custom event"

3. Fill in:
   - Label: AdFormat_ecpm_X.X  (e.g. "Interstitial_ecpm_1.3" for $1.30 floor price)
   - eCPM: same floor price value as in the Label

4. Click Continue, then fill in the mapping:
   - Class Name: BideaseMediationAdapter  (same for all formats)
   - Parameter: AdFormat_ecpm_X.X  (must match the Label exactly)

5. Click Done → Save

Repeat for each ad format and floor price tier.
In case of any questions please refer to the documentation: https://devs.bidease.com/docs/ios-admob#3-add-custom-events-in-admob-mediation
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
  BideaseAdapterAdmob Initialization end no error
  Bidease Rewarded creative loaded
  BideaseAdapterAdmob Rewarded loaded
  BideaseAdapterAdmob Rewarded bid success
  Bidease Rewarded call show
  Bidease Rewarded displayed
  BideaseAdapterAdmob Rewarded displayed
  Bidease Rewarded close
  BideaseAdapterAdmob Rewarded closed
  BideaseAdapterAdmob Rewarded rewarded

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
