# Bidease Android SDK — AdMob Custom Event

You are helping a developer integrate the Bidease SDK as a custom event in Google AdMob mediation for a native Android project.

Reference docs — fetch and read before proceeding:
- https://devs.bidease.com/docs/android-admob
- https://developers.google.com/admob/android/quick-start

## Step 1: Detect project type

- `build.gradle` or `build.gradle.kts` present → Native Android, proceed.
- Otherwise → stop: "This command currently supports Native Android projects only."

## Step 2: Inspect the project

### 2.1 Google Mobile Ads SDK

Check `build.gradle` / `build.gradle.kts` and source files for `play-services-ads` dependency or `import com.google.android.gms.ads`.

- If **not found**: AdMob SDK is required. Share the setup guide: https://developers.google.com/admob/android/quick-start — then stop.
- If **found**: check the version. Bidease requires **AdMob ≥ 23**. If lower — ask the user to update before proceeding.

### 2.2 AdMob App ID

Search for `com.google.android.gms.ads.APPLICATION_ID` in `AndroidManifest.xml`. Note the value (`ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`) if found.

### 2.3 Ad formats

Scan source files for usage of:
- `AdView` or `BannerAd` → Banner
- `InterstitialAd` → Interstitial
- `RewardedAd` → Rewarded
- `AppOpenAd` → App Open

Report which formats are found — Bidease adapter will be integrated for those.

## Step 3: Add dependencies and verify requirements

Read the project's `build.gradle` / `build.gradle.kts` files, then apply the following in order:

### 3.1 Minimum SDK and compile SDK

Verify in `app/build.gradle`:
- `minSdkVersion` ≥ **26** — if lower, update it.
- `compileSdkVersion` ≥ **36** — if lower, update it.
- `sourceCompatibility` and `targetCompatibility` set to **Java 8** or higher.

### 3.2 Add Bidease dependencies

```groovy
implementation("com.bidease:bidease-mobile:2.0.2")
implementation("com.bidease:admob-adapter:2.0.2")
```

### 3.3 Check local.properties

Verify `local.properties` exists in the project root with:
```
sdk.dir=/Users/<username>/Library/Android/sdk
```
This file is git-ignored by default. If missing — create it.

### 3.4 Java version for Gradle

Gradle 8.x supports up to **Java 21**. If the system Java is higher (e.g. OpenJDK 25 via Homebrew), the build will fail with:
```
Unsupported class file major version 69
```

Use Android Studio's bundled JDK when building from terminal:
```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew assembleDebug
```

## Step 4: Set Bidease App Key

Bidease requires its own App Key set **before** AdMob is initialized.

Find the file where `MobileAds.initialize(context)` is called — typically `Application` or `MainActivity`. Add the following immediately before that call:

```kotlin
import com.bidease.ads.adapter.admob.BideaseMediationAdapter

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
   - Class Name: com.bidease.ads.adapter.admob.BideaseMediationAdapter  (same for all formats)
   - Parameter: AdFormat_ecpm_X.X  (must match the Label exactly)

5. Click Done → Save

Repeat for each ad format and floor price tier.
In case of any questions please refer to the documentation: https://devs.bidease.com/docs/android-admob#3-add-custom-events-in-admob-mediation
```

## Step 6: Build and verify

### 6.1 Build

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew assembleDebug
```

### 6.2 Verify integration

If the build succeeded — tell the user:

```
Build succeeded. The project is ready for testing.

To verify the integration, install the APK on a device and filter logcat
by the keyword "Bidease" in Android Studio or via:

  adb logcat | grep -i "bidease"

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
- `CertPathValidatorException` — SSL proxy (Fiddler/Charles) interfering, test without proxy.
- `bid failure 204` — no fill, normal behavior.

### 6.3 Test mode (optional)

To get near 100% fill during QA — add the test mode dependency and rebuild:

```groovy
implementation("com.bidease:bidease-mobile-test-mode:2.0.2")
```

Alternatively, enable via **monetize.bidease.com → Applications → [App] → Test Devices** — add the device by GAID and enable Test for the app.

**Disable test mode before submitting to Google Play.**

Report results to the user with a summary of what's working.
