# AsyncStream.Continuation helpers (EZ*)

Набор удобных методов для управления `AsyncStream.Continuation`:
- автоматическое завершение (`finish()`) при деинициализации якоря;
- таймаут на завершение стрима;
- (опционально) привязка жизненного цикла continuation к объекту через `EZAssociatedKit`.

> Доступность:  
> - `ezSetTimeout(duration:)` — macOS 13+, iOS 16+, watchOS 9+, tvOS 16+  
> - остальное — macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+  
> Некоторые методы доступны только при `canImport(EZAssociatedKit) && canImport(ObjectiveC)`.

---

## API

```swift
extension AsyncStream.Continuation {
    public func ezSetTimeout(duration: Duration) // macOS13+/iOS16+...

    public func ezMakeAnchor() -> EZDeinitAnchor

    @discardableResult
    public func ezMakeAnchor(_ action: (EZDeinitAnchor) -> Void) -> Self

    // Только если canImport(EZAssociatedKit) && canImport(ObjectiveC)
    @discardableResult
    public func ezSnapToObject(_ object: AnyObject) -> Self
}
```

---

## Поведение

- `ezMakeAnchor()` создаёт `EZDeinitAnchor`, который вызывает `finish()` при деинициализации якоря.
- `ezMakeAnchor(_:)` — то же самое, но сразу отдаёт якорь в замыкание и возвращает `self`.
- `ezSetTimeout(duration:)` запускает `Task`, который спит указанное время и затем вызывает `finish()`.
- `ezSnapToObject(_:)` *(опционально)* привязывает якорь к объекту. Когда объект деинициализируется — стрим завершается (`finish()`).

---

## Примеры

### 1) Завершать стрим при деинициализации владельца (ручное хранение якоря)

```swift
final class Producer {
    private var anchor: EZDeinitAnchor?
    private var continuation: AsyncStream<Int>.Continuation?

    func makeStream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
            self.anchor = continuation.ezMakeAnchor() // при deinit Producer -> finish()
        }
    }
}
```

### 2) Таймаут на завершение стрима

```swift
let stream = AsyncStream<Int> { continuation in
    continuation.ezSetTimeout(duration: .seconds(2))

    Task.detached {
        for i in 0..<10 {
            continuation.yield(i)
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }
}

Task {
    for await value in stream {
        print(value)
    }
    print("stream finished")
}
```

> Условный пример (только при EZAssociatedKit + ObjectiveC):  
> `continuation.ezSnapToObject(self)` — завершить стрим при деинициализации `self`.
