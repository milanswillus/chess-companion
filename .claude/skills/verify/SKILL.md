---
name: verify
description: Build, install, and observe ChessCompanion in the iOS simulator to verify changes at runtime.
---

# Verify ChessCompanion

## Build

`xcodebuild` needs the full Xcode (CLT alone fails with "requires Xcode"):

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ChessCompanion.xcodeproj -scheme ChessCompanion \
  -destination 'generic/platform=iOS Simulator' build
```

## Install & launch

Deployment target is iOS 26.0 — iOS 18 simulators refuse the install. Use an
iOS 26.x device (e.g. iPhone 17 Pro):

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID=$(xcrun simctl list devices available | grep -A3 "iOS 26" | grep "iPhone 17 Pro (" | grep -oE '[A-F0-9-]{36}' | head -1)
xcrun simctl boot $UDID; xcrun simctl bootstatus $UDID -b
APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/ChessCompanion-*/Build/Products/Debug-iphonesimulator/ChessCompanion.app | head -1)
xcrun simctl install $UDID "$APP"
xcrun simctl launch $UDID com.ChessCompanion
xcrun simctl io $UDID screenshot shot.png
```

## Forcing app state (no taps needed)

`@AppStorage` keys can be overridden per-launch via launch arguments
(NSArgumentDomain beats stored defaults):

```bash
xcrun simctl launch $UDID com.ChessCompanion -appTheme darkNeon -hasCompletedOnboarding NO
```

Useful keys: `appTheme` (standard|darkNeon|midnightGold|sweetRose|onyx|aquamarine),
`hasCompletedOnboarding`, `appLanguage` (de|en), `showBoardCoordinates`.

## Gotchas

- **Always terminate before relaunching** (`simctl terminate $UDID com.ChessCompanion`);
  a live process re-renders on defaults changes and screenshots can show a stale
  process's UI otherwise.
- **Synthetic clicks do not work**: AppleScript/System Events `click at` fails
  (TCC accessibility, error -25204) or silently no-ops; cliclick/idb are not
  installed. Interactive flows (playing moves, tab navigation) need manual testing
  or an XCUITest target (none exists).
- Verify pixel colors with a CoreGraphics sampler script rather than eyeballing;
  screenshots are 1206x2622 (iPhone 17 Pro @3x, 402x874 pt).
- Engine regression signal: the repo dir must stay free of `engine_log.txt`,
  `game_flow_log.txt`, `test_result.txt` after running the app (dev-logging was
  removed pre-App-Store; those writers used hardcoded repo paths).
