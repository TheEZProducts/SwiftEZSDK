# ezWithTaskGroup

`ezWithTaskGroup` — набор обёрток вокруг `withTaskGroup`, который позволяет удобно запускать несколько задач параллельно и получать результат **кортежем**:

- как значения (`.values`);
- как `Result` для каждой задачи (`.results`);
- как опционалы (`.optionals`);
- с “all-or-nothing” семантикой через `EZGroupError`.

Вместо ручной работы с индексами и массивами ты описываешь задачи через `EZTaskItem` (или с помощью билдер-синтаксиса `@EZTaskItemGroupBuilder`), а на выходе получаешь типизированный кортеж в том же порядке.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+  
> Используются вариативные дженерики (`each T`) и `TaskGroup`.

---

## Основные типы

Функции работают поверх следующих сущностей:

- `EZTaskItem<Success, Failure>` — элемент группы, который знает, как запустить задачу и вернуть результат.
- `EZTaskGroupResultValuesType` / `EZTaskGroupResultResultsType` / `EZTaskGroupResultOptionalsType` — маркеры для выбора режима (`.values`, `.results`, `.optionals`).
- `EZGroupError<ResultsTuple>` — ошибка, содержащая кортеж `Result`-ов по всем задачам.

---

## API (значения, `.values`)

### Небросающий вариант (Failure == Never)

```swift
public func ezWithTaskGroup<each T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: repeat (EZTaskItem<each T, Never>)
) async -> (repeat (each T))

public func ezWithTaskGroup<each T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, Never>)
) async -> (repeat each T)
```

- Запускает все `EZTaskItem` параллельно в `TaskGroup`.
- Не бросает ошибок (успех гарантирован типом `Failure == Never`).
- Возвращает кортеж значений, порядок — как в списке/билдере.

---

### Бросающий “all-or-nothing” вариант

```swift
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: repeat EZTaskItem<each T, each Err>
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T)

@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, each Err>)
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T)
```

Поведение:

- Внутри сначала собирает **кортеж `Result`** по всем задачам (режим `.results`).
- Если **хотя бы одна** задача завершилась с `.failure`, выбрасывает `EZGroupError`, в котором лежит весь кортеж результатов.
- Если все задачи успешны — возвращает кортеж развернутых значений (`Success`).

Удобно, когда нужна “всё или ошибка целиком”, но при этом важно сохранить информацию об индивидуальных ошибках.

---

## API (результаты, `.results`)

```swift
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    _ ops: repeat (EZTaskItem<each T, each Err>)
) async -> (repeat (Result<each T, each Err>))

@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err: Error>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, each Err>)
) async -> (repeat (Result<each T, each Err>))
```

- Никогда не бросает сам по себе.
- Каждая задача даёт `Result<Success, Failure>`.
- Порядок `Result` в кортеже соответствует порядку задач.

---

## API (опционалы, `.optionals`)

```swift
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err: Error>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultOptionalsType,
    _ ops: repeat EZTaskItem<each T, each Err>
) async -> (repeat Optional<each T>)

@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultOptionalsType,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, each Err>)
) async -> (repeat Optional<each T>)
```

- Обёртка над `.results`:
  - `.success(value)` → `value`
  - `.failure(error)` → `nil`
- Удобно, когда детали ошибок не важны, нужно только “есть значение / нет значения”.

---

## Параметр `isolation`

Во всех вариантах есть параметр:

```swift
isolation: isolated (any Actor)? = #isolation
```

Он задаёт изоляцию для `TaskGroup`:

- По умолчанию используется `#isolation`, то есть группа создаётся в текущем actor-контексте.
- Можно явно передать другой actor для изоляции, если нужно.

---

## Примеры

### 1) Простые значения (не бросают, `.values`)

```swift
let (a, b): (Int, String) = await ezWithTaskGroup(
    EZTaskItem { 1 },
    EZTaskItem { "two" }
)
```

То же самое, но через билдер:

```swift
let (a, b): (Int, String) = await ezWithTaskGroup {
    EZTaskItem { 1 }
    EZTaskItem { "two" }
}
```

---

### 2) “Всё или ошибка” (бросающий `.values` с `EZGroupError`)

```swift
let (user, posts) = try await ezWithTaskGroup {
    EZTaskItem { try await loadUser() }
    EZTaskItem { try await loadPosts() }
}
```

Если хотя бы один таск упадёт, ты получишь `EZGroupError<(Result<User, Error>, Result<[Post], Error>)>`,
в котором лежат оба результата и можно разобраться, что именно пошло не так.

---

### 3) Явная работа с `Result` (`.results`)

```swift
let (userResult, postsResult): (Result<User, Error>, Result<[Post], Error>) =
    await ezWithTaskGroup(
        result: .results,
        EZTaskItem { try await loadUser() },
        EZTaskItem { try await loadPosts() }
    )

switch userResult {
case .success(let user): print("User:", user)
case .failure(let error): print("User error:", error)
}
```

Или через билдер:

```swift
let (userResult, postsResult) = await ezWithTaskGroup(result: .results) {
    EZTaskItem { try await loadUser() }
    EZTaskItem { try await loadPosts() }
}
```

---

### 4) Опциональные значения (`.optionals`)

```swift
let (user, posts): (User?, [Post]?) = await ezWithTaskGroup(result: .optionals) {
    EZTaskItem { try await loadUser() }
    EZTaskItem { try await loadPosts() }
}

if let user { print("Got user:", user) }
if let posts { print("Got", posts.count, "posts") }
```

---

`ezWithTaskGroup` снимает большую часть рутины вокруг `TaskGroup` + кортежей с вариативными дженериками:
ты описываешь, что запускать, а SDK заботится о запуске, сборе и типобезопасном возврате результатов.
