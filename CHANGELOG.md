# Changelog

## 7.1.1 — EZSafeContinuation deadlock fix

### Fixed
- **`EZSafeContinuation` no longer resumes a `CheckedContinuation` while holding its own mutex.**
  Resuming a continuation makes the runtime take the resumed task's status-record lock, while
  `withTaskCancellationHandler` invokes `onCancel` *with that same lock already held* — so the
  cancellation handler's `resume` (which takes the `EZSafeContinuation` mutex) and a concurrent
  `resume` on another thread could deadlock, both parked in the kernel at 0% CPU. The Swift
  stdlib documents this hazard on `withTaskCancellationHandler`: code must not resume
  continuations while holding a lock the cancellation handler also takes.
  `resume(with:)` and `set(continuation:)` now take the continuation out under the lock and
  resume it after releasing it. Behaviour is otherwise unchanged — first resume still wins,
  the continuation is still resumed exactly once — and the lock is held strictly shorter.
  Reachable from every `ezWithCheckedStoppableContinuation` caller (`EZChannel`,
  `EZBufferedChannel`, `EZAsyncValue`, `EZAsyncSemaphore`), i.e. from shipping apps, whenever a
  task is cancelled on one thread while its continuation is resumed on another.

## Unreleased — IMV access unification, protocols-only base (breaking)

Recommended bump: **major** (breaking API changes across the IMV kits).

### Added
- Library **`EZUIPackHelpersKit`** — the standard IMV implementation for both sides
  (depends only on `EZIMVPackKit`, re-exported by both view kits):
  `EZIMVPackAccessI`, the single view access `EZIMVPackAccessV` (struct), the
  `accessI`/`accessV` factories + `AccessI`/`AccessV` typealiases, `EZIMVPackMediator`.
  The mediator container doubles as the SwiftUI invalidation cell.
- **`EZIMVPackViewAccess`** and **`EZIMVPackInteractorAccess`** — abstract access protocols in
  the base (`viewModel` / `inputI`-or-`inputV` / `setMediator(_:)`, primary associated type
  `Mediator`).
- **`EZUIPackViewAccessProtocol`** — UIKit refinement adding `packBridge`, conformed by the view
  access when the mediator is a UIKit mediator.
- **`EZUIPackPlatformsAccessV`** — forwarding access used by the `EZUIPackPlatformsV` router.
- `ExampleUITests` target in the Example project: end-to-end invalidation tests for all three
  SwiftUI flavors (pure SUI, struct SView, UIView SView).

### Changed (breaking)
- **`EZIMVPackKit` is contracts-only.** Protocols and protocol-extension logic, zero concrete
  types. All implementation lives in `EZUIPackHelpersKit`.
- **One access entity per side, one canon everywhere.** Views: `let access = M.accessV` returns
  the struct `EZIMVPackAccessV` for every view kind (plain UIKit views, `EZUIPackSV`,
  `EZUIPackSUIV`, `EZSUIPackV`). Interactors: `let access = M.accessI` returns
  `EZIMVPackAccessI` as before, now witnessing the abstract
  `associatedtype Access: EZIMVPackInteractorAccess`.
- **Conditional `DynamicProperty`.** The view access conforms to `DynamicProperty` only when
  `Mediator.ViewModel: ObservableObject`; the `objectWillChange` subscription is created lazily
  in `update()`, which SwiftUI calls only for accesses stored in live SwiftUI views. Non-SwiftUI
  hosts and non-observable view models carry no SwiftUI machinery at runtime. SwiftUI specifics
  are gated per-declaration (`#if canImport(SwiftUI)`), not per-type.
- `EZIMVPackViewProtocol` / `EZIMVPackInteractorProtocol` own the access contract abstractly
  (`associatedtype Access` bound to the access protocol, `Mediator` derived through it);
  kit-level protocols pin `Access` to the concrete types. Branch protocols no longer re-declare
  `associatedtype Mediator` or concrete-typed `access` requirements.
- `EZSUIPackViewProtocol` and `EZUIPackSViewProtocol` no longer refine `Equatable`; the
  `static func == { false }` hacks are removed. Struct SViews (`EZUIPackSV`) get point-of-use
  invalidation: their hosting wrapper no longer top-observes the view model.
- `EZUIPackSUIV` (UIView hosting SwiftUI) is unchanged behaviorally: view-model top-observation
  at the hosting wrapper (a `DynamicProperty` cannot fire for a non-SwiftUI host).
- `bAccess` on `EZUIPackSViewProtocol` is retyped from `Binding<Mediator.AccessV>` to
  `Binding<Access>`.

### Removed
- The old view-facing class `EZIMVPackAccessV` (the name now belongs to the unified struct), the
  interim `EZIMVPackAccessSV`/`EZSUIPackAccessV` types, and `EZIMVPackMappedAccess` (both access
  objects are self-contained now). Access initializers take only `accessMap:` (the optional
  mediator parameter is gone).
- The base `AccessI`/`AccessV` typealiases and `accessI`/`accessV` factories (moved to
  `EZUIPackHelpersKit`), and the base `EZIMVPackMediator` class (moved there too).
- `EZUIPackKit/.../EZIMVPackAccessV + packBridge.swift` extension (subsumed by the
  `EZUIPackViewAccessProtocol` conformance of the unified access).
- The re-anchored `associatedtype Mediator` workarounds in both view branch protocols.
