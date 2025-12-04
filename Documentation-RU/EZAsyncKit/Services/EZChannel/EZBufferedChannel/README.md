# EZBufferedChannel

`EZBufferedChannel` — **буферизированный асинхронный канал** для обмена данными между задачами через `async/await`.

- В отличие от `EZChannel`, канал имеет **буфер фиксированного размера**.
- `set(_:)` не блокируется, пока в буфере есть свободное место.
- Если буфер заполнен — `set(_:)` ждёт, пока кто-то вызовет `get()` и освободит слот.
- При закрытии все ожидающие операции завершаются с ошибкой `EZChannelError.closed`.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

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

## Поведение

- **Буфер:** максимум `bufferSize` элементов.
- **get():**
  - если в буфере есть элементы — возвращает первый (FIFO);
  - иначе ждёт, пока будет установлен новый элемент через `set(_:)`.
- **set(_:):**
  - если есть ожидающий `get()` — значение отдаётся сразу ему;
  - иначе, если буфер не заполнен — значение добавляется в буфер;
  - иначе ждёт, пока освободится место (когда кто-то сделает `get()`).
- **close():**
  - переводит канал в состояние `isClosed = true`;
  - пробуждает все ожидающие `get()` / `set(_:)`, завершая их ошибкой `EZChannelError.closed`.
- **После закрытия:** любые новые `get()` и `set(_:)` выбрасывают `EZChannelError.closed`.
- **Параллельность:** допускается использование из нескольких `Task` (много продюсеров / много консюмеров).

---

## Примеры использования

### 1) Один продюсер — один консюмер (с буфером)

```swift
let channel = EZBufferedChannel<String>(bufferSize: 2)

Task {
    // первые 2 set пройдут сразу (буфер)
    try await channel.set("a")
    try await channel.set("b")

    // третий set может ждать, пока консюмер не сделает get()
    try await channel.set("c")

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
let channel = EZBufferedChannel<Int>(bufferSize: 8)

// Консюмеры
for id in 1...2 {
    Task {
        while true {
            do {
                let v = try await channel.get()
                print("Consumer \(id):", v)
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
                for i in 0..<10 {
                    try? await channel.set(producerId * 100 + i)
                }
            }
        }
        await group.waitForAll()
    }

    // Все продюсеры завершились — закрываем канал,
    // чтобы консюмеры корректно вышли из цикла.
    channel.close()
}
```
