# EZAsyncSemaphore

`EZAsyncSemaphore` — небольшой асинхронный семафор для координации конкурентных задач.

Поведение похоже на классический счётный семафор:

- `wait()` уменьшает число разрешений; если оно становится отрицательным — вызывающая задача приостанавливается, пока не появится новое разрешение.
- `signal()` увеличивает число разрешений и возобновляет одну ожидающую задачу (если такая есть).

Отмена: `wait()` использует проверку отмены `Task.checkCancellation()` и стопаемую continuation, поэтому  
если задача будет отменена во время ожидания, она получит `CancellationError`, а внутренний счётчик разрешений будет скорректирован обратно.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZAsyncSemaphore {
    public init(value: Int = 1)

    public func wait() async throws
    public func signal()
}
```

---

## Поведение

- `init(value:)`:
  - создаёт семафор с заданным начальными количеством разрешений;
  - отрицательные значения приводятся к нулю (`max(0, value)`).

- `wait()`:
  - вызывает `Task.checkCancellation()` перед блокировкой;
  - уменьшает `permits`;
  - если `permits >= 0` — возвращает сразу (разрешение было доступно);
  - если `permits < 0` — приостанавливает задачу до тех пор, пока другая задача не вызовет `signal()`;
  - если задача будет отменена во время ожидания, выбрасывает `CancellationError`, а `permits` откатывается обратно (чтобы не терять разрешение).

- `signal()`:
  - увеличивает `permits`;
  - если есть ожидающие задачи, возобновляет первую из тех, у кого ещё нет результата (`result == nil`);
  - если ожидающих нет — разрешение “накапливается” и будет использовано следующим `wait()`.

---

## Примеры использования

### Ограничение параллелизма (до N одновременных задач)

```swift
let semaphore = EZAsyncSemaphore(value: 2)

await withTaskGroup(of: Void.self) { group in
    for i in 0..<5 {
        group.addTask {
            try await semaphore.wait()
            defer { Task { await semaphore.signal() } }

            // критическая секция (не более 2 задач одновременно)
            print("Task", i, "entered")
            try? await Task.sleep(nanoseconds: 300_000_000)
            print("Task", i, "leaving")
        }
    }
}
```

### Защита критической секции

```swift
let semaphore = EZAsyncSemaphore(value: 1) // бинарный семафор

func doWork(id: Int) async {
    try? await semaphore.wait()
    defer { Task { await semaphore.signal() } }

    // код, который должен выполняться только одной задачей за раз
    print("Work from", id)
}
```

---
