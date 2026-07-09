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
- **EZIMVPackKit** — IMV architecture contracts **only** (Foundation-only, zero concrete types): mediator/interactor/view protocols plus the abstract access protocols `EZIMVPackInteractorAccess` / `EZIMVPackViewAccess`
- **EZUIPackHelpersKit** — the standard IMV implementation for both sides: `EZIMVPackAccessI` (class), the single view access `EZIMVPackAccessV` (struct), the `accessI`/`accessV` factories, `EZIMVPackMediator`; depends only on EZIMVPackKit, used by both view kits; SwiftUI specifics gated per-declaration
- **EZTransitionKit** — View controller transitions (iOS/tvOS)
- **EZUIPackKit** — UIKit component pack (combines IMVPack, UIPackHelpers, Transition, SwiftUIBridge)
- **EZSUIPackKit** — SwiftUI component pack
- **EZMacrosKit** / **EZMacros** — Swift macros

### IMV view access model

`EZIMVPackViewProtocol` owns the access contract: `associatedtype Access: EZIMVPackViewAccess where Access.Mediator == Mediator` plus `var access`, from which `viewModel`/`inputI` are derived once. The concrete view witness pins `Access`; `Mediator` is inferred through it — do not re-declare `associatedtype Mediator` in refining protocols.

There is a **single view access**: the self-contained struct `EZIMVPackAccessV` (`EZUIPackHelpersKit`), created via the one factory `let access = M.accessV` in every view kind. It conforms to `DynamicProperty` **conditionally** — only when `Mediator.ViewModel: ObservableObject`; the `objectWillChange` subscription is created lazily in `update()`, which SwiftUI calls only for accesses stored in live SwiftUI views. The interactor side mirrors the same shape (`associatedtype Access: EZIMVPackInteractorAccess`, witness `let access = M.accessI`, kit-level pin to `EZIMVPackAccessI`). Consequences per view kind:

- Plain UIKit view (`EZUIPackV`) — the access is inert plumbing (`update()` never runs; no subscription).
- Pure-SwiftUI view (`EZSUIPackV`) and SwiftUI struct in a UIKit pack (`EZUIPackSV`) — point-of-use invalidation when the view model is an `ObservableObject`.
- UIView hosting SwiftUI (`EZUIPackSUIV`) — top-observation of the view model at the hosting wrapper (`ezWrap`); the `DynamicProperty` mechanism cannot fire for a UIView that is not itself a SwiftUI view.

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
