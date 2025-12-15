# ezWithTaskGroupFirstSuccess

`ezWithTaskGroupFirstSuccess` — обёртка вокруг `withTaskGroup`, которая запускает несколько задач параллельно и возвращает **значение первой успешно завершившейся задачи**.

- Все задачи стартуют одновременно.
- Любые ошибки (`.failure`) **игнорируются**, пока хотя бы одна задача в итоге завершится успехом.
- Как только получен первый `.success(value)`:
  - группа отменяется (`cancelAll()`),
  - возвращается найденное `value`.
- Если задач не было или все они завершились ошибкой — функция возвращает `nil`.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+  
> Работает поверх `EZTaskItem<T, Error>` и `TaskGroup`.

---

## API

### Массивная форма

```swift
@discardableResult
public func ezWithTaskGroupFirstSuccess<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ ops: [EZTaskItem<T, Error>]
) async -> T?
```

- Принимает массив `EZTaskItem<T, Error>`.
- Запускает все задачи и возвращает:
  - первое успешно полученное значение `T`,
  - либо `nil`, если массив пустой или все задачи упали.

### Builder-форма

```swift
@discardableResult
public func ezWithTaskGroupFirstSuccess<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    @EZTaskItemArrayBuilder _ ops: () -> [EZTaskItem<T, Error>]
) async -> T?
```

Позволяет описать набор задач декларативно:

```swift
let value = await ezWithTaskGroupFirstSuccess {
    EZTaskItem { try await fastNetworkCall() }
    EZTaskItem { try await slowFallbackCall() }
}
```

### Variadic-форма

```swift
@discardableResult
public func ezWithTaskGroupFirstSuccess<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ ops: EZTaskItem<T, Error>...
) async -> T?
```

- Принимает список задач как vararg.
- Внутри просто делегирует на массивный вариант.

---

## Поведение

- Все переданные `EZTaskItem` запускаются в одном `TaskGroup`.
- Каждый child возвращает `Result<T, Error>`:
  - при успехе — `.success(value)`,
  - при ошибке — `.failure(error)`.
- Внутренний цикл `while let next = await group.next()`:
  - перебирает результаты по мере их завершения,
  - при первом `.success(value)` вызывает `group.cancelAll()` и возвращает `value`.
- Ошибки не пробрасываются наружу, они просто “проскакивают”, пока не найдётся успешная задача.
- Если ни одна задача не завершилась успехом, результат — `nil`.

---

## Параметр `isolation`

Во всех вариантах есть параметр:

```swift
isolation: isolated (any Actor)? = #isolation
```

- По умолчанию используется `#isolation`, то есть `TaskGroup` живёт в текущем actor-контексте.
- Можно явно указать другой actor для изоляции, если нужно.

---

## Примеры

### 1) Быстрый основной запрос + медленный фоллбек

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

### 2) Variadic-форма

```swift
let value = await ezWithTaskGroupFirstSuccess(
    EZTaskItem { try await fastNetworkCall() },
    EZTaskItem { try await slowFallbackCall() }
)
```

---

### 3) Билдер-синтаксис

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

`ezWithTaskGroupFirstSuccess` удобно использовать для сценариев “первый успешный ответ выигрывает”:
например, несколько реплик сервиса, основной и фоллбек запросы, несколько альтернативных источников данных и т.п.
