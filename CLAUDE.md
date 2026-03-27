# Burndown

A body battery watch face for circular Garmin watches, built with Monkey C and the Connect IQ SDK.

## Project Structure

```
source/
├── Garmin-FaceApp.mc         # App entry point (Garmin_FaceApp class)
└── Garmin-FaceView.mc        # Watch face rendering (Garmin_FaceView class)
resources/
├── layouts/layout.xml        # UI layout (centered TimeLabel)
├── strings/strings.xml       # Localized strings
└── drawables/                # Icons (launcher_icon.svg)
manifest.xml                  # App metadata, device targets, permissions
monkey.jungle                 # Build config
watch.sh                      # Dev build-watch script (fswatch + auto-deploy)
```

## Tech Stack

- **Language:** Monkey C (Garmin Connect IQ)
- **SDK:** Connect IQ SDK 9.1.0
- **Target Devices:** Circular Garmin watches (Enduro 3, Fenix 7/8, Forerunner 265/965, Epix 2, Venu 3)
- **Min API:** 5.2.0
- **App Type:** watchface

## Architecture

- `Garmin_FaceApp` extends `Application.AppBase` — creates the initial view on launch
- `Garmin_FaceView` extends `WatchUi.WatchFace` — renders time via `onUpdate(dc)`
- All layout calculations use `dc.getWidth()`/`dc.getHeight()` to adapt to any circular screen size
- Layout loaded from XML resources; time displayed as blue centered text (`Graphics.FONT_LARGE`)
- Resources auto-generate the `Rez` module in `gen/` (resource IDs, layout functions, device constants)

## Supported Devices

Devices are listed in `manifest.xml`. Currently includes:
- Enduro 3
- Fenix 7 / 7S / 7X (+ Pro variants)
- Fenix 8 Solar (47mm, 51mm), Fenix 8 AMOLED (47mm, 51mm), Fenix E
- Tactix 8 / Tactix 8 AMOLED
- Descent Mk3 / Descent 3i
- MARQ Gen 2 / MARQ Aviator Gen 2
- Forerunner 170 / 265 / 265S / 965
- Epix 2 (+ Pro 42/47/51mm)
- Venu 3 / 3S
- Instinct 3 AMOLED (45mm, 50mm)

To add a new circular device, add a `<iq:product id="devicename"/>` entry to the `<iq:products>` block in `manifest.xml`.

## Build & Development

**Prerequisites:** Garmin Connect IQ SDK, Java runtime, `fswatch` (for watch mode), developer key at `~/.garmin/developer_key` (symlinked to iCloud Drive at `~/Library/Mobile Documents/com~apple~CloudDocs/Code/garmin-keys/developer_key`)

**Watch mode (auto-rebuild + simulator deploy):**
```bash
./watch.sh
```
Edit `DEVICE` in `watch.sh` to test different devices (default: `enduro3`).

**Manual build:**
```bash
SDK="/Users/henry/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin"
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
    -jar "$SDK/monkeybrains.jar" \
    -o GarminFace.prg \
    -f monkey.jungle \
    -y ~/.garmin/developer_key \
    -d enduro3 -w
```
Replace `-d enduro3` with any supported device ID (e.g., `-d fenix7`).

**Deploy to simulator:**
```bash
"$SDK/monkeydo" GarminFace.prg enduro3
```

## Conventions

- Filenames use hyphens (`Garmin-FaceApp.mc`), class names use underscores (`Garmin_FaceApp`)
- Resource IDs use camelCase (`TimeLabel`, `AppName`)
- Files in `gen/` and `mir/` are auto-generated — never edit manually
- The compiled output is `GarminFace.prg`
- Screen dimensions must never be hardcoded — always derive from `dc.getWidth()`/`dc.getHeight()`
