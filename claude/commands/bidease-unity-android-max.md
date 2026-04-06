# Bidease Unity SDK — AppLovin MAX Custom Adapter (Android)

You are helping a developer integrate the Bidease SDK as a custom network in AppLovin MAX mediation inside a Unity project targeting Android.

Reference docs — fetch and read before proceeding:
- https://devs.bidease.com/docs/android-applovin
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

Extract the major version and save it — all subsequent steps branch on this:

- `2022.x` → **UNITY_2022** — AGP 7.4.2, Gradle 7.5.1 bundled
- `2023.x` or `6000.x` / `2024.x` → **UNITY_6** — AGP 8.x, Java 17
- `2021.x` or older → not supported. Stop: "Unity 2021 and older are not supported. Please upgrade to Unity 2022 LTS or Unity 6."

### 1.3 Check AppLovin MAX SDK

```bash
find . -name "Dependencies.xml" | xargs grep -l -i "applovin" 2>/dev/null
find . -path "*/MaxSdk*" -name "AppLovinSettings.asset" 2>/dev/null | head -1
```

If MAX **not found** — stop: "AppLovin MAX SDK is required for Bidease adapter integration."
Share: https://support.axon.ai/en/max/unity/overview/integration/

If **found** — note the MAX SDK version, then detect active ad formats:

```bash
grep -r "MaxSdk.CreateBanner\|MaxBannerAd\|MaxSdkCallbacks.Banner" Assets/ --include="*.cs" 2>/dev/null
grep -r "MaxSdk.LoadInterstitial\|MaxInterstitialAd\|MaxSdkCallbacks.Interstitial" Assets/ --include="*.cs" 2>/dev/null
grep -r "MaxSdk.LoadRewardedAd\|MaxRewardedAd\|MaxSdkCallbacks.Rewarded" Assets/ --include="*.cs" 2>/dev/null
grep -r "MaxSdk.CreateMRec\|MaxMRecAd\|MaxSdkCallbacks.MRec" Assets/ --include="*.cs" 2>/dev/null
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

**For UNITY_6** — only `mainTemplate.gradle` and `gradleTemplate.properties` are required. If missing — ask the user to open `Window → AppLovin → Integration Manager` once, then re-run.

Do not proceed without the required templates.

---

## Step 3: Patch Gradle templates

### 3.1 baseProjectTemplate.gradle — UNITY_2022 only

Skip this section entirely for UNITY_6.

Read the file and apply both changes:

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
implementation('com.bidease:applovin-adapter:2.0.2') {
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
implementation('com.bidease:applovin-adapter:2.0.2') {
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

Bidease requires its own App Key set **before** AppLovin MAX is initialized.

Find the C# file where `MaxSdk.SetSdkKey()` or `MaxSdk.InitializeSdk()` is called — typically the main scene controller. Add the following immediately before the MAX initialization call:

```csharp
// Set Bidease App Key before initializing AppLovin MAX
MaxSdk.SetCustomData("bidease_app_key", "YOUR_BIDEASE_APP_KEY");
```

Ask the user for their Bidease App Key if not already known — it is found in **monetize.bidease.com → Applications → [App] → App Key**.

---

## Step 5: Verify Android build settings

### 5.1 minSdkVersion

Bidease SDK requires `minSdkVersion ≥ 26`:

```bash
grep "AndroidMinSdkVersion" ProjectSettings/ProjectSettings.asset
```

If below 26 — update in `ProjectSettings.asset`.

### 5.2 targetSdkVersion

```bash
grep "AndroidTargetSdkVersion" ProjectSettings/ProjectSettings.asset
```

If below 34 — update in `ProjectSettings.asset`.

### 5.3 BuildScript.cs — enforce settings at build time

Unity's build pipeline can override PlayerSettings set in the UI. Check if `Assets/Editor/BuildScript.cs` exists. If not — create it:

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

## Step 6: AppLovin MAX dashboard setup

Tell the user the following and wait for confirmation before proceeding:

```
Manual steps required in AppLovin MAX dashboard (dash.applovin.com):

1. Go to MAX → Mediation → Manage → Networks
   Scroll to the bottom → click "Click here to add a Custom Network"

2. Fill in:
   - Network Type: SDK
   - Network Name: Bidease
   - Android Adapter Class: com.bidease.ads.adapter.applovin.BideaseMediationAdapter

3. Click Save, then go to MAX → Mediation → Manage → Ad Units
   Select the ad unit → find Bidease in the custom networks list → enable it

4. Enter placement details:
   - App ID: your Bidease App Key
   - Placement ID: AdFormat_ecpm_X.X  (e.g. "Interstitial_ecpm_1.3" for $1.30 floor price)
   - CPM Price: same floor price value as in Placement ID

5. Click Save

Repeat for each ad unit and floor price tier.
Wait 30–60 minutes for changes to take effect.
In case of any questions please refer to the documentation: https://devs.bidease.com/docs/android-applovin
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

Close the Unity Editor first — batch mode cannot run while the Editor has the project open.

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

### 7.5 Known build errors

| Error | Unity | Cause | Fix |
|-------|-------|-------|-----|
| `StackOverflowError` in Gradle resolution | 2022 | `applovin-adapter` pulling `bidease-mobile` without `@aar` | Add `exclude` in Step 3.2 |
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

Only report issues that require action. Skip harmless log entries (`bid failure 204`, DNS errors).
