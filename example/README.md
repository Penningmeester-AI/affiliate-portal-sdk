# Afflicate SDK Example App

Minimal Flutter app that initializes the SDK, shows the attribution result, and has a **Simulate Signup** button that prints the affiliate code. Use it to verify integration and to compare behavior with your own app.

## Run the example

From the **package root** (not inside `example/`):

```bash
cd example && flutter run
```

Or from the `example/` directory:

```bash
flutter run
```

## What the example does

- **main()**  
  Gets the initial app link (if any) via `app_links`, passes it to `Afflicate.setLaunchUrl()`, then calls `Afflicate.init()` with a demo config (`pk_live_xxx`, debug on in debug builds).

- **Home screen**  
  Displays:
  - `Attributed: true/false`
  - `Affiliate Code: <code> or None`
  - Match method and confidence when present  
  And a **Simulate Signup** button that prints the current affiliate code to the debug console.

No backend, auth, or analytics — only attribution and a minimal UI.

---

## How to verify the example app works

### 1. Automated test (CI / local)

From the **package root**:

```bash
cd example && flutter test
```

This runs a widget test that: initializes the SDK (with a short timeout so it doesn’t depend on the real API), builds the example app, and checks that the screen shows the attribution line and the **Simulate Signup** button. If this passes, the app and SDK wiring are working.

### 2. Manual run

1. **Start the app** (from package root):
   ```bash
   cd example && flutter run
   ```
   Pick a device/emulator when prompted.

2. **Check the screen**  
   You should see:
   - **Attributed: false** (or **true** if you use a real key and backend)
   - **Affiliate Code: None** (or a code if attributed)
   - A **Simulate Signup** button

3. **Tap Simulate Signup**  
   In the terminal/console where `flutter run` is running, you should see a line like:
   ```text
   Signup with code: null
   ```
   (or a code if attribution succeeded).

4. **With a real backend**  
   If you set `publicKey` to a valid key and your backend returns attribution for a given `click_id` (from URL or clipboard), you should see **Attributed: true** and an affiliate code; the button then prints that code.

If any of these steps fail, see [Troubleshooting](#troubleshooting) below.

---

## Test scenarios

Use these to confirm attribution and consent behavior. The example app is preconfigured with the scheme `afflicateexample` (Android intent filter and iOS URL type).

---

### Test 1 – Deterministic URL attribution (must have)

Validates that opening the app via a link with `click_id` is detected and sent to the backend.

**Android (copy-paste):**

1. Install and run the example app once, then close it (cold start needed for the next step).
2. From your machine (with device/emulator connected), run:

   ```bash
   adb shell am start -a android.intent.action.VIEW -d "afflicateexample://open?click_id=123e4567-e89b-12d3-a456-426614174000"
   ```

3. The app opens. **Verify:** With `debug: true`, the console shows something like `[Afflicate] Collected click_id_from_url: 123e4567-e89b-12d3-a456-426614174000, ...`. The screen shows **Attributed: true** and an affiliate code if your backend returns attribution for that `click_id`; otherwise **Attributed: false** (URL path is still validated).

**iOS:**

1. On the device/simulator, open **Safari** and in the address bar go to:
   ```text
   afflicateexample://open?click_id=123e4567-e89b-12d3-a456-426614174000
   ```
2. Confirm opening in the example app when prompted.
3. **Verify:** Same as Android — debug logs show the collected `click_id_from_url`; the screen shows the attribution result.

**Without a backend:** You still confirm the URL is parsed and the SDK sends the request (see [Debug output](#debug-output-example) below).

---

### Test 2 – Clipboard attribution (must have)

Validates that a valid UUID on the clipboard is read on cold start and used for attribution.

1. **Copy a valid UUID** to the clipboard, e.g.:
   ```text
   123e4567-e89b-12d3-a456-426614174000
   ```

2. **Cold start the app** — fully kill the example app, then open it again (so init runs and reads the clipboard once).

3. **Verify:**  
   - With `debug: true`, the console shows `[Afflicate] Collected ... click_id_from_clipboard: 123e4567-e89b-12d3-a456-426614174000, ...`.  
   - The screen **Attributed** value reflects the backend response (true if that `click_id` is attributed).  
   - If you had **Attributed: false** before, and the backend attributes this click_id, you should now see **Attributed: true** and an affiliate code — that confirms the clipboard path.

4. **Note:** On iOS 16+, the system may show a “pasted from…” banner. The SDK only reads once and clears the clipboard after reading.

---

### Debug output example

When `debug: true` in `AfflicateConfig` (e.g. `debug: kDebugMode` in the example), you should see logs like:

```text
[Afflicate] Collected click_id_from_url: null, click_id_from_clipboard: null, click_id_from_referrer: null
[Afflicate] Sending attribution request...
[Afflicate] API response 200: {"attributed":false}
[Afflicate] Attribution result: attributed=false
```

With a URL or clipboard `click_id`:

```text
[Afflicate] Collected click_id_from_url: 123e4567-e89b-12d3-a456-426614174000, click_id_from_clipboard: null, click_id_from_referrer: null
[Afflicate] Sending attribution request...
[Afflicate] API response 200: {"attributed":true,"affiliate_code":"AFF01"}
[Afflicate] Attribution result: attributed=true, affiliateCode=AFF01
```

This reassures that the SDK is collecting signals and calling the API correctly.

---

### Expected screen (screenshot)

When the app runs, you should see a screen like:

- **Title:** “Afflicate Example”
- **Attributed:** `true` or `false`
- **Affiliate Code:** a code or `None`
- **Simulate Signup** button

You can add a `screenshot.png` in the `example/` folder showing this screen for quick reference in the README.

---

### Test 3 – Consent disabled (no fingerprint)

1. In `example/lib/main.dart`, set `consentGiven: false` in `AfflicateConfig`:

   ```dart
   await Afflicate.init(AfflicateConfig(
     publicKey: 'pk_live_xxx',
     appId: 'com.example.affiliate_portal_sdk_example',
     consentGiven: false,  // no fingerprint signals
     debug: kDebugMode,
   ));
   ```

2. Run the app and trigger an attribution request (e.g. with a URL or clipboard `click_id` if your backend allows).

3. **Expected:**  
   In your backend or via debug logs, the request must **not** include fingerprint fields (`platform`, `os_version`, `screen_resolution`, `language`, `timezone`, `app_version`, `sdk_version`). Only deterministic signals (e.g. `click_id_from_url`, `click_id_from_clipboard`, `consent_given`, `is_test`) should be sent.

---

## Android Play Store referrer testing

**Referrer testing limitations:** Install referrer is provided only by the Google Play Store when the app is installed from a store link that includes referrer parameters. It is **not** available for local installs (`flutter run`, sideloaded APKs, or emulator installs). So you cannot fully validate the referrer path with the example app alone — use the **URL** (Test 1) and **clipboard** (Test 2) paths for deterministic verification. For referrer, use Internal testing (below) or rely on SDK/backend integration tests.

### Option A – Internal testing track (recommended)

1. Build an app bundle: `flutter build appbundle` (from your app or the example).
2. Upload the bundle to the [Play Console](https://play.google.com/console) and create an **Internal testing** release.
3. Add testers and get the **internal testing** link (optionally with referrer params).
4. Install the app from that link on a device (same Google account as tester).
5. Open the app and check attribution. The SDK reads the install referrer from the Play Store and sends it to the backend.

### Option B – adb (for development only)

You cannot inject the real Play Store referrer via `adb`. You can only simulate that the app was opened from a **link** (Test 1 above). To simulate install referrer locally you would need a custom build that injects a referrer string (not covered here; in production, only the Play Store provides it).

### adb for install referrer library

To confirm the Install Referrer library is called (no real referrer on local installs):

1. Run the example on an Android device/emulator: `flutter run`.
2. In Android Studio or via `adb logcat`, filter logs by your app or by `InstallReferrer`. You may see logs from `com.android.installreferrer` when the SDK runs.

### Known limitations

- **Sideload / `flutter run`:** No install referrer is available; the SDK will not send `click_id_from_referrer` from the store.
- **First launch after install:** Referrer is read once; later launches use cached attribution if already attributed.
- **Testing:** Use Internal testing (or Closed/Open testing) with a real install from a store link to verify end-to-end referrer attribution.

---

## Changing the config

Edit `example/lib/main.dart`:

- **publicKey:** Use your key from the Afflicate dashboard (or keep `pk_live_xxx` for a 401/error path).
- **appId:** Must match the example app’s package (e.g. `com.example.affiliate_portal_sdk_example`) or your own when you copy the example.
- **consentGiven:** `true` to send fingerprint data, `false` for deterministic-only (Test 3).
- **debug:** `kDebugMode` so debug builds get logs and `is_test: true` in requests.

---

## Troubleshooting

- **Attribution always false**  
  Ensure a valid `click_id` (UUID) is provided via URL or clipboard and that your backend returns `attributed: true` for that click. Check debug logs (and `debug: true`) for API responses.

- **URL not used**  
  Confirm you called `Afflicate.setLaunchUrl(uri?.toString())` (or equivalent) **before** `Afflicate.init()`, and that the URL contains `click_id` as a query parameter.

- **401 / invalid key**  
  The SDK caches 401. Change `publicKey` to a valid key and reinstall the app (or clear app data) to retry.

- **No referrer on Android**  
  Install from a Play Store link (e.g. Internal testing) with referrer parameters; local installs do not get install referrer.
