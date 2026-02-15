# ezWithTaskGroup

`ezWithTaskGroup` is a set of wrappers around `withTaskGroup` that lets you conveniently run multiple tasks in parallel and receive the result as a **tuple**:

- as values (`.values`);
- as a `Result` for each task (`.results`);
- as optionals (`.optionals`);
- with "all-or-nothing" semantics via `EZGroupError`.

Instead of manually working with indices and arrays, you describe tasks using `EZTaskItem` (or with builder syntax via `@EZTaskItemGroupBuilder`), and the output is a typed tuple in the same order.

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+
> Uses variadic generics (`each T`) and `TaskGroup`.

---

## Core Types

The functions operate on top of the following entities:

- `EZTaskItem<Success, Failure>` -- a group element that knows how to run a task and return a result.
- `EZTaskGroupResultValuesType` / `EZTaskGroupResultResultsType` / `EZTaskGroupResultOptionalsType` -- markers for selecting the mode (`.values`, `.results`, `.optionals`).
- `EZGroupError<ResultsTuple>` -- an error containing a tuple of `Result`s for all tasks.

---

## API (values, `.values`)

### Non-throwing variant (Failure == Never)

```swift
public func ezWithTaskGroup<each T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: repeat (EZTaskItem<each T, Never>)
) async -> (repeat (each T))

public func ezWithTaskGroup<each T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, Never>)
) async -> (repeat each T)
```

- Runs all `EZTaskItem` instances in parallel within a `TaskGroup`.
- Does not throw errors (success is guaranteed by the `Failure == Never` type).
- Returns a tuple of values, in the same order as the list/builder.

---

### Throwing "all-or-nothing" variant

```swift
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: repeat EZTaskItem<each T, each Err>
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T)

@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, each Err>)
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T)
```

Behavior:

- Internally first collects a **tuple of `Result`s** for all tasks (`.results` mode).
- If **at least one** task completed with `.failure`, throws `EZGroupError` containing the entire tuple of results.
- If all tasks succeeded, returns a tuple of unwrapped values (`Success`).

Convenient when you need "all or full error" but also want to preserve information about individual errors.

---

## API (results, `.results`)

```swift
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    _ ops: repeat (EZTaskItem<each T, each Err>)
) async -> (repeat (Result<each T, each Err>))

@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err: Error>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, each Err>)
) async -> (repeat (Result<each T, each Err>))
```

- Never throws on its own.
- Each task produces a `Result<Success, Failure>`.
- The order of `Result` values in the tuple matches the order of tasks.

---

## API (optionals, `.optionals`)

```swift
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err: Error>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultOptionalsType,
    _ ops: repeat EZTaskItem<each T, each Err>
) async -> (repeat Optional<each T>)

@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultOptionalsType,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, each Err>)
) async -> (repeat Optional<each T>)
```

- A wrapper on top of `.results`:
  - `.success(value)` -> `value`
  - `.failure(error)` -> `nil`
- Convenient when error details are not important and you only need "has value / no value".

---

## The `isolation` parameter

All variants include the parameter:

```swift
isolation: isolated (any Actor)? = #isolation
```

It specifies the isolation for the `TaskGroup`:

- By default, `#isolation` is used, meaning the group is created in the current actor context.
- You can explicitly pass a different actor for isolation if needed.

---

## Examples

### 1) Simple values (non-throwing, `.values`)

```swift
let (a, b): (Int, String) = await ezWithTaskGroup(
    EZTaskItem { 1 },
    EZTaskItem { "two" }
)
```

The same, but using a builder:

```swift
let (a, b): (Int, String) = await ezWithTaskGroup {
    EZTaskItem { 1 }
    EZTaskItem { "two" }
}
```

---

### 2) "All or error" (throwing `.values` with `EZGroupError`)

```swift
let (user, posts) = try await ezWithTaskGroup {
    EZTaskItem { try await loadUser() }
    EZTaskItem { try await loadPosts() }
}
```

If at least one task fails, you get `EZGroupError<(Result<User, Error>, Result<[Post], Error>)>`
containing both results so you can figure out what exactly went wrong.

---

### 3) Explicit work with `Result` (`.results`)

```swift
let (userResult, postsResult): (Result<User, Error>, Result<[Post], Error>) =
    await ezWithTaskGroup(
        result: .results,
        EZTaskItem { try await loadUser() },
        EZTaskItem { try await loadPosts() }
    )

switch userResult {
case .success(let user): print("User:", user)
case .failure(let error): print("User error:", error)
}
```

Or using a builder:

```swift
let (userResult, postsResult) = await ezWithTaskGroup(result: .results) {
    EZTaskItem { try await loadUser() }
    EZTaskItem { try await loadPosts() }
}
```

---

### 4) Optional values (`.optionals`)

```swift
let (user, posts): (User?, [Post]?) = await ezWithTaskGroup(result: .optionals) {
    EZTaskItem { try await loadUser() }
    EZTaskItem { try await loadPosts() }
}

if let user { print("Got user:", user) }
if let posts { print("Got", posts.count, "posts") }
```

---

`ezWithTaskGroup` removes most of the boilerplate around `TaskGroup` + tuples with variadic generics:
you describe what to run, and the SDK handles launching, collecting, and returning results in a type-safe manner.
