# Realm Gony3T

<p align="center">
	<img src="assets/images/logo_gony3t.png" alt="Realm Gony3T Logo" width="180" />
</p>

Realm Gony3T is a Flutter desktop app for exploring `.realm` files.
It supports class browsing, query filtering, depth-limited object loading, and JSON export.

## Features

- Open local `.realm` files with optional encryption key input
- Auto-discover Realm classes and show per-class document counts
- Browse data in table + detail views
- Query/filter data from UI
- Depth control for nested object traversal
- Export class data to JSON
- Works with read-only Realm open mode to reduce lock-file issues

## Tech Stack

- Flutter (Desktop)
- Dart SDK `^3.10.8`
- Realm Dart SDK `^20.1.1`
- Riverpod `^3.3.2`

## Requirements

- Flutter SDK installed and configured
- macOS/Windows/Linux desktop support enabled in Flutter
- Xcode command line tools (for macOS builds)

## Quick Start

1. Clone and enter project

```bash
git clone https://github.com/YongKhamchun/Realm-Gony3T.git
cd Realm-Gony3T
```

2. Install dependencies

```bash
flutter pub get
```

3. Run app (recommended for macOS Realm initialization stability)

```bash
flutter run -d macos --release
```

You can also run on Windows:

```bash
flutter run -d windows
```

## How To Use

1. Click `Open File` and choose a `.realm` file.
2. If file is encrypted, provide key in one of these formats:
	 - Base64 that decodes to 64 bytes
	 - 128-character hex string
	 - Plain text exactly 64 characters
3. Select class from left panel.
4. Use query tabs to filter results.
5. Adjust depth for nested object preview.
6. Export full-depth JSON when needed.

## macOS Privacy / Trust Settings

If you open files from protected folders (Desktop/Documents/Downloads), macOS may block access.

### 1) Allow file access in Privacy settings

1. Open `System Settings`.
2. Go to `Privacy & Security`.
3. Check these sections and allow the app/tool you run with:
	 - `Files and Folders`
	 - `Full Disk Access` (only if needed)

Tip: Opening files via the app file picker helps grant scoped permission automatically.

### 2) Trust / allow app execution (unsigned app case)

If macOS blocks app startup:

1. Try opening the app once.
2. Go to `System Settings > Privacy & Security`.
3. In `Security`, click `Open Anyway` for the blocked app.
4. Re-open and confirm.

### 3) macOS entitlement note (for developers)

If you edit macOS target settings, ensure file-read entitlement for user-picked files is available.
For this project, user-selected file access is important to open `.realm` files correctly.

## Download By Tag

### Option A: From GitHub UI

1. Go to repository page: `https://github.com/YongKhamchun/Realm-Gony3T`
2. Click `Releases` or open `Tags`.
3. Choose required tag (example: `v0.1.0`).
4. Download source as `zip`/`tar.gz`, or download release assets if provided.

### Option B: From Git CLI

```bash
git clone https://github.com/YongKhamchun/Realm-Gony3T.git
cd Realm-Gony3T
git fetch --tags
git checkout tags/<tag-name> -b release/<tag-name>
```

Example:

```bash
git checkout tags/v0.1.0 -b release/v0.1.0
```

## Troubleshooting

- `RLM_ERR_FILE_PERMISSION_DENIED` / `Operation not permitted`
	- Grant macOS privacy permission, or open file through picker.
- Realm init error mentioning `Platform.resolvedExecutable`
	- Run in `--release` or `--profile` mode on macOS.
- Cannot decrypt file
	- Verify encryption key format and length.

## License

If you plan to publish this project, add a `LICENSE` file and update this section.
