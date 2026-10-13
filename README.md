# Youtube Phenom

**Ad-free YouTube VR for Meta Quest.** Sideload the APK, sign in, watch VR
videos without pre-rolls, mid-rolls, overlays, or VR180 immersive ads.

Based on YouTube VR Oculus `1.88.10` — the final build Google shipped
before deprecating YouTube VR on Quest in March 2025.

---

## Features

- Pre-roll, mid-roll, overlay, and in-player ads removed
- VR180 and 360° immersive ads removed (the `BELOW_PLAYER_IMMERSIVE`
  slot type that fires on spherical content)
- Renamed to **Youtube Phenom** on the Quest home screen
- Repackaged as `com.phenom.ytvr` — Meta's app registry and
  entitlement system do not recognise it (`OVRService: Unable to find
  AppId for package`), and it coexists cleanly with the original
  YouTube VR if you ever reinstall that
- Keeps all original playback features intact: flat video in a VR
  theater, 360° head-tracked, VR180 stereoscopic, live streams,
  co-watch, hand-tracking, cast
- Sign-in works normally via YouTube's OAuth device-code flow
  (`youtube.com/activate` + 8-char code — no microG needed on Quest)

## Compatibility

| Device       | Status                        |
|--------------|-------------------------------|
| Quest 3      | Tested, works                 |
| Quest 2      | Should work (same APK target) |
| Quest Pro    | Should work (same APK target) |
| Quest 1      | Untested (device EoL)         |
| Pico / other | Untested                      |

Horizon OS SDK 57–67. Android target SDK 32, min SDK 26.

---

## Download & install

1. **Download the latest APK** from the
   [Releases page](../../releases/latest).
2. **Enable Developer Mode** on your Quest (via the Meta Horizon mobile
   app → Devices → your headset → Developer Mode → On).
3. **Install the APK** using whichever sideload method you prefer:

   **Option A — ADB (recommended)**
   ```bash
   adb install -r youtube-phenom.apk
   ```

   **Option B — SideQuest**
   Drag the APK into SideQuest's "Install APK" area with the headset
   connected.

   **Option C — Meta Quest Developer Hub (MQDH)**
   File → Install APK → pick the downloaded file.

4. **Launch**: on your Quest, open the **Library** → **Unknown
   Sources** → **Youtube Phenom**.

5. **Sign in** via the OAuth code shown in-headset
   (`youtube.com/activate` on a phone or PC).

That's it. Browse and play; no pre-rolls.

### Verify the download

Each release lists a SHA-256 hash. Verify before installing:

```bash
# Linux / macOS
shasum -a 256 youtube-phenom.apk

# Windows (PowerShell)
Get-FileHash .\youtube-phenom.apk -Algorithm SHA256
```

The hash should match the one on the release page.

---

## Disclaimer

- This is a **personal-use** modification of YouTube VR for Quest, for
  users who have obtained the original app legitimately (while it was
  available on the Meta Store).
- YouTube VR for Oculus is Google's copyrighted work. This project
  modifies and redistributes a debug-signed derivative under a
  fair-use personal-modification posture. No warranty, no support, no
  affiliation with Google, Alphabet, Meta, or ReVanced.
- The APK is **debug-signed** by `uber-apk-signer` with an ephemeral
  key — the signature will never match Google's Play-signed original,
  and it will never pass Play Protect / Meta Store integrity. This is
  sideloading only.
- Google deprecated YouTube VR for Quest in March 2025. Version
  `1.88.10` is the final client. The patches freeze the client there;
  backend protocol drift at YouTube may eventually degrade playback
  independent of this project.
- Modifying your account's ad-serving posture may be against
  YouTube's Terms of Service. Use at your own discretion.
- Install at your own risk. If something breaks, uninstall:
  `adb uninstall com.phenom.ytvr`.

If you receive a DMCA notice or similar: this repo mirrors the pattern
established by ReVanced, YouTube Vanced, SmartTube, NewPipe, and many
other sideloading communities, under the same fair-use reasoning.

---

## Known limitations

- **One-time install state loss**: because the APK is debug-signed,
  it won't upgrade over Meta's original YouTube VR. You must either
  uninstall the original first, or install this one as a separate app
  (which happens automatically because of the different package
  name).
- **Account sync is per-install**: watch history and preferences live
  in the app's data dir. Reinstalling resets them.
- **No cross-package login**: because the package name is
  `com.phenom.ytvr` rather than Google's original, nothing else on
  your Quest treats it as "the YouTube app" for cross-app flows
  (unlikely to matter in practice on Quest).
- **Shorts ads**: not explicitly targeted. The main AdSlotRenderer
  stub likely covers them, but Shorts has its own flow
  (`moj.smali` → `AdBreakResponseFuture for Shorts Ads`). If you see
  Shorts ads, open an issue.
- **DAI (Dynamic Ad Insertion)** — if YouTube ever server-stitches
  ads directly into the main video stream, no client-side patch can
  remove them. Not observed in testing so far.

---

## For developers: build from source

The repo contains the patch recipe and automation; the APK on Releases
is produced by this pipeline. To rebuild (e.g. to re-patch a different
APK version, verify the build, or extend the patches):

### Prerequisites
- Windows + PowerShell 5+ (adapt for Linux/macOS)
- Java 17+
- `adb` on PATH
- A Quest with YouTube VR already installed (so you can pull the base
  APK — the repo does not redistribute Google's unmodified APK)

### Build steps

```powershell
# 1. One-time: fetch Apktool + uber-apk-signer into tools/
.\scripts\00-setup.ps1

# 2. Connect Quest in developer mode
adb devices

# 3. Pull YouTube VR 1.88.10 from your device
.\scripts\01-pull-apk.ps1

# 4. Decompile
.\scripts\02-decompile.ps1

# 5. Apply all six Phenom patches
.\scripts\02a-apply-patches.ps1

# 6. Rebuild + zipalign + debug-sign
.\scripts\03-build-and-sign.ps1

# 7. (optional) Install on connected Quest
.\scripts\04-install.ps1
```

Output: `apk/patched/youtubevr-patched-aligned-debugSigned.apk`.

### Project layout

```
YouTubeVR-Patches/
├── README.md                     this file
├── .gitignore                    excludes decompile output + tool JARs
├── scripts/
│   ├── 00-setup.ps1              downloads apktool + uber-apk-signer
│   ├── 01-pull-apk.ps1           adb pull YT VR from Quest
│   ├── 02-decompile.ps1          apktool d
│   ├── 02a-apply-patches.ps1     the full patch recipe, scripted
│   ├── 03-build-and-sign.ps1     apktool b + uber-apk-signer
│   └── 04-install.ps1            adb install to Quest
├── tools/                        apktool.jar + uber-apk-signer.jar (gitignored, auto-downloaded)
└── apk/                          (gitignored — build intermediates)
```

---

## What the patches do

Six patches, all applied by `scripts/02a-apply-patches.ps1`:

### 1. Rename app
`res/values/strings.xml`
```diff
- <string name="youtube_vr_app_name">YouTube</string>
+ <string name="youtube_vr_app_name">Youtube Phenom</string>
```

### 2. Repackage to `com.phenom.ytvr`
`AndroidManifest.xml` — all six occurrences of the original package
name: the `<manifest package="...">` attribute, the
`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` declaration + usage, and
three `FileProvider` authorities (`.tracing`, `.mlkitinitprovider`,
`.firebaseinitprovider`). The lone smali reference in
`smali_classes2/lpf.smali:179` is left alone — it is a lookup table of
known Google apps, not a self-identity check.

### 3. Dead-end the `player/ad_break` endpoint
`smali_classes3/ovj.smali` and `smali_classes3/ovh.smali`:
```diff
- const-string v?, "player/ad_break"
+ const-string v?, "player/noop_phenom"
```
Both classes extend `Losw` and pass this string as the Innertube
request path to their request constructor. The invalid path 404s
cleanly; `/player`, `/next`, `/search` traffic untouched.

### 4. Stub `mqy.smali` AdSlotRenderer
Replaces `a(Lvmo;Lmwh;)Lvmo;` with an empty-list return and
`b(Lvmo;Lmwh;)V` with no-op. Kills every slot type:

- `SLOT_TYPE_AD_BREAK_REQUEST`
- `SLOT_TYPE_BELOW_PLAYER_IMMERSIVE` *(the VR180 ad)*
- `SLOT_TYPE_MINI_APP_IN_PLAYER`
- `SLOT_TYPE_IN_PLAYER_ORGANIC_OVERLAY`
- `SLOT_TYPE_IN_FEED`
- `SLOT_TYPE_IN_PLAYER`
- `SLOT_TYPE_SEQUENCE_ITEM_AD_SELECTION`

### 5. Stub `muk.smali` AdBreak proto deserializer
`a(Loqi;)Ljava/util/List;` and
`b(Lmzt;Ljava/util/List;Loqi;)Ljava/util/List;` both reduced to
`return-object Lvrm;->a:Lvmo;` (the empty immutable list singleton
the method already used as a fallback).

### 6. Stub `mqx.smali` ad-break builder
`q(Loqi;Lstd;Ljava/lang/String;)Lj$/util/Optional;` returns
`Optional.empty()`; `r(Loqi;Lstd;Ljava/lang/String;Lsq;)Ljava/util/List;`
returns the empty-list singleton. This is the direct-build pipeline
that bypasses the proto deserializer — the one that actually serves
startup pre-rolls.

---

## Deferred features

These are reasonable follow-ups but aren't in current releases:

- **Return YouTube Dislike** integration (would need a hook into the
  VR panel's like/dislike view binding)
- **SponsorBlock** auto-skip (would need a playback-progress hook plus
  the SponsorBlock API)
- **Custom settings tab** inside the app's profile settings for
  toggling the above

Each is a non-trivial reverse-engineering project in its own right —
ReVanced's regular-YouTube patches for these don't apply, because
YouTube VR uses a different UI framework and different internal protos.

---

## Credits

- Methodology inspired by [ReVanced](https://revanced.app/) — this
  project applies the same reverse-engineer-and-stub pattern to a
  different target (YouTube VR Oculus) that ReVanced does not cover.
- Tools: [Apktool](https://apktool.org/) 2.11.1,
  [uber-apk-signer](https://github.com/patrickfav/uber-apk-signer) 1.3.0.
- Not affiliated with Google, Alphabet, Meta, or the ReVanced
  project.
