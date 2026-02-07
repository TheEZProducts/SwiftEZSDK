# EZBufferedChannel

`EZBufferedChannel` is a **buffered asynchronous channel** for exchanging data between tasks via `async/await`.

- Unlike `EZChannel`, this channel has a **fixed-size buffer**.
- `set(_:)` does not block as long as there is free space in the buffer.
- If the buffer is full, `set(_:)` waits until someone calls `get()` and frees a slot.
- On close, all pending operations complete with an `EZChannelError.closed` error.

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
public actor EZBufferedChannel<T: Sendable> {
    public private(set) var isClosed: Bool
    public init(bufferSize: Int)

    public func get() async throws -> T
    public func set(_ value: T) async throws
    public func close()
}
```

---

## Behavior

- **Buffer:** holds a maximum of `bufferSize` elements.
- **get():**
  - if the buffer contains elements, returns the first one (FIFO);
  - otherwise waits until a new element is provided via `set(_:)`.
- **set(_:):**
  - if there is a pending `get()`, the value is delivered directly to it;
  - otherwise, if the buffer is not full, the value is added to the buffer;
  - otherwise waits until space becomes available (when someone calls `get()`).
- **close():**
  - transitions the channel to `isClosed = true`;
  - wakes all pending `get()` / `set(_:)` calls, completing them with an `EZChannelError.closed` error.
- **After closing:** any new `get()` and `set(_:)` calls throw `EZChannelError.closed`.
- **Concurrency:** can be used from multiple `Task` instances (many producers / many consumers).

---

## Usage Examples

### 1) One producer -- one consumer (with buffer)

```swift
let channel = EZBufferedChannel<String>(bufferSize: 2)

Task {
    // first 2 set calls complete immediately (buffer)
    try await channel.set("a")
    try await channel.set("b")

    // third set may wait until consumer calls get()
    try await channel.set("c")

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
let channel = EZBufferedChannel<Int>(bufferSize: 8)

// Consumers
for id in 1...2 {
    Task {
        while true {
            do {
                let v = try await channel.get()
                print("Consumer \(id):", v)
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
                for i in 0..<10 {
                    try? await channel.set(producerId * 100 + i)
                }
            }
        }
        await group.waitForAll()
    }

    // All producers finished — close the channel
    // so consumers exit the loop correctly.
    channel.close()
}
```
