# Bidease Android SDK — AppLovin MAX Custom Adapter

You are helping a developer integrate the Bidease SDK as a custom network in AppLovin MAX.

Reference docs — fetch and read before proceeding:
- https://devs.bidease.com/update/docs/android-applovin
- https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/

## Step 1: Detect project type

- `build.gradle` or `build.gradle.kts` present → Native Android, proceed
- Otherwise → stop, say: "This command currently supports Native Android projects only."

## Step 2: Inspect the project

Scan the project files to determine:

1. **AppLovin MAX mediation** — check `build.gradle` / `build.gradle.kts` and source files for AppLovin MAX SDK dependency (`applovin-sdk`) and usage.
   - If MAX is **not found**: tell the user that AppLovin MAX mediation is required for Bidease adapter integration and share the setup guide: https://support.axon.ai/en/max/android/overview/integration/ — then stop.
   - If MAX is **found**: proceed.

2. **`app_key`** — search for the AppLovin SDK key in the project (commonly in `AndroidManifest.xml` as `applovin.sdk.key` or passed to `AppLovinSdk.getInstance()`). Note the value if found.

3. **Ad formats already implemented** — scan source files for usage of:
   - `MaxAdView` or `MaxBannerAd` → Banner
   - `MaxInterstitialAd` → Interstitial
   - `MaxRewardedAd` → Rewarded
   - `MaxAdView` with MREC size → MREC

   Report which formats are found in the project — Bidease adapter will be integrated for those formats.

## Step 3: Add dependencies and verify requirements

Read the project's `build.gradle` / `build.gradle.kts` files, then apply the following in order:

### 3.1 Kotlin version — must be 2.3.0

Bidease SDK `2.0.1` is compiled with Kotlin 2.3.0. Using any older version causes a hard binary crash at build time:
```
InvalidProtocolBufferException: Protocol message contained an invalid tag (zero)
```

Check the Kotlin version in root `build.gradle`:
```groovy
classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.0"
```
Update to `2.3.0` if needed.

Also update the stdlib dependency in `app/build.gradle`:
```groovy
implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.3.0"
```

### 3.2 Compose compiler plugin (required for Kotlin 2.x)

In Kotlin 2.x, the Compose compiler must be applied as an explicit plugin — `composeOptions { kotlinCompilerExtensionVersion }` alone is no longer sufficient.

Root `build.gradle` — add to classpath:
```groovy
classpath "org.jetbrains.kotlin:compose-compiler-gradle-plugin:2.3.0"
```

`app/build.gradle` — apply the plugin:
```groovy
apply plugin: 'org.jetbrains.kotlin.plugin.compose'
```

Remove `kotlinCompilerVersion` from `composeOptions` if present — this field is removed in Kotlin 2.x and causes a build error. Keep only `kotlinCompilerExtensionVersion` (or omit it entirely with the new plugin).

### 3.3 Minimum SDK and Java version

Verify in `app/build.gradle`:
- `minSdkVersion` ≥ **26** — if lower, update it. Runtime will fail silently without this.
- `sourceCompatibility` and `targetCompatibility` set to **Java 8** or higher

### 3.4 Add Bidease dependencies

```groovy
implementation 'com.bidease:applovin-adapter:2.0.1'
implementation 'com.bidease:bidease-mobile:2.0.1'
```

### 3.5 Check local.properties

Verify `local.properties` exists in the project root with:
```
sdk.dir=/Users/<username>/Library/Android/sdk
```
This file is git-ignored by default. If missing — create it.

### 3.6 Java version for Gradle

Gradle 8.x supports up to **Java 21**. If the system Java is higher (e.g. OpenJDK 25 via Homebrew), the build will fail with:
```
Unsupported class file major version 69
```

Use Android Studio's bundled JDK when building from terminal:
```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew assembleDebug
```

### 3.7 Coroutines (if needed)

If `kotlinx.coroutines` errors appear in logcat after launch — add:
```groovy
implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2'
```

## Step 4: AppLovin MAX dashboard setup

Tell the user the following and wait for confirmation before proceeding:

```
Manual steps required in AppLovin MAX dashboard:

1. Go to MAX Dashboard → Mediation → Manage Networks → Add Custom Network
   Full guide: https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/

2. Fill in:
   - Network Type: SDK
   - Network Name: Bidease
   - Android Adapter Class: com.bidease.ads.adapter.applovin.BideaseMediationAdapter

3. Enable the network on each Ad Unit and set Placement ID using the format:
   AdFormat_ecpm_X.X  (e.g. "Interstitial_ecpm_1.3" for $1.30 floor price)
   Set the same value in the CPM Price field.

4. Wait 30–60 minutes for changes to take effect.
```

## Step 5: Build and verify

Build the project using Android Studio's JDK to avoid Java version conflicts:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew assembleDebug
```

Then ask the user to run the app on a connected device and check logcat:

```bash
adb logcat | grep -i "bidease"
```

Confirm these appear in the logs:
- `Bidease init success` — SDK initialized
- `Bidease [Format] bid success` — ad request successful
- `Bidease [Format] creative loaded` — ad ready to show

Known issues:
- `CertPathValidatorException` — SSL proxy (Fiddler/Charles) interfering, test without proxy
- `bid failure 204` — no fill, normal behavior

Report results to the user with a summary of what's working.
