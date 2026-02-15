# ezWithUnstructuredTaskGroup

`ezWithUnstructuredTaskGroup` is a set of helpers for awaiting already created **unstructured** tasks (`Task`) in parallel, with convenient tuple-based result return and proper cancellation.

Unlike `ezWithTaskGroup*`, here the tasks are created **externally** (unstructured `Task`), and the helper only:

- waits for their results;
- carefully propagates cancellation (via `withTaskCancellationHandler`);
- converts everything into a convenient form:
  - a tuple of values (`.values`),
  - a tuple of `Result`s (`.results`),
  - a tuple of optionals (`.optionals`),
  - or "all-or-nothing" with `EZGroupError`.

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+
> Works with already created `Task<Success, Failure>` and does not create a `TaskGroup`.

---

## Core Idea

- You create multiple `Task` instances (e.g. in different parts of the code or in advance).
- You pass them to `ezWithUnstructuredTaskGroup(...)`.
- The helper:
  - waits for all tasks **in parallel** (via variadic generics `each T`),
  - monitors cancellation of the outer task and calls `cancel()` on all children,
  - returns the result in a convenient form (values / Result / optionals).

---

## Values (`.values`) -- non-throwing variant

### Variadic/builder API for `Task<Success, Never>`

```swift
@discardableResult
public func ezWithUnstructuredTaskGroup<each T>(
    result: EZTaskGroupResultValuesType = .values,
    _ values: repeat Task<each T, Never>
) async -> (repeat each T)

@discardableResult
public func ezWithUnstructuredTaskGroup<each T>(
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, Never>)
) async -> (repeat each T)
```

- Takes a tuple of non-throwing tasks (`Failure == Never`).
- Under the hood uses `withTaskCancellationHandler`:
  - `operation` awaits all `task.value`,
  - `onCancel` calls `cancel()` for each task.
- Returns a tuple of values in the same order as the input `Task` instances.

**Example:**

```swift
let t1 = Task { 1 }
let t2 = Task { 2 }

let (a, b) = await ezWithUnstructuredTaskGroup(t1, t2)
// a == 1, b == 2
```

---

## Values (`.values`) -- throwing variant with `EZGroupError`

```swift
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultValuesType = .values,
    _ values: repeat Task<each T, each Err>
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T)

@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, each Err>)
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T)
```

Behavior:

- First calls the `.results` overload and obtains a tuple of `Result<Success, Failure>`.
- If at least one `Result` is `.failure`, throws `EZGroupError` containing the **entire tuple** of results.
- If all tasks completed successfully, returns a tuple of unwrapped values.

Convenient when you need "all-or-nothing" on top of already created `Task` instances.

**Example:**

```swift
let t1 = Task { try await loadUser() }
let t2 = Task { try await loadPosts() }

let (user, posts) = try await ezWithUnstructuredTaskGroup(t1, t2)
```

---

## Results (`.results`)

```swift
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultResultsType,
    _ values: repeat Task<each T, each Err>
) async -> (repeat Result<each T, each Err>)

@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultResultsType,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, each Err>)
) async -> (repeat Result<each T, each Err>)
```

- Never throws on its own.
- Each `Task` is returned as `Result<Success, Failure>`:
  - on success -- `.success(value)`,
  - on error -- `.failure(error)`.
- Cancellation of the outer task still causes `cancel()` on all inner tasks.

**Example:**

```swift
let t1 = Task { try await loadUser() }
let t2 = Task { try await loadPosts() }

let (userResult, postsResult): (Result<User, Error>, Result<[Post], Error>) =
    await ezWithUnstructuredTaskGroup(result: .results, t1, t2)
```

---

## Optionals (`.optionals`)

```swift
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultOptionalsType,
    _ values: repeat Task<each T, each Err>
) async -> (repeat Optional<each T>)

@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultOptionalsType,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, each Err>)
) async -> (repeat Optional<each T>)
```

- A wrapper over value awaiting:
  - on success -- returns `value`,
  - on error -- `nil`.
- Does not preserve the errors themselves -- only "has value / no value".

**Example:**

```swift
let t1 = Task { try await loadUser() }
let t2 = Task { try await loadPosts() }

let (user, posts): (User?, [Post]?) =
    await ezWithUnstructuredTaskGroup(result: .optionals, t1, t2)
```

---

## Cancellation

All variants use `withTaskCancellationHandler`:

- if the outer task (in which `ezWithUnstructuredTaskGroup` was called) is cancelled,
- then `cancel()` is called for all provided `Task` instances,
- and they subsequently complete according to their own rules (typically `CancellationError`).

This provides "structured" behavior for already created unstructured tasks:
you can still cancel them as a single group without losing control over their lifetimes.
