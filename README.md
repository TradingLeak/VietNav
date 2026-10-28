# VietNav — iOS Navigation (SpaceX-style, Offline OSM)

Premium offline navigation app for iOS built on OpenStreetMap, with on-device speedmap sign/camera warnings and an AI routing backend (ckey.vn).

## Features
- Offline OSM vector maps (tiles.bin) + spatial index (index.bin)
- Speed cameras & traffic signs overlay (cameras.bin, signs.bin)
- Road network + speed limits (tiles.bin), street name dictionary (names.bin, seg_names.bin)
- SpaceX-style dark futuristic UI (glassmorphism, neon accents)
- AI smart routing via ckey.vn (custom model configurable in Settings)
- Turn-by-turn navigation, voice guidance, lane assist, speed-limit alerts
- Premium: traffic, weather, ETA, multi-stop, EV charging, offline search

## Requirements
- Xcode 16+, iOS 17+
- Swift 6, SwiftUI
- No external SPM deps beyond what's listed (MapLibre optional)

## Build
1. Open `VietNav.xcodeproj` in Xcode
2. Add speedmap *.bin files to `Resources/speedmap/` (target membership checked)
3. Build & run on device/simulator
4. Archive → Export IPA for sideload

## Project layout
```
VietNav/
 ├─ VietNavApp.swift          # entry
 ├─ Models/                   # data models
 ├─ Services/                 # map, routing, AI, speedmap parser, location
 ├─ ViewModels/               # MVVM state
 ├─ Views/                    # SwiftUI screens
 ├─ Components/               # reusable UI
 ├─ Helpers/                  # extensions, theme
 └─ Resources/speedmap/       # *.bin data files
```

## AI backend
Configure in Settings → AI:
- Base URL: https://ckey.vn (or custom)
- Model: custom model name
- API key (stored in Keychain)

## Offline data
The 7 .bin files ship inside the app bundle. SpeedmapParser decodes them at first launch into a memory-mapped cache.

## License
MIT
