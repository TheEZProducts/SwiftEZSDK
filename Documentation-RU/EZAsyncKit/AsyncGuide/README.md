# AsyncGuide

## Вступление

Это небольшое руководство по безопасному использованию **Swift Concurrency** — набор лучших практик и типовых «подводных камней», с которыми легко столкнуться в реальном коде.

Цели гайда:
- Показать неочевидные проблемы, которые выглядят «логично», но ведут к утечкам, зависаниям или гонкам.
- Дать понятные правила и паттерны, которые можно применять сразу.

---

## Содержание

- [Подводные камни Swift Concurrency](#подводные-камни-swift-concurrency)
  - [Удержание сильной ссылки в async-методе](#удержание-сильной-ссылки-в-async-методе)
  - [Task.cancel() не отменяет задачу, а помечает её как отменённую](#taskcancel-не-отменяет-задачу-а-помечает-её-как-отменённую)
  - [Блокировка потока вечной или долгой задачей](#блокировка-потока-вечной-или-долгой-задачей)
  - [withCheckedContinuation не завершается при Task.cancel()](#withcheckedcontinuation-не-завершается-при-taskcancel)
  - [Реэнтерабельность actor’ов: состояние может измениться «между await»](#реэнтерабельность-actorов-состояние-может-измениться-между-await)
  - [Потеря изоляции](#потеря-изоляции)
- [Полезные ссылки](#полезные-ссылки)

---

## Подводные камни Swift Concurrency

Ниже — набор кейсов, которые чаще всего «стреляют» в проде.

Формат у разделов одинаковый:
- **Что происходит** — симптом.
- **Почему** — краткое объяснение механики.
- **Как делать правильно** — практический паттерн.

### Удержание сильной ссылки в async-методе

**Что происходит:**
когда вызываешь `async`-метод у объекта, важно понимать: внутри этого `async`-выполнения `self` удерживается сильной ссылкой до завершения метода. Если метод «вечный» (или очень долгий), объект может не деинициализироваться, даже если снаружи ты обнулил ссылку.

**Почему:**
даже если ты захватил `self` с `[weak self]` в `Task`, при входе в `async`-метод объект становится нужен для выполнения метода, и runtime удерживает его на время выполнения. Если внутри есть `await`, удержание сохраняется между точками приостановки.

Проблема выглядит так:

```swift
public final class Worker: Sendable {
    public func start() {
        Task.detached {[weak self] in
            try await self?._doWork()
        }
    }
    
    private func _doWork() async throws {
        while true {
            print("Worker is working")
            try await Task.sleep(for: .seconds(1))
        }
    }
}

var worker: Worker? = .init()
worker?.start()
//Каждую секунду print("Worker is working")
worker = nil
//Worker - остается жив, продолжает каждую секунду print("Worker is working")
```

**Как делать правильно:**
- Привязывай жизненный цикл «вечных» задач к жизненному циклу объекта.
- Явно поддерживай остановку по cancel (либо через `Task.checkCancellation()`, либо через операции, которые сами выбрасывают `CancellationError`, например `Task.sleep`).

В качестве решения можно использовать такой подход:

```swift
import EZAsyncKit
import EZHelpersKit

public final class SafeWorker: Sendable {
    let workAnchor = EZMutex<EZDeinitAnchor?>(nil)

    public func start() {
        // Вариант 1: храним якорь; при его деинициализации задача будет отменена (isCancelled == true)
        workAnchor.withLock {
            $0.value = Task.detached { [weak self] in
                try await Self._doWork(self: .init(value: self))
            }.ezMakeAnchor()
        }

        // Вариант 2 (только платформы с ObjC): привязываем якорь к объекту.
        // Task.detached { [weak self] in
        //     try await Self._doWork(self: .init(value: self))
        // }.ezSnapToObject(self)
    }

    private static func _doWork(self: EZWeakWrapper<SafeWorker>) async throws {
        while true {
            if let self = self.value {
                print("\(self) is working")
            }
            try await Task.sleep(for: .seconds(1))
        }
    }
}

var worker: SafeWorker? = .init()
worker?.start()
// Каждую секунду печатает "… is working"
worker = nil
// SafeWorker освобождается, таск помечается как isCancelled,
// и `try await Task.sleep(...)` выбрасывает CancellationError
```

---

### Task.cancel() не отменяет задачу, а помечает её как отменённую

**Что происходит:**
вызов `Task.cancel()` не останавливает задачу сам по себе — он лишь помечает её как отменённую (и запускает cancellation handlers, если они есть). Если алгоритм не проверяет отмену, код продолжит выполняться.

**Почему:**
отмена в Swift Concurrency кооперативная: «остановка» — ответственность выполняемого кода.

Пример проблемы:

```swift
final class Worker: Sendable {
    private let task: Task<Void, Never>
    
    init() {
        task = Task.detached {
            while true {
                print("Hello world!")
            }
        }
    }
    
    func stop() {
        task.cancel()
    }
}

let worker = Worker()
// постоянно принтит "Hello world!"
worker.stop()
// продолжает принтить "Hello world!"
```

**Как делать правильно:**
- Регулярно проверяй отмену (`Task.isCancelled` / `Task.checkCancellation()`), особенно в циклах.
- Используй отменяемые suspending-операции там, где это уместно (например, `Task.sleep` выбрасывает `CancellationError`).

Правильный подход:

```swift
final class Worker: Sendable {
    private let task: Task<Void, Error>

    init() {
        task = Task.detached {
            while true {
                try Task.checkCancellation() // Выбросит CancellationError, если задачу отменили
                print("Hello world!")
            }
        }
    }

    func stop() {
        task.cancel()
    }
}

let worker = Worker()
// постоянно принтит "Hello world!"
worker.stop()
// больше не принтит
```

---

### Блокировка потока вечной или долгой задачей

**Что происходит:**
если создать задачу с очень тяжёлым, вечным или блокирующим действием, можно заблокировать поток (в том числе главный), на котором запустилась задача.

**Почему:**
Swift Concurrency не «магически» делает код неблокирующим: если ты используешь блокирующие вызовы (`sleep`, синхронные ожидания, тяжёлые CPU-циклы) на `@MainActor` — ты блокируешь UI и всё, что должно выполняться на этом же потоке.

Пример проблемы:

```swift
@MainActor
final class Worker: Sendable {
    private let task: Task<Void, Error>

    init() {
        task = Task {
            while true {
                try Task.checkCancellation()
                print("Hello world!")
                sleep(1) // ⚠️ блокирует поток (на @MainActor — блокирует UI)
            }
        }
    }

    func stop() {
        task.cancel()
    }
}

@MainActor
func mainActorFunction() async {
    let worker = Worker()
    // постоянно принтит "Hello world!"
    try? await Task.sleep(for: .seconds(1))

    worker.stop()
    // Задача завершилась
}
```

**Как делать правильно:**
- Не блокируй `@MainActor`: используй неблокирующие ожидания (`Task.sleep`) или выноси тяжёлую работу с MainActor.
- В бесконечных циклах регулярно делай yield, чтобы давать рантайму шанс выполнять другие задачи.

Правильный подход:

```swift
@MainActor
final class Worker: Sendable {
    private let task: Task<Void, Error>

    init() {
        task = Task {
            while true {
                try Task.checkCancellation()
                print("Hello world!")
                try await Task.sleep(for: .seconds(1))
                // `Task.sleep` не блокирует поток и автоматически реагирует на cancel.
            }
        }
    }

    func stop() {
        task.cancel()
    }
}

@MainActor
func mainActorFunction() async {
    let worker = Worker()
    // постоянно принтит "Hello world!"
    try? await Task.sleep(for: .seconds(1))

    worker.stop()
    // Задача завершилась
}
```

---

### withCheckedContinuation не завершается при Task.cancel()

**Что происходит:**
обычные `withCheckedContinuation` / `withCheckedThrowingContinuation` сами по себе не «просыпаются» от `Task.cancel()`. Если внешний колбэк никогда не вызовет `resume`, задача может остаться suspended, несмотря на cancel.

**Почему:**
continuation — это мост к callback-миру. Отмена `Task` не отменяет внешнюю операцию автоматически. Нужно явно связать cancel с тем, что «разбудит» continuation (или отменит внешнюю операцию).

Пример проблемы:

```swift
final class Worker: Sendable {
    func wait() async {
        await withCheckedContinuation { cont in
            // Имитируем внешний колбек, который должен резюмнуть continuation позже
            DispatchQueue.global().asyncAfter(deadline: .now() + 60) {
                cont.resume()
            }
        }
        print("Done")
    }
}

func demo() async {
    let worker = Worker()

    let task = Task.detached {
        await worker.wait()
        print("Task finished")
    }

    try? await Task.sleep(for: .seconds(1))
    task.cancel()

    // Пытаемся дождаться завершения задачи после cancel
    await task.value
    print("Await finished")
    // Несмотря на cancel, задача может зависнуть в suspended,
    // пока continuation не будет resume (в примере ~60 секунд).
}
```

**Как делать правильно:**
- При бриджинге колбэков продумывай отмену: либо отменяй внешнюю операцию, либо резюмь continuation отменой.
- Избегай ситуаций, где continuation может «потеряться» и никогда не будет resumed.

В качестве решения можно использовать такой подход:

```swift
import EZAsyncKit

final class Worker: Sendable {
    func wait() async {
        try? await ezWithCheckedStoppableContinuation { cont in // Выбросит ошибку, если таск был отменен
            // Имитируем внешний колбек, который должен резюмнуть continuation позже
            DispatchQueue.global().asyncAfter(deadline: .now() + 60) {
                cont.resume()
            }
        }
        print("Done")
    }
}

func demo() async {
    let worker = Worker()

    let task = Task.detached {
        await worker.wait()
        print("Task finished")
    }

    try? await Task.sleep(for: .seconds(1))
    task.cancel()

    // Пытаемся дождаться завершения задачи после cancel
    await task.value // Результат будет доступен сразу
    print("Await finished")
}
```

ezWithCheckedStoppableContinuation — так же защищён от двойного вызова `resume`,
и от потери ссылки на continuation: в случае утраты будет отброшена ошибка деинициализации.

---

### Реэнтерабельность actor’ов: состояние может измениться «между await»

**Что происходит:**
в асинхронных методах actor’ов на каждом `await` актор «отпускает» выполнение, и пока текущий метод ждёт, актор может обработать другие сообщения. В итоге состояние может измениться «между await».

**Почему:**
actor обеспечивает изоляцию от data race, но допускает interleaving при приостановке (reentrancy). Поэтому нельзя переносить предположения о состоянии через `await`, если это состояние может поменяться.

Пример проблемы:

```swift
actor Cache {
    private var dict: [URL: Data] = [:]

    func get(_ url: URL) async throws -> Data {
        if let v = dict[url] { return v }
        // Если два вызова `get` придут одновременно, оба могут пройти мимо dict
        // и запустить `download(url)` параллельно (а затем перезаписать значение).
        let data = try await download(url)   // <-- пока ждём, dict мог измениться
        dict[url] = data
        return data
    }
    
    private func download(_ url: URL) async throws -> Data {
        try await Task.sleep(for: .seconds(0.1))
        return Data()
    }
}
```

**Как делать правильно:**
- Для долгих операций выноси работу наружу и храни в actor’е «промис»/идентификатор операции, чтобы все конкурирующие запросы ждали один и тот же результат.
- Для коротких операций можно сериализовать критическую секцию (но важно не превращать actor в «очередь, которая всё ждёт» без нужды).

В качестве решения для долгих задач можно использовать такой подход:

```swift
import EZAsyncKit

actor Cache {
    private var dict: [URL: EZAsyncValue<Data>] = [:] // Меняем Data на promise-like EZAsyncValue

    func get(_ url: URL) throws -> EZAsyncValue<Data> { // Убираем асинхронность
        if let v = dict[url] { return v }
        let data = try download(url)
        dict[url] = data
        return data
    }
    
    private func download(_ url: URL) throws -> EZAsyncValue<Data> {
        let (promise, continuation) = EZAsyncValue<Data>.makeValue()
        Task {
            try await Task.sleep(for: .seconds(10))
            continuation.resume(returning: Data())
        }
        return promise
    }
}
```

В качестве решения для быстрых задач можно использовать такой подход:

```swift
import EZAsyncKit

//РЕКОМЕНДУЕТСЯ ТОЛЬКО, ЕСЛИ УВЕРЕН, ЧТО ЗАДАЧА ВЫПОЛНИТСЯ ОЧЕНЬ БЫСТРО
actor Cache {
    private let semaphore = EZAsyncSemaphore(value: 1) // Асинхронный семафор, пока не будет отпущен прошлый вызов, другие не смогут пройти
    private var dict: [URL: Data] = [:]

    func get(_ url: URL) async throws -> Data {
        try await semaphore.wait(); defer { Task { await semaphore.signal() } }
        if let v = dict[url] { return v }
        let data = try await download(url)
        dict[url] = data
        return data
    }
    
    private func download(_ url: URL) async throws -> Data {
        try await Task.sleep(for: .seconds(0.1))
        return Data()
    }
}
```

---

### Потеря изоляции

**Что происходит:**
вызов синхронной функции, которая не помечена изоляцией, даже из изолированного контекста (например, `@MainActor`), не гарантирует сохранение изоляции внутри новых задач.

**Почему:**
- Синхронная функция выполнится там, откуда её вызвали.
- Но если внутри синхронной функции ты создаёшь задачу без привязки к текущей изоляции (или используешь `Task.detached`), она может выполняться уже в другом контексте.
- У `async`-функций, напротив, возврат в изоляцию происходит по правилам их декларации, а не по месту вызова.

Пример проблемы:

```swift
// 1) Синхронная функция без изоляции.
// Если вызвать из MainActor, то сама функция выполнится на MainActor,
// но внутри Task.detached уже нет никакой изоляции.
func syncHelperNoIsolation() {
    print("syncHelperNoIsolation on main:", Thread.isMainThread) // true (если вызвали с MainActor)

    Task {
        print("detached task on main:", Thread.isMainThread) // false
        // Detached-задачи НЕ наследуют actor context.
        // Если отсюда тронуть UI/состояние MainActor — будет проблема.
    }
}

@MainActor
func case1_calledFromMainActor() {
    print("case1_calledFromMainActor on main:", Thread.isMainThread) // case1_calledFromMainActor on main: true
    syncHelperNoIsolation()
}

// 2) Async helper с явной изоляцией в сигнатуре.
@MainActor
func mainActorAsync() async {
    print("inside mainActorAsync on main:", Thread.isMainThread) // true
    try? await Task.sleep(for: .milliseconds(10))
}

@MainActor
func case2_asyncFromMainActor() async {
    print("before await on main:", Thread.isMainThread) // true
    await mainActorAsync()
    print("after await on main:", Thread.isMainThread) // true
}
```

**Как делать правильно:**
- Явно прокидывай изоляцию, если внутри helper-а создаёшь новые задачи и ожидаешь сохранение контекста.
- Для таких утилит удобно принимать `isolated (any Actor)? = #isolation` и запускать работу в переданной изоляции.

В качестве решения можно использовать такой подход:

```swift
import EZAsyncKit

// 1) Синхронная функция, наследующая переданную изоляцию.
func syncHelperNoIsolation(isolation: isolated (any Actor)? = #isolation) {
    print("syncHelperNoIsolation on main:", Thread.isMainThread) // syncHelperNoIsolation on main: true

    isolation?.ezTask { _ in // запускает таск в изоляции эктора
        print("task in isolation on main:", Thread.isMainThread) // task in isolation on main: true
    }
}

@MainActor
func case1_calledFromMainActor() {
    print("case1_calledFromMainActor on main:", Thread.isMainThread) // case1_calledFromMainActor on main: true
    syncHelperNoIsolation()
}

// 2) Вызов async функции с переданной изоляцией.
func unisolatedAsync(isolation: isolated (any Actor)? = #isolation) async {
    print("inside unisolatedAsync on main:", Thread.isMainThread) // inside unisolatedAsync on main: true
    try? await Task.sleep(for: .milliseconds(10))
}

@MainActor
func case2_asyncFromMainActor() async {
    print("before await on main:", Thread.isMainThread) // before await on main: true
    await unisolatedAsync()
    print("after await on main:", Thread.isMainThread) // after await on main: true
}
```

