# ezWithTaskGroupFirstCompleted

`ezWithTaskGroupFirstCompleted` is a set of wrappers around `withTaskGroup` that runs multiple tasks in parallel and returns the **first one to complete**:

- either as `Result<Success, Failure>?` (`.results`),
- or as a value `Success?` throwing the first error (`.values`).

The remaining tasks are **cancelled** as soon as the first result is obtained (success or error).

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+
> Uses `EZTaskItem`, `EZTaskGroupResultValuesType`, and `EZTaskGroupResultResultsType`.

---

## Core Idea

- You describe a set of operations via `EZTaskItem<T, Error>`.
- All tasks start simultaneously in a `TaskGroup`.
- As soon as the first task completes (`.success` or `.failure`):
  - its `Result` is returned;
  - the remaining tasks receive `cancelAll()` and may subsequently complete with cancellation.
- If there were no tasks (`ops` is empty), `nil` is returned.

---

## API -- first `Result` (`.results`)

### Array form

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    _ ops: [EZTaskItem<T, Error>]
) async -> Result<T, Error>?
```

- Runs all tasks from the array.
- Returns the first `Result<T, Error>?`:
  - `nil` if the array is empty;
  - `.success` or `.failure` from the first completed task.

### Variadic form

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    _ ops: EZTaskItem<T, Error>...
) async -> Result<T, Error>?
```

Simply a wrapper over the array variant.

### Builder form

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    @EZTaskItemArrayBuilder _ ops: () -> [EZTaskItem<T, Error>]
) async -> Result<T, Error>?
```

Lets you describe the task list as:

```swift
let first = await ezWithTaskGroupFirstCompleted(result: .results) {
    EZTaskItem { try await fastTask() }
    EZTaskItem { try await slowTask() }
}
```

---

## API -- first value (`.values`)

Here, a convenience layer is built on top of the `.results` variants that:

- returns a **value** (`T?`),
- or **throws the first error**.

### Array form

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: [EZTaskItem<T, Error>]
) async throws -> T?
```

Behavior:

- Internally calls the `.results` version.
- If `nil` is returned (no tasks), returns `nil`.
- If the first result is `.success(value)`, returns `value`.
- If the first result is `.failure(error)`, throws `error`.

### Variadic form

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: EZTaskItem<T, Error>...
) async throws -> T?
```

Delegates to the array `.values` variant.

### Builder form

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskItemArrayBuilder _ ops: () -> [EZTaskItem<T, Error>]
) async throws -> T?
```

Same thing, but with declarative task description.

---

## The `isolation` parameter

All variants include:

```swift
isolation: isolated (any Actor)? = #isolation
```

- By default, `#isolation` is used, meaning the group runs in the current actor context.
- You can explicitly specify a different actor for execution isolation.

---

## Examples

### 1) First completed `Result`

```swift
let tasks: [EZTaskItem<Int, Error>] = [
    EZTaskItem { try await fastTask() },
    EZTaskItem { try await slowTask() }
]

let first = await ezWithTaskGroupFirstCompleted(result: .results, tasks)

switch first {
case .success(let value)?:
    print("First value:", value)
case .failure(let error)?:
    print("First error:", error)
case nil:
    print("No tasks")
}
```

---

### 2) First value (throws on first error)

```swift
let value = try await ezWithTaskGroupFirstCompleted(
    EZTaskItem { try await fastTask() },
    EZTaskItem { try await slowTask() }
)

if let value {
    print("First finished value:", value)
}
```

---

### 3) Builder syntax

```swift
let first = await ezWithTaskGroupFirstCompleted(result: .results) {
    EZTaskItem { try await fastTask() }
    EZTaskItem { try await slowTask() }
}
```

`ezWithTaskGroupFirstCompleted` is convenient for "racing" tasks:
whichever finishes first provides the result you care about, and the rest can be safely cancelled.
