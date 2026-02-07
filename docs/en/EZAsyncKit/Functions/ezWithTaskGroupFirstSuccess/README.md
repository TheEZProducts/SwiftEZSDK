# ezWithTaskGroupFirstSuccess

`ezWithTaskGroupFirstSuccess` is a wrapper around `withTaskGroup` that runs multiple tasks in parallel and returns the **value of the first successfully completed task**.

- All tasks start simultaneously.
- Any errors (`.failure`) are **ignored** as long as at least one task eventually completes successfully.
- As soon as the first `.success(value)` is obtained:
  - the group is cancelled (`cancelAll()`),
  - the found `value` is returned.
- If there were no tasks or all of them completed with errors, the function returns `nil`.

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+
> Works on top of `EZTaskItem<T, Error>` and `TaskGroup`.

---

## API

### Array form

```swift
@discardableResult
public func ezWithTaskGroupFirstSuccess<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ ops: [EZTaskItem<T, Error>]
) async -> T?
```

- Takes an array of `EZTaskItem<T, Error>`.
- Runs all tasks and returns:
  - the first successfully obtained value `T`,
  - or `nil` if the array is empty or all tasks failed.

### Builder form

```swift
@discardableResult
public func ezWithTaskGroupFirstSuccess<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    @EZTaskItemArrayBuilder _ ops: () -> [EZTaskItem<T, Error>]
) async -> T?
```

Lets you describe the set of tasks declaratively:

```swift
let value = await ezWithTaskGroupFirstSuccess {
    EZTaskItem { try await fastNetworkCall() }
    EZTaskItem { try await slowFallbackCall() }
}
```

### Variadic form

```swift
@discardableResult
public func ezWithTaskGroupFirstSuccess<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ ops: EZTaskItem<T, Error>...
) async -> T?
```

- Takes a list of tasks as varargs.
- Internally delegates to the array variant.

---

## Behavior

- All provided `EZTaskItem` instances are launched in a single `TaskGroup`.
- Each child returns `Result<T, Error>`:
  - on success -- `.success(value)`,
  - on error -- `.failure(error)`.
- The internal loop `while let next = await group.next()`:
  - iterates over results as they complete,
  - on the first `.success(value)`, calls `group.cancelAll()` and returns `value`.
- Errors are not propagated; they are simply skipped until a successful task is found.
- If no task completed successfully, the result is `nil`.

---

## The `isolation` parameter

All variants include the parameter:

```swift
isolation: isolated (any Actor)? = #isolation
```

- By default, `#isolation` is used, meaning the `TaskGroup` runs in the current actor context.
- You can explicitly specify a different actor for isolation if needed.

---

## Examples

### 1) Fast primary request + slow fallback

```swift
let items: [EZTaskItem<Int, Error>] = [
    EZTaskItem { try await fastNetworkCall() },
    EZTaskItem { try await slowFallbackCall() }
]

let firstSuccess = await ezWithTaskGroupFirstSuccess(items)

if let value = firstSuccess {
    print("Got first successful value:", value)
} else {
    print("All tasks failed")
}
```

---

### 2) Variadic form

```swift
let value = await ezWithTaskGroupFirstSuccess(
    EZTaskItem { try await fastNetworkCall() },
    EZTaskItem { try await slowFallbackCall() }
)
```

---

### 3) Builder syntax

```swift
let value = await ezWithTaskGroupFirstSuccess {
    EZTaskItem { try await primaryCall() }
    EZTaskItem { try await secondaryCall() }
    EZTaskItem { try await backupCall() }
}

if let value {
    print("First ok:", value)
}
```

`ezWithTaskGroupFirstSuccess` is convenient for "first successful response wins" scenarios:
for example, multiple service replicas, primary and fallback requests, multiple alternative data sources, and so on.
