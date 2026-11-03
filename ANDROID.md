# Android debug build and phone testing

## Current status

A signed debug APK was rebuilt and verified on 25 October 2026:
`builds/parkshift-debug.apk` (171,217,786 bytes; approximately 163.3 MiB).
Its SHA-256 and build timestamp are in `builds/parkshift-debug.build.json`.
The earlier 23 October build was installed on 25 October 2026 on the connected Samsung
SM-A175F with `adb install -r`. Android reported a successful cold launch
(`Status: ok`, activity startup 737 ms). The same process remained alive and in
the foreground after at least one minute. Screenshots showed the garage and a
rendered Level 2 gameplay screen. App-filtered logcat contained no fatal crash or
Godot script errors, and the process's crash buffer was empty. This is a startup
smoke test, not a full gameplay, persistence or performance acceptance pass.
Evidence: `artifacts/phone_launch_result.txt`, `phone_launch_logcat.txt`,
`phone_launch_crash.txt` and `phone_launch.png`.

The earlier controls UI update was installed successfully on the same phone with
`adb install -r`, preserving app data. It contains one swipe-scrollable list of
all 12 garage cars (without Previous/Next pagination), pressed-only pedal
highlighting, 124-pixel base touch targets and a compact parking feedback panel.
Full target/reward details remain available in Pause. Graphical UI checks passed
21 assertions; campaign/persistence checks passed 439 + 4 assertions. See
`artifacts/mobile_ui_checks.log`, `mobile_ui_*.png` and
`mobile_ui_phone_install.txt`. Manual testing of this update is left to the user.
That controls update's SHA-256 was
`3531EA2F26226BAF4A1DD1EBF88266F05C625A5E352C32F186BF0F81DA4558D9`.

The workshop redesign was subsequently built, signed and installed with
`adb install -r`, preserving data. Its SHA-256 is
`9AFF6EC9B7243B91846A7CFFE07BC9496F461FAD6F91BAB12A04DEFB5342FEBA`.
The app process started with Godot's Compatibility renderer and no fatal/script
errors in startup logs. The phone was locked during the final check, so phone
visual acceptance remains for the user after unlocking. Desktop renders of all
menus and five district scenes were inspected. Evidence: `artifacts/workshop_phone_install.txt`,
`workshop_phone_launch.txt`, `workshop_phone_logcat.txt`, `realism_workshop_*.png`.
See [WORKSHOP_UI.md](WORKSHOP_UI.md) for the design and checks.

The district environment update was signed,
verified and installed on the Samsung SM-A175F with `adb install -r`, retaining
the existing app data. SHA-256:
`AB1FF89480C6AEE0F7221DE805BB0B001E0FD06375971AEDD6C6DF07C52F2A7E`.
The launcher reported `Status: ok`, a cold activity start of 1374 ms, and the app
process remained alive. The phone screenshot showed the rendered home screen
with the existing 5 completed levels, 14 stars and 519 credits. App-filtered
startup logs contained zero fatal/script errors and the crash buffer was empty.
Level 6 also loaded and rendered the updated courtyard on the phone; after this
gameplay load the app log still had zero fatal/script errors and no crash entries.
The app was returned to its home screen for the user's own testing.
Evidence: `artifacts/environment_phone_install.txt`, `environment_phone_launch.txt`,
`environment_phone_logcat.txt`, `environment_phone_crash.txt`, `environment_phone.png`,
`environment_phone_gameplay.png`.
All five district scenes were reviewed on desktop; all 100 collision layouts
matched their pre-change baseline. See [DISTRICT_ENVIRONMENTS.md](DISTRICT_ENVIRONMENTS.md).
Hands-on gameplay and sustained phone performance remain user checks.

The current installed build adds an adjustable camera: scene drag to orbit/tilt,
pinch to zoom, Front/Rear presets and Reset view, with a lower default driving
angle. It passed 33 camera input/layout/collision checks plus the existing mobile
UI, campaign/progression and sampled driving checks. See [CAMERA_CONTROLS.md](CAMERA_CONTROLS.md).
It was signed and installed with `adb install -r`, preserving data. SHA-256:
`073BEAA3684F2F40518E07243E24F2C4CB48AF3EE3E32D24E967B8D0E3DC1544`.
Android reported a successful cold start (1352 ms); initial app-filtered logs had
no fatal/script errors and the crash buffer was empty. Evidence:
`artifacts/camera_phone_install.txt`, `camera_phone_launch.txt`,
`camera_phone_logcat.txt`, `camera_phone_crash.txt`.
The phone then showed Level 13 gameplay with the selected imported convertible
and the new camera toolbar (`artifacts/camera_phone_level.png`). App-filtered
gameplay logs still had zero fatal/script errors and no crash-buffer entries.

- Package: `com.parkshift.prototype`; version `0.1.0`, code `1`.
- ARM64 only; minimum Android API 24, target/compile API 36.
- Debuggable, with verified APK Signature Schemes v2 and v3.
- Existing debug key retained: certificate SHA-256
  `84cc6ecc085d74479b60804675d4adb1ff112eb0bf6b3f0ca8416dd95e4d197b`.
- All 100 campaign records, economy/imported-car JSON and the campaign validator
  are present. The 12 vehicle import mappings are included. Tools, test artifacts
  and the build directory are excluded from packaged project assets.
- Legacy/adaptive/monochrome PARKSHIFT icon assets are assigned.

`aapt2` inspection exits successfully but reports an unused template resource
reference to `res/mipmap-anydpi-v26/themed_icon.xml` that is not present. The
assigned adaptive icon is present as `res/mipmap-anydpi-v26/icon.xml`. Signature
and package verification pass; themed launcher behavior remains a device check.
The diagnostic is retained in `artifacts/android_badging_warnings.txt`.

## Setup completed

- Downloaded the standard Godot 4.7.2 template archive from the
  [official release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).
  Verified its SHA-512 against the release's `SHA512-SUMS.txt` before extraction.
- Installed `android_debug.apk`, `android_release.apk` and `version.txt` under
  `%APPDATA%/Godot/export_templates/4.7.2.stable/`. Other platform templates and
  Gradle sources were not needed for this standard APK export.
- Configured Godot's Editor Settings:
  - `export/android/java_sdk_path`: `C:/Program Files/Android/Android Studio/jbr`
    (installed OpenJDK 21.0.9).
  - `export/android/android_sdk_path`: `%LOCALAPPDATA%/Android/Sdk`.
- The previous editor settings are backed up in
  `artifacts/editor_settings_before_android.tres`.
- Preserved the application ID, version and `builds/debug.keystore`.
  Do not regenerate the key when updating an existing phone installation.

The original failed setup report is preserved in [PHASE9_ANDROID.md](PHASE9_ANDROID.md).
The [Godot Android export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
provides setup guidance for other machines. Godot's SDK and Java Editor Settings
must match the paths used by the build script on that machine.

## Rebuild

From this project folder in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_android.ps1
```

The script accepts `-Godot`, `-AndroidSdk` and `-JavaSdk` path overrides. It exports
to a pending APK, checks the Godot log and process exit code, verifies the signature,
checks package/debug/ABI metadata and required packaged assets, then replaces the
final APK only after success. It retains the build log, signature report and
package report under `artifacts/`, and writes a SHA-256 build manifest beside the APK.
The development key is required; the script never generates a replacement.

## Install on a phone

For manual installation, copy `builds/parkshift-debug.apk` to the phone and open
it there. Android may require allowing installation from that file manager.

For USB installation, enable Developer options and USB debugging, connect the
phone, and authorize the computer. From this project folder:

```powershell
$adb = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
& $adb devices -l
& $adb install -r 'builds/parkshift-debug.apk'
```

If several devices are listed, add `-s SERIAL` before `install`. A Samsung SM-A175F
was connected and reported ARM64 support and API 36 during the build inspection;
the 25 October startup smoke test above confirmed installation and launch.
Launch PARKSHIFT from the phone's launcher.

`install -r` updates the app while retaining its data when package/signing identity
matches. Do not uninstall or clear storage to resolve an update problem if you
need existing progress. Windows and Android saves remain separate.

## Phone checks still needed

- Launch and inspect the home screen and all garage previews, including themed icons.
- Check landscape fit, navigation insets and simultaneous steering/pedal touches.
- Drive, reverse, collide, finish parking and confirm rewards and unlocks.
- Purchase/select a car, close/reopen the app and confirm saved state.
- Check pause, Home/background/resume, screen lock, Android Back, audio and haptics.
- Measure cold loading, sustained frame rate, memory and heat with dense imported cars.

This is a local debug build. The detailed-car trial asset restrictions remain as
recorded in `assets/cars/TRIAL_ASSETS.md`.
