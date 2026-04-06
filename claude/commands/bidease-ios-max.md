# Bidease iOS SDK — AppLovin MAX Custom Adapter

You are helping a developer integrate the Bidease SDK as a custom network in AppLovin MAX mediation for a native iOS project.

Reference docs — fetch and read before proceeding:
- https://devs.bidease.com/docs/ios-applovin
- https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/

## Step 1: Detect project type

Check for a `Podfile` and an `.xcodeproj` or `.xcworkspace` in the project root.

- Both present → CocoaPods iOS project, proceed.
- `Podfile` missing → stop: "Please run `pod init` first, then re-run this command."
- Neither found → stop: "This command supports native iOS projects with CocoaPods."

## Step 2: Inspect the project

### 2.1 AppLovin MAX SDK

Check `Podfile` and source files for `AppLovinSDK` pod or `import AppLovinSDK`.

- If **not found**: AppLovin MAX SDK is required. Share the setup guide: https://support.axon.ai/en/max/ios/overview/integration/ — then stop.
- If **found**: check the MAX SDK version. Bidease requires **AppLovin MAX ≥ 13**. If lower — ask the user to update before proceeding.

### 2.2 SDK key

Search for the AppLovin SDK key in the project — commonly in `AppDelegate` as `ALSdkInitializationConfiguration(sdkKey:)` or in `Info.plist` as `AppLovinSdkKey`. Note the value if found.

### 2.3 Ad formats

Scan Swift/Objective-C source files for:

```bash
grep -r "MAInterstitialAd\|MAAdDelegate" . --include="*.swift" --include="*.m" 2>/dev/null
grep -r "MARewardedAd\|MARewardedAdDelegate" . --include="*.swift" --include="*.m" 2>/dev/null
grep -r "MAAdView\|MAAdViewAdDelegate" . --include="*.swift" --include="*.m" 2>/dev/null
grep -r "MAAppOpenAd" . --include="*.swift" --include="*.m" 2>/dev/null
```

Report which formats are found.

## Step 3: Add dependency and verify requirements

### 3.1 Xcode version

Bidease SDK requires Xcode **16.4 or higher**:

```bash
xcodebuild -version
```

If below 16.4 — stop and ask the user to update Xcode.

### 3.2 Minimum iOS deployment target

Bidease SDK requires iOS **13.0** or higher. Check `platform :ios` in the Podfile and `IPHONEOS_DEPLOYMENT_TARGET` in `project.pbxproj`:

```bash
grep "platform :ios" Podfile
grep "IPHONEOS_DEPLOYMENT_TARGET" *.xcodeproj/project.pbxproj | head -4
```

If either is below `13.0` — update both.

Update Podfile:
```ruby
platform :ios, '13.0'
```

Update `project.pbxproj` — replace all occurrences of `IPHONEOS_DEPLOYMENT_TARGET` values below 13.0.

### 3.3 use_frameworks!

Verify `use_frameworks!` is present in the Podfile. If missing — add it before the `target` block.

### 3.4 Add Bidease pod

Add inside the target block in `Podfile`:

```ruby
pod 'BideaseSDK/AdapterApplovin', '2.0.2'
```

### 3.5 Run pod install

```bash
pod install --repo-update
```

After install — use `.xcworkspace` for all subsequent operations, not `.xcodeproj`.

## Step 4: Set Bidease App Key

Bidease requires its own App Key set **before** AppLovin MAX is initialized.

Find the file where `ALSdk.shared().initialize(with:)` is called — typically `AppDelegate`. Add the following immediately before that call:

```swift
import BideaseMobileSDK

BideaseApplovinMediationAdapter.setAppKey("YOUR_BIDEASE_APP_KEY")
```

Ask the user for their Bidease App Key if not already known — it is found in **monetize.bidease.com → Applications → [App] → App Key**.

## Step 5: AppLovin MAX dashboard setup

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

## Step 6: Build and verify

### 6.1 Build

Find the workspace and scheme:

```bash
ls *.xcworkspace
xcodebuild -list 2>/dev/null | grep -A 10 "Schemes:"
```

Build for simulator:

```bash
xcodebuild \
  -workspace "<ProjectName>.xcworkspace" \
  -scheme "<SchemeName>" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "warning:" | tail -20
```

If **framework not found** or **module missing** — verify `pod install` completed without errors and the workspace (not `.xcodeproj`) is being used.

### 6.2 Verify integration

If the build succeeded — tell the user:

```
Build succeeded. The project is ready for testing.

To verify the integration, run the app from Xcode and filter the console output
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

### 6.3 Test mode (optional)

To get near 100% fill during QA — add the test mode pod and re-run `pod install`:

```ruby
pod 'BideaseSDK/TestMode', '2.0.2'
```

Alternatively, enable via **monetize.bidease.com → Applications → [App] → Test Devices** — add the device by IDFA and enable Test for the app.

**Disable test mode before submitting to the App Store.**

Report results to the user with a summary of what's working.
