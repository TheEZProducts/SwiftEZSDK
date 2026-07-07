# SwiftEZSDK

## Overview

A modular Swift SDK (package name: EZSDK) providing utility kits for Apple platform development. Swift 6.0, supports iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+, visionOS 1+.

## Architecture

Modular design — each kit is an independent library that can be imported separately. The umbrella `All` product re-exports everything.

### Stable Kits

- **EZAssociatedKit** — Associated object helpers
- **EZHelpersKit** — General helpers, depends on EZAssociatedKit and EZMacrosKit
- **EZAsyncKit** — Async/concurrency utilities
- **EZObservableKit** — Observable pattern implementation
- **EZBuilderKit** — Builder pattern utilities
- **EZSwiftUIBridgeKit** — SwiftUI/UIKit bridging
- **EZIMVPackKit** — IMVP architecture pack
- **EZTransitionKit** — View controller transitions (iOS/tvOS)
- **EZUIPackKit** — UIKit component pack (combines IMVPack, Transition, SwiftUIBridge)
- **EZSUIPackKit** — SwiftUI component pack
- **EZMacrosKit** / **EZMacros** — Swift macros

### Experimental

- **EZJsonStriderKit** — JSON traversal
- **EZJsonKeysPlugin** — Build plugin for JSON key generation

## Build & Test

```bash
swift build
swift test
```

## Key Conventions

- Target metadata (name, test name, platform conditions, paths) is declared via `EZTargetProtocol` structs in `Package.swift`.
- Sources are under `Sources/` with UI-related kits nested in `Sources/EZUI/`.
- Macros are under `Macros/`.
