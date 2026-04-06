# Bidease iOS SDK — AdMob Custom Event

You are helping a developer integrate the Bidease SDK as a custom event in Google AdMob mediation for a native iOS project.

Reference docs — fetch and read before proceeding:
- https://devs.bidease.com/docs/ios-admob
- https://developers.google.com/admob/ios/quick-start

## Step 1: Detect project type

Check for a `Podfile` and an `.xcodeproj` or `.xcworkspace` in the project root.

- Both present → CocoaPods iOS project, proceed.
- `Podfile` missing → stop: "Please run `pod init` first, then re-run this command."
- Neither found → stop: "This command supports native iOS projects with CocoaPods."

## Step 2: Inspect the project

### 2.1 Google Mobile Ads SDK

Check `Podfile` and source files for `Google-Mobile-Ads-SDK` pod or `import GoogleMobileAds`.

- If **not found**: AdMob SDK is required. Share the setup guide: https://developers.google.com/admob/ios/quick-start — then stop.
- If **found**: check the SDK version. Bidease requires **AdMob ≥ 12**. If lower — ask the user to update before proceeding.

### 2.2 AdMob App ID

Search for `GADApplicationIdentifier` in `Info.plist`. Note the value (`ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`) if found.

### 2.3 Ad formats

Scan Swift/Objective-C source files for:

```bash
grep -r "InterstitialAd\|GADInterstitialAd" . --include="*.swift" --include="*.m" 2>/dev/null
grep -r "RewardedAd\|GADRewardedAd" . --include="*.swift" --include="*.m" 2>/dev/null
grep -r "BannerView\|GADBannerView" . --include="*.swift" --include="*.m" 2>/dev/null
grep -r "AppOpenAd\|GADAppOpenAd" . --include="*.swift" --include="*.m" 2>/dev/null
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
pod 'BideaseSDK/AdapterAdmob', '2.0.2'
```

### 3.5 Run pod install

```bash
pod install --repo-update
```

After install — use `.xcworkspace` for all subsequent operations, not `.xcodeproj`.

## Step 4: Set Bidease App Key

Bidease requires its own App Key set **before** AdMob is initialized.

Find the file where `MobileAds.shared.start()` (or `GADMobileAds.sharedInstance().start()`) is called — typically `AppDelegate`. Add the following immediately before that call:

```swift
import BideaseMobileSDK

BideaseMediationAdapter.setAppKey("YOUR_BIDEASE_APP_KEY")
```

Ask the user for their Bidease App Key if not already known — it is found in **monetize.bidease.com → Applications → [App] → App Key**.

## Step 5: AdMob mediation setup

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
BideaseAdapterAdmob Initialization end no error

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
