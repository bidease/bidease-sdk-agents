# Bidease Android SDK — AppLovin MAX Custom Adapter (Unity)

You are helping a developer integrate the Bidease SDK as a custom network in AppLovin MAX inside a Unity project targeting Android.

Reference docs — fetch and read before proceeding:
- https://devs.bidease.com/docs/kmp-android-max-adapter
- https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/

---

## Step 1: Detect and validate the project

### 1.1 Confirm Unity project

Check for:
- `ProjectSettings/ProjectSettings.asset`
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

Check which templates exist:

```bash
ls Assets/Plugins/Android/mainTemplate.gradle \
   Assets/Plugins/Android/baseProjectTemplate.gradle \
   Assets/Plugins/Android/gradleTemplate.properties 2>/dev/null
```

**For UNITY_2022** — all three files are required:

- If `mainTemplate.gradle` or `gradleTemplate.properties` are missing:
  ```
  Please enable in Unity Editor:
  Edit → Project Settings → Player → Android → Publishing Settings
    ✓ Custom Main Gradle Template
    ✓ Custom Gradle Properties Template
  Then re-run this command.
  ```

- If `baseProjectTemplate.gradle` is missing:
  ```
  Please also enable:
    ✓ Custom Base Gradle Template
  Then re-run this command.
  ```

**For UNITY_6** — `baseProjectTemplate.gradle` is not needed. Only `mainTemplate.gradle` and `gradleTemplate.properties` are required.

- If they are missing: check whether `AppLovinSettings.asset` was created (EDM4U generates the templates automatically when Integration Manager is opened):
  ```bash
  find . -path "*/MaxSdk*" -name "AppLovinSettings.asset" 2>/dev/null
  ```
  If missing — ask the user to open `Window → AppLovin → Integration Manager` once, then re-run.
  If present but templates still missing — ask to enable manually:
  ```
  Edit → Project Settings → Player → Android → Publishing Settings
    ✓ Custom Main Gradle Template
    ✓ Custom Gradle Properties Template
  ```

Do not proceed without the required templates.

---

## Step 3: Patch Gradle templates

### 3.1 baseProjectTemplate.gradle — UNITY_2022 only

Skip this section entirely for UNITY_6.

Read the file and apply both changes:

**a) Add Kotlin Android plugin 2.3.0**

Bidease SDK 2.0.1 requires Kotlin 2.3.0. A mismatch causes a binary crash at build time (`InvalidProtocolBufferException: invalid tag zero`).

Find the `plugins {}` block. If the Kotlin plugin is missing or version < 2.3.0 — add/update:

```groovy
id 'org.jetbrains.kotlin.android' version '2.3.0' apply false
```

**b) Force slf4j-api to 1.7.36**

`slf4j-api 2.0.x` uses Java 9+ module metadata incompatible with D8 on AGP 7.x, causing `NullPointerException` in the dexer.

Add inside `allprojects {}`:
```groovy
configurations.all {
    resolutionStrategy {
        force 'org.slf4j:slf4j-api:1.7.36'
    }
}
```

Full expected result for `baseProjectTemplate.gradle`:

```groovy
plugins {
    id 'com.android.application' version '7.4.2' apply false
    id 'com.android.library' version '7.4.2' apply false
    id 'org.jetbrains.kotlin.android' version '2.3.0' apply false
    **BUILD_SCRIPT_DEPS**
}

allprojects {
    repositories {
        google()
        mavenCentral()
        **ARTIFACTORYREPOSITORY**
    }

    configurations.all {
        resolutionStrategy {
            force 'org.slf4j:slf4j-api:1.7.36'
        }
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
```

### 3.2 mainTemplate.gradle

Read the current file. Locate the `dependencies {}` block and add after `**DEPS**` (and after any Android Resolver entries).

**Important:** check if the closing `}` of `dependencies {}` is on the same line as `**DEPS**` (Unity 6 style: `**DEPS**}`) — if so, split it before inserting.

**UNITY_2022** — use `javascriptengine:1.0.0-beta01` (stable 1.0.0 requires AGP 8.1.1+):

```groovy
// Bidease SDK
implementation('com.bidease:applovin-adapter:2.0.1') {
    // applovin-adapter pulls bidease-mobile transitively without @aar,
    // causing StackOverflowError in AGP 7.x variant disambiguation.
    exclude group: 'com.bidease', module: 'bidease-mobile'
}
implementation('com.bidease:bidease-mobile:2.0.1@aar')

// Transitive dependencies — declared explicitly because @aar disables POM resolution
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

**UNITY_6** — use `javascriptengine:1.0.0` stable (AGP 8.x is compatible):

```groovy
// Bidease SDK
implementation('com.bidease:applovin-adapter:2.0.1') {
    exclude group: 'com.bidease', module: 'bidease-mobile'
}
implementation('com.bidease:bidease-mobile:2.0.1@aar')

// Transitive dependencies — declared explicitly because @aar disables POM resolution
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

Ensure the following are present (add if missing — skip if already injected by Android Resolver):

```properties
android.useAndroidX=true
android.enableJetifier=true
```

---

## Step 4: Verify Android build settings

### 4.1 minSdkVersion

Bidease SDK requires `minSdkVersion ≥ 26`:

```bash
grep "AndroidMinSdkVersion" ProjectSettings/ProjectSettings.asset
```

If below 26 — update in `ProjectSettings.asset`.

### 4.2 targetSdkVersion

`androidx.startup` (AppLovin MAX 13.x dependency) requires `compileSdkVersion 34`:

```bash
grep "AndroidTargetSdkVersion" ProjectSettings/ProjectSettings.asset
```

If below 34 — update in `ProjectSettings.asset`.

### 4.3 BuildScript.cs — enforce settings at build time

Unity's build pipeline can override PlayerSettings set in the UI. Create or update `Assets/Editor/BuildScript.cs`.

If the file already exists — read it first and add only the missing lines.

```csharp
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

public class BuildScript
{
    public static void BuildAndroid()
    {
        // Enforced programmatically — Unity may override Project Settings UI values at build time
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

## Step 5: AppLovin MAX dashboard setup

Tell the user the following (include the links as clickable text) and wait for confirmation before proceeding:

---

**Manual steps required in AppLovin MAX dashboard:**

1. Go to **MAX Dashboard → Mediation → Manage Networks → Add Custom Network**
   - Guide: https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/
   - Bidease adapter docs: https://devs.bidease.com/docs/kmp-android-max-adapter

2. Fill in:
   - Network Type: **SDK**
   - Network Name: **Bidease**
   - Android Adapter Class: `com.bidease.ads.adapter.applovin.BideaseMediationAdapter`

3. Enable Bidease on each Ad Unit and set **Placement ID** in the format:
   `AdFormat_ecpm_X.X` (e.g. `Interstitial_ecpm_1.3` for $1.30 floor price)
   Set the same value in the **CPM Price** field.

4. Wait **30–60 minutes** before testing — changes take time to propagate.

---

Wait for the user to confirm they've completed the dashboard steps before building.

---

## Step 6: Build and verify

### 6.1 Clear build cache (if rebuilding after Gradle changes)

```bash
rm -rf Library/Bee
```

### 6.2 Find Unity executable

```bash
# macOS — picks the version matching the project
UNITY_VERSION=$(cat ProjectSettings/ProjectVersion.txt | grep "m_EditorVersion:" | awk '{print $2}')
find /Applications/Unity/Hub/Editor -name "Unity" -path "*${UNITY_VERSION}*" -type f 2>/dev/null | head -1
```

### 6.3 Run build in batch mode

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

### 6.4 Known build errors and fixes

| Error | Unity | Cause | Fix |
|-------|-------|-------|-----|
| `StackOverflowError` in Gradle resolution | 2022 | `applovin-adapter` pulling `bidease-mobile` without `@aar` | Add `exclude` in Step 3.2 |
| `NullPointerException` in D8 / dexer | 2022 | `slf4j-api 2.0.x` | Add `force 'org.slf4j:slf4j-api:1.7.36'` in Step 3.1 |
| Kotlin plugin not found | 2022 | Missing from `baseProjectTemplate.gradle` | Add Kotlin 2.3.0 plugin in Step 3.1 |
| `uses-sdk:minSdkVersion X cannot be smaller than 26` | both | minSdk too low | Set `minSdkVersion = 26` in Step 4.3 |
| `androidx.startup` compileSdk error | both | targetSdk < 34 | Set `targetSdkVersion = 34` in Step 4.2 |

### 6.5 Install and run

If build succeeded — tell the user:

```
Build succeeded. APK is at /tmp/build.apk.

Next steps:
1. Connect your Android device via USB
2. Install and launch:
   adb install -r /tmp/build.apk
   adb shell am start -n <bundle_id>/com.unity3d.player.UnityPlayerActivity
3. Let the app fully load to the main screen
4. Let me know when it's running — I'll check the logs.
```

Wait for the user to confirm before checking logcat.

### 6.6 Check logcat

```bash
# Find PID of the running app, then check its Bidease logs
adb logcat -d | grep "System.out.*Bidease\|Bidease.*System.out"
```

Expected on successful init:
```
Bidease init success
Bidease Interstitial start bid
Bidease Rewarded start bid
```

If init failed — check for these actionable errors:

| Log message | Cause | Fix |
|-------------|-------|-----|
| `Bidease init failure: Failed resolution of: Landroidx/javascriptengine/JavaScriptSandbox` | `javascriptengine` not in DEX | Unity 2022: verify `1.0.0-beta01` is declared. Unity 6: verify `1.0.0` is declared. |
| `Module with the Main dispatcher is missing` | `kotlinx-coroutines-android` missing | Verify it is declared explicitly in Step 3.2 |
| `NoClassDefFoundError: io/ktor/...` | Ktor not in DEX | Verify all 4 Ktor deps are declared in Step 3.2 |

Do not report or explain harmless log entries (`bid failure 204`, DNS errors, IPv6 ping failures). Only surface issues that require action.

---

## Step 7: Report results

Summarize to the user:

1. Unity version detected and path taken (UNITY_2022 / UNITY_6)
2. Files modified — list each file and what was changed
3. Dependencies added
4. Workarounds applied and why (only if relevant to detected version)
5. Build result
6. Logcat status: init success or failure, which bid formats are active

Only report issues that require action. Skip harmless log entries.
