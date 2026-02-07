# EZChannel

`EZChannel` is an **unbuffered asynchronous channel** for exchanging data between tasks via `async/await`.

- Each `set(_:)` synchronously pairs with exactly one `get()`.
- The channel is thread-safe thanks to `actor`.
- On close, all pending operations complete with an `EZChannelError.closed` error.

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
public actor EZChannel<T: Sendable> {
    public private(set) var isClosed: Bool
    public init()

    public func get() async throws -> T
    public func set(_ value: T) async throws
    public func close()
}

public enum EZChannelError: String, LocalizedError, Sendable {
    case closed = "Channel is closed"
}
```

---

## Behavior

- **No buffer:** `get()` waits until a `set(_:)` arrives, and vice versa.
- **close():**
  - transitions the channel to `isClosed = true`;
  - wakes all pending `get()` / `set(_:)` calls, completing them with an `EZChannelError.closed` error.
- **After closing:** any new `get()` and `set(_:)` calls throw `EZChannelError.closed`.
- **Concurrency:** can be used from multiple `Task` instances (many producers / many consumers).

---

## Usage Examples

### 1) One producer -- one consumer

```swift
let channel = EZChannel<String>()

Task {
    for i in 1...3 {
        try await channel.set("item \(i)")
    }
    channel.close()
}

Task {
    while true {
        do {
            let value = try await channel.get()
            print("Received:", value)
        } catch {
            break // channel closed
        }
    }
}
```

### 2) Many producers -- many consumers

```swift
let channel = EZChannel<Int>()

// Consumers
for id in 1...2 {
    Task {
        while true {
            do {
                let value = try await channel.get()
                print("Consumer \(id):", value)
            } catch {
                break // channel closed
            }
        }
    }
}

// Producers (in parallel)
Task {
    await withTaskGroup(of: Void.self) { group in
        for producerId in 1...3 {
            group.addTask {
                for i in 0..<3 {
                    try? await channel.set(producerId * 10 + i)
                }
            }
        }
        await group.waitForAll()
    }

    // When all producers have finished — close the channel
    // so consumers exit the loop correctly.
    channel.close()
}
```
