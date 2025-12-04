# Actor extensions (EZ*)

Набор утилит для удобной работы с `actor` и задачами, где операция принимает `(isolated Self)`.

> Доступность:  
> - `isIsolated` и `ezTaskImmediate` — macOS 26+, iOS 26+, watchOS 26+, tvOS 26+  
> - остальное — macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
extension Actor {
    public var isIsolated: Bool // macOS/iOS/watchOS/tvOS 26+

    public func ezWithIsolation<T>(
        _ body: @Sendable (isolated Self) async throws -> T
    ) async rethrows -> T

    @discardableResult
    public func ezTask<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error>

    @discardableResult
    public func ezTaskImmediate<R>( // macOS/iOS/watchOS/tvOS 26+
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error>

    @discardableResult
    public func ezTaskDetached<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @Sendable @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error>

    public func ezUnsafeRun<R>(_ body: @escaping (isolated Self) throws -> R) throws -> R
    public func ezUnsafeRun<R>(_ body: @escaping (isolated Self) -> R) -> R
}
```

---

## Поведение

- `ezWithIsolation(...)`: выполняет `body` в изоляции актора (внутри `await` контекста актора).
- `ezTask(...)`: создаёт `Task`, который выполнит `operation` в изоляции этого актора.
- `ezTaskImmediate(...)` (26+): создаёт `Task.immediate`, который может стартовать немедленно (когда это возможно по правилам runtime).
- `ezTaskDetached(...)`: создаёт `Task.detached`, но сама операция всё равно выполняется в изоляции актора (происходит hop на actor внутри задачи).
- `isIsolated` (26+): возвращает `true`, если код прямо сейчас выполняется на executor-е этого актора (удобно для дебага/asserтов).
- `ezUnsafeRun(...)`: **небезопасный** синхронный запуск тела, принимающего `isolated Self`, через `unsafeBitCast`. Используй только если понимаешь последствия (не “перепрыгивает” на actor executor и не делает ожиданий — это именно unsafe-обход).

---

## Примеры

### 1) Планирование работы на акторе из не-async контекста

```swift
actor Counter {
    private var value = 0
    func inc() { value += 1 }
    func get() -> Int { value }
}

let counter = Counter()

// Запускаем инкремент без явного await на месте вызова
let task = counter.ezTask { isolatedSelf in
    isolatedSelf.inc()
    return isolatedSelf.get()
}

let result = try await task.value
print(result)
```

### 2) Несколько параллельных задач, безопасно сериализованных актором

```swift
actor Store {
    private var items: [Int] = []
    func add(_ x: Int) { items.append(x) }
    func snapshot() -> [Int] { items }
}

let store = Store()

let tasks = (0..<10).map { i in
    store.ezTaskDetached { isolatedSelf in
        isolatedSelf.add(i)
    }
}

for t in tasks { _ = try await t.value }

let values = try await store.snapshot()
print(values.count) // 10
```
