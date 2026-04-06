# Bidease Unity SDK — AdMob Custom Event (Android)

You are helping a developer integrate the Bidease SDK as a custom event in Google AdMob mediation inside a Unity project targeting Android.

Reference docs — fetch and read before proceeding:
- https://devs.bidease.com/docs/android-admob
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

- `2022.x` → **UNITY_2022** — AGP 7.4.2, Gradle 7.5.1 bundled
- `2023.x` or `6000.x` / `2024.x` → **UNITY_6** — AGP 8.x, Java 17
- `2021.x` or older → not supported. Stop: "Unity 2021 and older are not supported. Please upgrade to Unity 2022 LTS or Unity 6."

### 1.3 Check Google Mobile Ads SDK

```bash
find . -name "Dependencies.xml" | xargs grep -l -i "google-mobile-ads\|play-services-ads" 2>/dev/null
find . -name "GoogleMobileAdsSettings.asset" 2>/dev/null | head -1
```

If AdMob **not found** — stop: "Google Mobile Ads SDK is required for Bidease adapter integration."
Share: https://developers.google.com/admob/unity/quick-start

If **found** — note the AdMob SDK version. Bidease requires **AdMob ≥ 23**. Then detect active ad formats:

```bash
grep -r "BannerView\|AdView" Assets/ --include="*.cs" 2>/dev/null
grep -r "InterstitialAd" Assets/ --include="*.cs" 2>/dev/null
grep -r "RewardedAd" Assets/ --include="*.cs" 2>/dev/null
grep -r "AppOpenAd" Assets/ --include="*.cs" 2>/dev/null
```

Report which formats are active — Bidease will be integrated for those.

---

## Step 2: Check Gradle templates

```bash
ls Assets/Plugins/Android/mainTemplate.gradle \
   Assets/Plugins/Android/baseProjectTemplate.gradle \
   Assets/Plugins/Android/gradleTemplate.properties 2>/dev/null
```

**For UNITY_2022** — all three files are required. If any are missing:
```
Please enable in Unity Editor:
Edit → Project Settings → Player → Android → Publishing Settings
  ✓ Custom Main Gradle Template
  ✓ Custom Gradle Properties Template
  ✓ Custom Base Gradle Template
Then re-run this command.
```

**For UNITY_6** — only `mainTemplate.gradle` and `gradleTemplate.properties` are required. If missing — check whether `GoogleMobileAdsSettings.asset` was created (EDM4U generates templates automatically when opened). If still missing — ask to enable manually in Publishing Settings.

Do not proceed without the required templates.

---

## Step 3: Patch Gradle templates

### 3.1 baseProjectTemplate.gradle — UNITY_2022 only

Skip this section entirely for UNITY_6.

**a) Add Kotlin Android plugin 2.3.0**

Find the `plugins {}` block. If the Kotlin plugin is missing or version < 2.3.0 — add/update:

```groovy
id 'org.jetbrains.kotlin.android' version '2.3.0' apply false
```

**b) Force slf4j-api to 1.7.36**

Add inside `allprojects {}`:
```groovy
configurations.all {
    resolutionStrategy {
        force 'org.slf4j:slf4j-api:1.7.36'
    }
}
```

### 3.2 mainTemplate.gradle

Read the current file. Locate the `dependencies {}` block and add after `**DEPS**`.

**Important:** check if the closing `}` of `dependencies {}` is on the same line as `**DEPS**` (Unity 6 style: `**DEPS**}`) — if so, split it before inserting.

**UNITY_2022:**

```groovy
// Bidease SDK
// admob-adapter pulls bidease-mobile transitively without @aar,
// causing variant disambiguation failure in AGP 7.4.2 (StackOverflowError / could not resolve).
implementation('com.bidease:admob-adapter:2.0.2') {
    exclude group: 'com.bidease', module: 'bidease-mobile'
}
implementation('com.bidease:bidease-mobile:2.0.2@aar')

// Transitive dependencies
implementation 'org.jetbrains.kotlin:kotlin-stdlib:2.3.0'
implementation 'androidx.javascriptengine:javascriptengine:1.0.0-beta01'
implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2'
implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-guava:1.10.2'
implementation 'io.ktor:ktor-client-okhttp-jvm:3.3.3'
implementation 'io.ktor:ktor-client-core-jvm:3.3.3'
implementation 'io.ktor:ktor-client-encoding-jvm:3.3.3'
implementation 'io.ktor:ktor-client-logging-jvm:3.3.3'
implementation 'org.jetbrains.kotlinx:kotlinx-serialization-json-jvm:1.10.0'
implementation 'com.google.android.gms:play-services-ads-identifier:18.3.0'
implementation 'com.google.android.gms:play-services-appset:16.1.0'
```

**UNITY_6:**

```groovy
// Bidease SDK
implementation('com.bidease:admob-adapter:2.0.2') {
    exclude group: 'com.bidease', module: 'bidease-mobile'
}
implementation('com.bidease:bidease-mobile:2.0.2@aar')

// Transitive dependencies
implementation 'org.jetbrains.kotlin:kotlin-stdlib:2.3.0'
implementation 'androidx.javascriptengine:javascriptengine:1.0.0'
implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2'
implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-guava:1.10.2'
implementation 'io.ktor:ktor-client-okhttp-jvm:3.3.3'
implementation 'io.ktor:ktor-client-core-jvm:3.3.3'
implementation 'io.ktor:ktor-client-encoding-jvm:3.3.3'
implementation 'io.ktor:ktor-client-logging-jvm:3.3.3'
implementation 'org.jetbrains.kotlinx:kotlinx-serialization-json-jvm:1.10.0'
implementation 'com.google.android.gms:play-services-ads-identifier:18.3.0'
implementation 'com.google.android.gms:play-services-appset:16.1.0'
```

### 3.3 gradleTemplate.properties

Ensure the following are present:

```properties
android.useAndroidX=true
android.enableJetifier=true
```

---

## Step 4: Set Bidease App Key

Bidease requires its own App Key set **before** AdMob is initialized.

`BideaseMobileSDK` is **not** a Unity C# package — the SDK is delivered as an AAR via Gradle without a Unity wrapper. Use `AndroidJavaClass` to call into the native Android class directly.

Ask the user for their Bidease App Key if not already known — it is found in **monetize.bidease.com → Applications → [App] → App Key**.

Find the C# file where `MobileAds.Initialize()` is called — typically the main scene controller. Add the following immediately before that call:

```csharp
#if UNITY_ANDROID && !UNITY_EDITOR
using (var adapter = new AndroidJavaClass("com.bidease.ads.adapter.admob.BideaseMediationAdapter"))
{
    adapter.CallStatic("setAppKey", "YOUR_BIDEASE_APP_KEY");
}
#endif
```

---

## Step 5: Verify Android build settings

### 5.1 minSdkVersion

Bidease SDK requires `minSdkVersion ≥ 26`:

```bash
grep "AndroidMinSdkVersion" ProjectSettings/ProjectSettings.asset
```

If below 26 — update in `ProjectSettings.asset`.

### 5.2 compileSdkVersion

`mainTemplate.gradle` uses the `**APIVERSION**` placeholder — Unity substitutes it from `ProjectSettings.asset` at build time, so the template itself is not the source of truth.

Check the actual value:

```bash
grep "AndroidTargetSdkVersion" ProjectSettings/ProjectSettings.asset
```

- Value `0` → **Auto** — Unity uses the latest installed SDK, which is typically ≥ 36. No action needed.
- Value `< 36` → Update in Unity Editor: **Player Settings → Android → Other Settings → Target API Level → set to 36 or Auto**.

### 5.3 BuildScript.cs — enforce settings at build time

Check if `Assets/Editor/BuildScript.cs` already exists:

```bash
ls Assets/Editor/BuildScript.cs 2>/dev/null && echo "exists" || echo "not found"
```

**If the file exists** — read it and only verify that `minSdkVersion` is set to `AndroidApiLevel26`. Do not overwrite the file — it may contain custom bundle ID, iOS settings, or signing configuration.

**If the file does not exist** — create it:

```csharp
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

public class BuildScript
{
    public static void BuildAndroid()
    {
        PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "<bundle_id>");
        PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
        PlayerSettings.Android.targetSdkVersion = (AndroidSdkVersions)34;

        BuildPlayerOptions options = new BuildPlayerOptions();
        options.scenes = GetScenes();
        options.locationPathName = "/tmp/build.apk";
        options.target = BuildTarget.Android;
        options.options = BuildOptions.None;

        var report = BuildPipeline.BuildPlayer(options);
        if (report.summary.result == BuildResult.Succeeded)
            Debug.Log("Build succeeded: " + report.summary.outputPath);
        else
            Debug.LogError("Build failed: " + report.summary.result);
    }

    private static string[] GetScenes()
    {
        var scenes = new System.Collections.Generic.List<string>();
        foreach (var scene in EditorBuildSettings.scenes)
            if (scene.enabled) scenes.Add(scene.path);
        return scenes.ToArray();
    }
}
```

Replace `<bundle_id>` with the actual application identifier from `ProjectSettings.asset`.

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
   - Class Name: com.bidease.ads.adapter.admob.BideaseMediationAdapter  (same for all formats)
   - Parameter: AdFormat_ecpm_X.X  (must match the Label exactly)

5. Click Done → Save

Repeat for each ad format and floor price tier.
In case of any questions please refer to the documentation: https://devs.bidease.com/docs/android-admob#3-add-custom-events-in-admob-mediation
```

---

## Step 7: Build and verify

### 7.1 Find Unity executable

```bash
UNITY_VERSION=$(cat ProjectSettings/ProjectVersion.txt | grep "m_EditorVersion:" | awk '{print $2}')
find /Applications/Unity/Hub/Editor -name "Unity" -path "*${UNITY_VERSION}*" -type f 2>/dev/null | head -1
```

### 7.2 Clear build cache (if rebuilding after Gradle changes)

```bash
rm -rf Library/Bee
```

### 7.3 Run build in batch mode

Close the Unity Editor first.

```bash
"<unity_path>" \
  -batchmode \
  -nographics \
  -projectPath "$(pwd)" \
  -executeMethod BuildScript.BuildAndroid \
  -logFile /tmp/unity_build.log \
  -quit
echo "Exit code: $?"
```

On failure — read the log:
```bash
grep -E "error |Error |FAILED|Exception|StackOverflow" /tmp/unity_build.log | grep -v "^#" | tail -40
```

### 7.4 Verify integration

If the build succeeded — tell the user:

```
Build succeeded. APK is at /tmp/build.apk.

Install on a connected device:
  adb install -r /tmp/build.apk

Then filter logcat by the keyword "Bidease":
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
- `CertPathValidatorException` — SSL proxy interfering, test without proxy.
- `bid failure 204` — no fill, normal behavior.

### 7.5 Known build errors

| Error | Unity | Cause | Fix |
|-------|-------|-------|-----|
| `Could not resolve com.bidease:bidease-mobile` / variant disambiguation failure | 2022 | `admob-adapter` pulls `bidease-mobile` transitively without `@aar`; AGP 7.4.2 cannot select among `androidApiElements-published`, `androidRuntimeElements-published`, `androidSourcesElements-published` variants | Add `exclude group: 'com.bidease', module: 'bidease-mobile'` inside `admob-adapter` block and declare `bidease-mobile:2.0.2@aar` explicitly — see Step 3.2 |
| `NullPointerException` in D8 / dexer | 2022 | `slf4j-api 2.0.x` | Add `force 'org.slf4j:slf4j-api:1.7.36'` in Step 3.1 |
| `uses-sdk:minSdkVersion X cannot be smaller than 26` | both | minSdk too low | Update in Step 5.1 |
| `Bidease init failure: ...JavaScriptSandbox` | 2022 | `javascriptengine` version wrong | Use `1.0.0-beta01` for Unity 2022 |

---

## Step 8: Report results

Summarize to the user:

1. Unity version detected and path taken (UNITY_2022 / UNITY_6)
2. Files modified — list each file and what was changed
3. Dependencies added
4. Build result
5. Logcat status: init success or failure, which bid formats are active

Only report issues that require action. Skip harmless log entries.
