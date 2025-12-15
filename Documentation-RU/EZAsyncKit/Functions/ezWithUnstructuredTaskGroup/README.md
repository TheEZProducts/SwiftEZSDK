# ezWithUnstructuredTaskGroup

`ezWithUnstructuredTaskGroup` — набор хелперов для ожидания уже созданных **неструктурированных** задач (`Task`) параллельно, с удобным возвратом результата кортежем и корректной отменой.

В отличие от `ezWithTaskGroup*`, здесь задачи создаются **снаружи** (unstructured `Task`), а хелпер только:

- дожидается их результатов;
- аккуратно прокидывает отмену (через `withTaskCancellationHandler`);
- приводит всё к удобной форме:
  - кортеж значений (`.values`),
  - кортеж `Result`-ов (`.results`),
  - кортеж опционалов (`.optionals`),
  - или “all-or-nothing” с `EZGroupError`.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+  
> Работает с уже созданными `Task<Success, Failure>` и не создаёт `TaskGroup`.

---

## Основная идея

- Ты создаёшь несколько `Task` (например, в разных частях кода или заранее).
- Передаёшь их в `ezWithUnstructuredTaskGroup(...)`.
- Хелпер:
  - ждёт все задачи **параллельно** (через вариативные дженерики `each T`),
  - следит за отменой внешней задачи и вызывает `cancel()` у всех детей,
  - возвращает результат в удобной форме (значения / Result / опционалы).

---

## Значения (`.values`) — небросающий вариант

### Variadic-/builder-API для `Task<Success, Never>`

```swift
@discardableResult
public func ezWithUnstructuredTaskGroup<each T>(
    result: EZTaskGroupResultValuesType = .values,
    _ values: repeat Task<each T, Never>
) async -> (repeat each T)

@discardableResult
public func ezWithUnstructuredTaskGroup<each T>(
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, Never>)
) async -> (repeat each T)
```

- Принимает кортеж небросающих задач (`Failure == Never`).
- Под капотом использует `withTaskCancellationHandler`:
  - `operation` дожидается всех `task.value`,
  - `onCancel` вызывает `cancel()` для каждой задачи.
- Возвращает кортеж значений в том же порядке, что и входные `Task`.

**Пример:**

```swift
let t1 = Task { 1 }
let t2 = Task { 2 }

let (a, b) = await ezWithUnstructuredTaskGroup(t1, t2)
// a == 1, b == 2
```

---

## Значения (`.values`) — бросающий вариант с `EZGroupError`

```swift
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultValuesType = .values,
    _ values: repeat Task<each T, each Err>
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T)

@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, each Err>)
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T)
```

Поведение:

- Сначала вызывает `.results`-оверлоад и получает кортеж `Result<Success, Failure>`.
- Если хотя бы один `Result` — `.failure`, выбрасывает `EZGroupError`, внутри которого лежит **весь кортеж** результатов.
- Если все задачи завершились успехом — возвращает кортеж развернутых значений.

Удобно, когда нужен “all-or-nothing” поверх уже созданных `Task`.

**Пример:**

```swift
let t1 = Task { try await loadUser() }
let t2 = Task { try await loadPosts() }

let (user, posts) = try await ezWithUnstructuredTaskGroup(t1, t2)
```

---

## Результаты (`.results`)

```swift
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultResultsType,
    _ values: repeat Task<each T, each Err>
) async -> (repeat Result<each T, each Err>)

@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultResultsType,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, each Err>)
) async -> (repeat Result<each T, each Err>)
```

- Никогда не бросает сам по себе.
- Каждый `Task` возвращается как `Result<Success, Failure>`:
  - при успехе — `.success(value)`,
  - при ошибке — `.failure(error)`.
- Отмена внешней задачи всё так же приводит к `cancel()` всех внутренних задач.

**Пример:**

```swift
let t1 = Task { try await loadUser() }
let t2 = Task { try await loadPosts() }

let (userResult, postsResult): (Result<User, Error>, Result<[Post], Error>) =
    await ezWithUnstructuredTaskGroup(result: .results, t1, t2)
```

---

## Опционалы (`.optionals`)

```swift
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultOptionalsType,
    _ values: repeat Task<each T, each Err>
) async -> (repeat Optional<each T>)

@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultOptionalsType,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, each Err>)
) async -> (repeat Optional<each T>)
```

- Обёртка над ожиданием значений:
  - при успехе — возвращается `value`,
  - при ошибке — `nil`.
- Не сохраняет сами ошибки — только “есть значение / нет значения”.

**Пример:**

```swift
let t1 = Task { try await loadUser() }
let t2 = Task { try await loadPosts() }

let (user, posts): (User?, [Post]?) =
    await ezWithUnstructuredTaskGroup(result: .optionals, t1, t2)
```

---

## Отмена

Во всех вариантах используется `withTaskCancellationHandler`:

- если внешняя задача (в которой вызван `ezWithUnstructuredTaskGroup`) отменяется,
- то для всех переданных `Task` вызывается `cancel()`,
- и далее они завершаются по своим правилам (обычно `CancellationError`).

Это даёт “структурное” поведение по отношению к уже созданным неструктурированным задачам:  
ты всё ещё можешь отменять их как единый набор, не теряя контроль над временем жизни.
