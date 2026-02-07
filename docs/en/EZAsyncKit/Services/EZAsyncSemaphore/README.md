# EZAsyncSemaphore

`EZAsyncSemaphore` is a lightweight asynchronous semaphore for coordinating concurrent tasks.

Its behavior is similar to a classic counting semaphore:

- `wait()` decreases the number of permits; if it becomes negative, the calling task is suspended until a new permit becomes available.
- `signal()` increases the number of permits and resumes one waiting task (if any).

Cancellation: `wait()` uses `Task.checkCancellation()` and a stoppable continuation, so
if a task is cancelled while waiting, it will receive `CancellationError`, and the internal permit counter will be adjusted back.

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZAsyncSemaphore {
    public init(value: Int = 1)

    public func wait() async throws
    public func signal()
}
```

---

## Behavior

- `init(value:)`:
  - creates a semaphore with the specified initial number of permits;
  - negative values are clamped to zero (`max(0, value)`).

- `wait()`:
  - calls `Task.checkCancellation()` before blocking;
  - decreases `permits`;
  - if `permits >= 0`, returns immediately (a permit was available);
  - if `permits < 0`, suspends the task until another task calls `signal()`;
  - if the task is cancelled while waiting, throws `CancellationError`, and `permits` is rolled back (to avoid losing a permit).

- `signal()`:
  - increases `permits`;
  - if there are waiting tasks, resumes the first one that does not yet have a result (`result == nil`);
  - if there are no waiters, the permit "accumulates" and will be used by the next `wait()`.

---

## Usage Examples

### Limiting concurrency (up to N simultaneous tasks)

```swift
let semaphore = EZAsyncSemaphore(value: 2)

await withTaskGroup(of: Void.self) { group in
    for i in 0..<5 {
        group.addTask {
            try await semaphore.wait()
            defer { Task { await semaphore.signal() } }

            // critical section (at most 2 tasks at a time)
            print("Task", i, "entered")
            try? await Task.sleep(nanoseconds: 300_000_000)
            print("Task", i, "leaving")
        }
    }
}
```

### Protecting a critical section

```swift
let semaphore = EZAsyncSemaphore(value: 1) // binary semaphore

func doWork(id: Int) async {
    try? await semaphore.wait()
    defer { Task { await semaphore.signal() } }

    // code that should run only by one task at a time
    print("Work from", id)
}
```

---
