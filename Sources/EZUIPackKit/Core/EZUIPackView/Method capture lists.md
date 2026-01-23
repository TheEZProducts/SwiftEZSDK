# Pitch: Method capture lists (self / weak self / unowned self / none) for controlling implicit `self` in method bodies

## Motivation

Swift closures have capture lists that let developers control how values are captured (e.g. `weak self`, `unowned self`, or binding captures like `x = expr`).

However, **instance methods** don’t have an equivalent mechanism. In practice this becomes painful with long-running async work, especially when a task/loop outlives the last external reference to an actor or class instance.

A common pattern today is:

```swift
final actor WorkerActor {
  private var loopTask: Task<Void, Never>?

  func start() {
    loopTask = Task { [weak self] in
      await self?.runLoop()
    }
  }

  func runLoop() async {
    // Long-running / infinite loop that observes cancellation
  }

  deinit { loopTask?.cancel() }
}
```

Even though the task captures `self` weakly, once we call an **actor-isolated** instance method, we effectively re-establish a dependency on the actor instance’s lifetime for the duration of that method’s work. This has led to repeated confusion and workarounds in real code bases.

Developers can work around this by moving logic into static functions and passing weak wrappers, but that harms ergonomics and often complicates actor isolation guarantees.

## Proposed solution

Allow **methods (and functions)** to declare a capture list—syntactically and semantically aligned with closure capture lists—to control how `self` is available inside the method body.

### High-level goals

1. Keep the **current default behavior**: implicit `self` works as today.
2. Add an **opt-in** way to make `self` availability explicit and/or weakened.
3. Reuse the **existing capture-list features** developers already know from closures, including binding captures like `name = expr`.

### Strawman syntax options (pick one for discussion)

Option A (closest to closure capture list placement):

```swift
func f[weak self](x: Int) async { ... }
```

Option B (post-parameter clause):

```swift
func f(x: Int) async [weak self] { ... }
```

Option C (body signature clause, closure-like):

```swift
func f(x: Int) async { [weak self] in ... }
```

I currently prefer **Option A** because it reads as “part of the function signature” without interfering with `async`/`throws` ordering, and it visually matches closure capture-list syntax.

## Detailed design

### 1) Default equivalence

The following are equivalent:

```swift
func testFunc() { ... }
func testFunc[self]() { ... }
```

I.e. default is `[self]`.

### 2) `self` capture modes

Inside the method body:

- `func f[self]()` (or no capture list)
  `self` behaves exactly as today.

- `func f[weak self]()`
  `self` is available as `Self?`, requiring optional chaining / unwrapping (mirrors closure behavior).

- `func f[unowned self]()`
  `self` is available as `Self` with the same safety characteristics as `unowned` in closures.

#### Explicit-capture mode: empty list (`[]`) and readable alias (`[none]`)

When a method *has* a capture list, it enables an **explicit-capture mode**: `self` is **only** available inside the method body if it is explicitly listed (as `self`, `weak self`, or `unowned self`).

To express “capture nothing (including no `self`)”, this pitch proposes two spellings that are **equivalent**:

- `func f[]()`
- `func f[none]()`  *(readable alias for the empty list)*

Because `[none]` is just a spelling of the **empty** list, it is **not combinable** with other entries.

**Semantics (in the method body):** if `self` is not captured, then:

- The keyword `self` is unavailable.
- Implicit member lookup through `self` is disabled (so `property` / `method()` are rejected).
- Binding captures can still introduce specific names (see next section).

Example diagnostics (illustrative):

```swift
final class Example {
  var value: Int = 0

  func read[]() {
    _ = value        // error: instance member 'value' is unavailable because `self` is not in scope
    _ = self.value   // error: `self` is unavailable in an explicit-capture method unless captured
  }

  func read2[cached = value]() {
      _ = value      // error: instance member 'value' is unavailable because `self` is not in scope
    _ = cached       // ok
  }
}
```

#### Alternative design direction: opt-out-only (`[no self]`)

As an alternative to the explicit-capture model above, Swift could keep today’s default (implicit `self` availability) even when other captures are present, and add a single opt-out spelling:

- `func f[no self]()` — disables `self` and implicit member lookup.

This pitch treats **explicit-capture (`[]` / `[none]`)** and **opt-out-only (`[no self]`)** as mutually exclusive design directions.

### 3) Binding captures in method capture lists

Support binding captures identical in shape to closure capture lists, e.g.:

```swift
final class Example {
  var text: String = ""
  var count: Int = 0

  func work[cachedCount = text.count]() {
    // `self` is unavailable here, but `cachedCount` is available.
    // useful for avoiding implicit member lookup while still capturing specific values.
    _ = cachedCount
  }
}
```

This mirrors closure capture lists that bind names to expressions to capture snapshots.

**Evaluation time:** for methods, binding captures are evaluated at **method entry** (per call), since there is no “closure creation time” for methods.

### 4) Actors and isolation constraints (initial conservative rule)

To avoid suggesting actor isolation where `self` is not strongly held, the initial rule is:

- For `actor` instance methods, any capture list other than `[self]` requires `nonisolated`.

Example:

```swift
final actor WorkerActor {
  nonisolated func runLoop[weak self]() async {
    // long-running / infinite loop; self: WorkerActor?
  }
}
```

If a developer wants actor-isolated behavior, they must keep `[self]` (the default) and manage lifetime explicitly, or hop to the actor explicitly when needed (outside scope for this pitch).

## Examples

### Long-running async task that should not keep the owner alive

```swift
final actor WorkerActor {
  private var loopTask: Task<Void, Never>?

  func start() {
    loopTask = Task { [weak self] in
      await self?.runLoop()
    }
  }

  nonisolated func runLoop[weak self]() async {
    while true {
      await self?.work() // fast work
      // do some work without requiring the actor to be kept alive by the method itself
      // observe cancellation
      try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
  }

  deinit { loopTask?.cancel() }
}
```

### Making implicit `self` explicit (documentation / readability)

```swift
final class Example {
  func doWork[self]() { /* same as today */ }
  func doWork[none]() { /* no implicit self */ }
}
```

## Source compatibility

Purely additive. Existing code continues to compile unchanged.

## Alternatives considered

- Always use closure capture lists at call sites, e.g. `Task { [weak self] in ... }` (works but doesn’t help with *method-level* implicit `self` and discourages reusable APIs).
- Move logic into `static`/free functions + pass wrappers (works but harms ergonomics and readability).

## Prior art

- Swift Forums discussions about `Task { [weak self] ... }` inside actors highlight why weak references don’t preserve actor isolation and document real confusion around long-running tasks and lifetime.
- A Swift Forums thread proposed making capture semantics explicit for **local functions** and discussed allowing capture lists for them, which is a close syntactic precedent for extending capture-list syntax beyond closures.
- Related pitches about declaring capture semantics when passing method references show recurring developer pain around implicit `self` capture and lifetime.

## Open questions

1. Preferred syntax among A/B/C.
2. Design choice: explicit-capture mode (`[]` / `[none]`) vs opt-out-only (`[no self]`).
