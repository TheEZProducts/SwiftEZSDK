# EZChannel

`EZChannel` — **безбуферный асинхронный канал** для обмена данными между задачами через `async/await`.

- Каждый `set(_:)` синхронно спаривается ровно с одним `get()`.
- Канал потокобезопасен за счёт `actor`.
- При закрытии все ожидающие операции завершаются с ошибкой `EZChannelError.closed`.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

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

## Поведение

- **Без буфера:** `get()` ждёт, пока появится `set(_:)`, и наоборот.
- **close():**
  - переводит канал в состояние `isClosed = true`;
  - пробуждает все ожидающие `get()` / `set(_:)`, завершая их ошибкой `EZChannelError.closed`.
- **После закрытия:** любые новые `get()` и `set(_:)` выбрасывают `EZChannelError.closed`.
- **Параллельность:** допускается использование из нескольких `Task` (много продюсеров / много консюмеров).

---

## Примеры использования

### 1) Один продюсер — один консюмер

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
            break // канал закрыт
        }
    }
}
```

### 2) Много продюсеров — много консюмеров

```swift
let channel = EZChannel<Int>()

// Консюмеры
for id in 1...2 {
    Task {
        while true {
            do {
                let value = try await channel.get()
                print("Consumer \(id):", value)
            } catch {
                break // канал закрыт
            }
        }
    }
}

// Продюсеры (параллельно)
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

    // Когда все продюсеры завершились — закрываем канал,
    // чтобы консюмеры корректно вышли из цикла.
    channel.close()
}
```
