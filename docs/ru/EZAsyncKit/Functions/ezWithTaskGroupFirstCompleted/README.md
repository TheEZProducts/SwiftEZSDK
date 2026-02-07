# ezWithTaskGroupFirstCompleted

`ezWithTaskGroupFirstCompleted` — набор обёрток вокруг `withTaskGroup`, который запускает несколько задач параллельно и возвращает **первую завершившуюся**:

- либо как `Result<Success, Failure>?` (`.results`),
- либо как значение `Success?` c бросанием первой ошибки (`.values`).

Остальные задачи **отменяются** сразу после того, как получен первый результат (успех или ошибка).

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+  
> Использует `EZTaskItem`, `EZTaskGroupResultValuesType` и `EZTaskGroupResultResultsType`.

---

## Основная идея

- Ты описываешь набор операций через `EZTaskItem<T, Error>`.
- Все задачи стартуют одновременно в `TaskGroup`.
- Как только первая задача завершилась (`.success` или `.failure`):
  - её `Result` возвращается наружу;
  - остальные задачи получают `cancelAll()` и дальше могут завершиться отменой.
- Если задач не было (`ops` пустой) — возвращается `nil`.

---

## API — первый `Result` (`.results`)

### Массивная форма

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    _ ops: [EZTaskItem<T, Error>]
) async -> Result<T, Error>?
```

- Запускает все задачи из массива.
- Возвращает первый `Result<T, Error>?`:
  - `nil`, если массив пустой;
  - `.success` или `.failure` — от первой завершившейся задачи.

### Variadic-форма

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    _ ops: EZTaskItem<T, Error>...
) async -> Result<T, Error>?
```

Просто обёртка над массивным вариантом.

### Builder-форма

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    @EZTaskItemArrayBuilder _ ops: () -> [EZTaskItem<T, Error>]
) async -> Result<T, Error>?
```

Позволяет описать список задач в виде:

```swift
let first = await ezWithTaskGroupFirstCompleted(result: .results) {
    EZTaskItem { try await fastTask() }
    EZTaskItem { try await slowTask() }
}
```

---

## API — первое значение (`.values`)

Здесь поверх `.results`-вариантов строится удобный слой, который:

- возвращает **значение** (`T?`),
- либо **бросает первую ошибку**.

### Массивная форма

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: [EZTaskItem<T, Error>]
) async throws -> T?
```

Поведение:

- Внутри вызывает `.results`-версию.
- Если вернулся `nil` (нет задач) — возвращает `nil`.
- Если первый результат `.success(value)` — возвращает `value`.
- Если первый результат `.failure(error)` — бросает `error`.

### Variadic-форма

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: EZTaskItem<T, Error>...
) async throws -> T?
```

Делегирует в массивный `.values`-вариант.

### Builder-форма

```swift
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskItemArrayBuilder _ ops: () -> [EZTaskItem<T, Error>]
) async throws -> T?
```

То же самое, но с декларативным описанием задач.

---

## Параметр `isolation`

Во всех вариантах есть:

```swift
isolation: isolated (any Actor)? = #isolation
```

- По умолчанию используется `#isolation`, то есть группа живёт в текущем actor-контексте.
- Можно явно указать другой actor для изоляции выполнения.

---

## Примеры

### 1) Первый завершившийся `Result`

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

### 2) Первое значение (бросает по первой ошибке)

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

### 3) Билдер-синтаксис

```swift
let first = await ezWithTaskGroupFirstCompleted(result: .results) {
    EZTaskItem { try await fastTask() }
    EZTaskItem { try await slowTask() }
}
```

`ezWithTaskGroupFirstCompleted` удобно использовать для “гонок” (race) между задачами:
кто первый закончил — того результат и интересует, остальные можно смело отменять.
