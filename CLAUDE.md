# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftEZSDK is a modular Swift package providing focused, reusable kits for Apple platform development. Users can depend on the "All" umbrella product or select individual kits. There are no external dependencies.

- **Swift**: 6.0+ (uses experimental feature `Lifetimes` in EZHelpersKit)
- **Platforms**: iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+, visionOS
- **Build system**: Swift Package Manager

## Build & Test Commands

```bash
swift build                          # Build all targets
swift build -c release               # Release build
swift test                           # Run all tests
swift test --filter EZAsyncKitTest   # Run a single test target
swift package resolve                # Resolve dependencies
```

Docker-based Linux build: `docker build .`

## Architecture

### Module Dependency Graph

```
EZKit (umbrella, re-exports all stable kits)
├── EZUIPackKit ──────→ EZIMVPackKit, EZTransitionKit, EZSwiftUIBridgeKit
├── EZSUIPackKit ─────→ EZIMVPackKit
├── EZIMVPackKit      (leaf, platform-agnostic IMV base protocols)
├── EZTransitionKit   (leaf, custom VC transitions)
├── EZObservableKit ──→ EZAssociatedKit, EZAsyncKit, EZMacrosKit
├── EZAsyncKit ───────→ EZAssociatedKit, EZHelpersKit, EZMacrosKit
├── EZHelpersKit ─────→ EZAssociatedKit, EZMacrosKit
├── EZMacrosKit ──────→ EZMacros (compiler plugin, in Macros/ dir)
├── EZAssociatedKit   (leaf, ObjC runtime)
├── EZBuilderKit      (leaf)
└── EZSwiftUIBridgeKit (leaf)
```

Experimental: `EZJsonStriderKit`, `EZJsonKeysPlugin` + `EZJsonKeysGenerator`

### Key Kits

- **EZHelpersKit** — Thread-safety primitives (`EZMutex`, `EZRecursiveMutex`, `EZLockingMutex`), weak wrappers, extensions on Collection/Optional/Codable/Result. Requires `Lifetimes` experimental feature.
- **EZAsyncKit** — Async channels (`EZChannel`, `EZBufferedChannel`), `EZThreadSafety<T>`, `EZAsyncSemaphore`, `EZActorIsolator`, task group helpers, `ezWithCheckedStoppableContinuation`.
- **EZObservableKit** — `@EZObservable` macro for observable properties with token-based subscriptions. Bridges to SwiftUI via `snapEZObservable()`.
- **EZIMVPackKit** — Platform-agnostic base protocols for the IMV architecture: `EZIMVPackMediatorProtocol`, `EZIMVPackInteractorProtocol`, `EZIMVPackViewProtocol`, access objects (`EZIMVPackAccessI`/`V`), and `EZIMVPackMediator` base class. Used by both EZUIPackKit and EZSUIPackKit.
- **EZTransitionKit** — Custom view controller transition system. Provides a fluent API (`UIViewController.ezTransit`) for navigation push/pop, tab bar switching, modal present/dismiss, page transitions, and custom animated transitions. Platform-limited to iOS/macCatalyst/visionOS/tvOS.
- **EZUIPackKit** — UIKit IMV (Interactor-Mediator-View) architecture framework. Interactor = UIViewController with business logic, Mediator = shared state/communication hub, View = UI presentation. Includes `EZPackMaker` for pack creation, `EZUIPackPlatformsV` for multi-platform views, shared storage, and UIKit lifecycle integration. Platform-limited to iOS/macCatalyst/visionOS/tvOS.
- **EZSUIPackKit** — SwiftUI IMV architecture framework. Provides `EZSUIPack` container view, SwiftUI-native interactors with `onAppear`/`onDisappear`, and mediators with `ObservableObject` view models. Available on all Apple platforms.
- **EZMacrosKit + EZMacros** — Constant-storage property wrapper macros that expand stored properties into computed properties backed by `let _name` storage. This solves `Sendable` issues with traditional `@propertyWrapper` in classes. Macro types: `_CMP` (Constant/Mutable/Projected), `_CIP` (Constant/Immutable/Projected).
- **EZSwiftUIBridgeKit** — `EZUIViewWrapper` (UIView/NSView in SwiftUI), `EZView.ezWrap()` (SwiftUI in UIKit/AppKit), `EZObservableObjectGroup` for multi-object observation.
- **EZBuilderKit** — Builder pattern protocols (`EZBuilderProtocol`, `EZBuildableProtocol`).

### Package.swift Conventions

Targets are defined using an `EZTargetProtocol` at the bottom of Package.swift. Each target is a struct conforming to this protocol, which auto-derives `name`, `testName`, `condition`, `macrosPath`, and `path` from the struct name. Platform restrictions are specified via `condition` overrides. Non-default source locations are specified via `path` overrides (e.g., UI modules live under `Sources/EZUI/`).

### Macro Source Location

The compiler plugin source lives in `Macros/EZMacros/`, not under `Sources/`. It includes a custom lightweight compiler plugin framework (`EZSwiftCompilerPluginLight`).

### Sendable-First Design

All major types are `Sendable` or explicitly handle Sendable constraints. The macro system exists specifically to enable `Sendable` classes by replacing stored property wrappers with constant-backed (`let`) storage + computed accessors.

### Observable Property Convention

```swift
@EZObservable var value: Int = 0
// Access backing storage: _value
// Access projection (observer registration): $value
// Mutation: _value.update { $0.value += 1 }
```

### Platform Conditionals

Code uses `#if canImport()` and SPM `.when(platforms:)` conditions extensively. Key restrictions:
- `EZAssociatedKit`: Not available on Linux/Android (needs ObjC runtime)
- `EZIMVPackKit`: iOS, macCatalyst, visionOS, macOS, tvOS, watchOS
- `EZTransitionKit`: iOS, macCatalyst, visionOS, tvOS only
- `EZUIPackKit`: iOS, macCatalyst, visionOS, tvOS only
- `EZSUIPackKit`: iOS, macCatalyst, visionOS, macOS, tvOS, watchOS
- `EZSwiftUIBridgeKit`: iOS, macCatalyst, visionOS, macOS, tvOS
- `EZMacros`: macOS 13.0+ (compiler plugin host requirement)

## Directory Layout

- `Sources/` — All library target sources (one subdirectory per kit)
  - `Sources/EZUI/` — UI-related modules:
    - `EZSwiftUIBridgeKit/` — SwiftUI ↔ UIKit/AppKit bridging
    - `EZTransitionKit/` — Custom view controller transitions
    - `EZIMVPack/` — IMV architecture modules:
      - `EZIMVPackKit/` — Platform-agnostic base protocols
      - `EZUIPackKit/` — UIKit IMV implementation
      - `EZSUIPackKit/` — SwiftUI IMV implementation
- `Macros/EZMacros/` — Compiler plugin implementation
- `Plugins/EZJsonKeysPlugin/` — Build tool plugin
- `Tests/` — XCTest targets (named `<Kit>Test`)
- `Example/` — Example Xcode project demonstrating kit usage
- `File Templates/` — Xcode file templates for IMV architecture scaffolding
- `Documentation-RU/` — Russian-language documentation
- `docs/` — English documentation (migration guides, etc.)

## Git Workflow

- **Always agree on the commit message with the user before committing.** Never create commits autonomously — show the proposed message and get confirmation first.
