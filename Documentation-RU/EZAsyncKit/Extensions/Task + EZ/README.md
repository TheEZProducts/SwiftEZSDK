# Task Anchors & Cancellation Helpers

Этот набор расширений помогает:
- автоматически **отменять `Task` при деинициализации** (через `EZDeinitAnchor`);
- **привязывать `Task` к жизненному циклу объекта** (опционально через `EZAssociatedKit`);
- корректно **прокидывать отмену текущей задачи** внутрь `Task` (через `ezSnapToCurrentTask`).

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+  
> Некоторые методы доступны только при `canImport(EZAssociatedKit) && canImport(ObjectiveC)`.

---

## API

```swift
extension EZDeinitAnchor {
    public convenience init<Success, Failure>(task: Task<Success, Failure>)
}

extension Task {
    public func ezMakeAnchor() -> EZDeinitAnchor

    @discardableResult
    public func ezMakeAnchor(_ action: (EZDeinitAnchor) -> Void) -> Self

    // Только если canImport(EZAssociatedKit) && canImport(ObjectiveC)
    @discardableResult
    public func ezSnapToObject(_ object: AnyObject) -> Self
}

extension Task {
    public func ezSnapToCurrentTask(
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> Success
}
```

---

## Поведение

### `EZDeinitAnchor(task:)`
Создаёт `EZDeinitAnchor`, который вызовет `task.cancel()` при деинициализации якоря.

### `Task.ezMakeAnchor() / ezMakeAnchor(_:)`
- `ezMakeAnchor()` — возвращает якорь для этой задачи.
- `ezMakeAnchor(_:)` — то же самое, но сразу отдаёт якорь в замыкание (удобно для хранения/привязки) и возвращает `self` для чейнинга.

### `Task.ezSnapToObject(_:)` *(опционально)*
Если доступны `EZAssociatedKit` и `ObjectiveC`, привязывает якорь к объекту (через associated storage).  
Результат: когда объект деинициализируется — якорь деинициализируется — задача отменяется.

### `Task.ezSnapToCurrentTask(...)`
Ожидает результат задачи, но при отмене **текущей** (внешней) задачи автоматически вызывает `cancel()` у этой задачи.

---

## Примеры

### 1) Отмена задачи при деинициализации владельца (ручное хранение якоря)

```swift
final class Loader {
    private var anchor: EZDeinitAnchor?

    func start() {
        let task = Task {
            try await fetchSomething()
        }

        // Пока Loader жив — anchor жив — задача не отменяется автоматически
        anchor = task.ezMakeAnchor()
    }
}
```

### 2) Прокидывание отмены текущей задачи внутрь `Task`

```swift
func loadWithCancellationPropagation() async throws -> Data {
    let task = Task<Data, Error> {
        try await fetchData()
    }

    // Если вызывающая задача будет отменена — task.cancel() вызовется автоматически
    return try await task.ezSnapToCurrentTask()
}
```

> Условный пример (только при EZAssociatedKit + ObjectiveC):  
> `Task { ... }.ezSnapToObject(self)` — привязка к жизненному циклу `self`.
