# AsyncGuide

## Introduction

This is a short guide on safe usage of **Swift Concurrency** -- a collection of best practices and common pitfalls that are easy to encounter in real-world code.

Goals of the guide:
- Highlight non-obvious problems that look "logical" but lead to leaks, deadlocks, or races.
- Provide clear rules and patterns that can be applied immediately.

---

## Table of Contents

- [Swift Concurrency Pitfalls](#swift-concurrency-pitfalls)
  - [Strong reference retention in an async method](#strong-reference-retention-in-an-async-method)
  - [Task.cancel() does not cancel the task -- it marks it as cancelled](#taskcancel-does-not-cancel-the-task----it-marks-it-as-cancelled)
  - [Blocking a thread with an infinite or long-running task](#blocking-a-thread-with-an-infinite-or-long-running-task)
  - [withCheckedContinuation does not complete on Task.cancel()](#withcheckedcontinuation-does-not-complete-on-taskcancel)
  - [Actor reentrancy: state can change "between awaits"](#actor-reentrancy-state-can-change-between-awaits)
  - [Loss of isolation](#loss-of-isolation)
- [Useful links](#useful-links)

---

## Swift Concurrency Pitfalls

Below is a set of cases that most frequently cause issues in production.

Each section follows the same format:
- **What happens** -- the symptom.
- **Why** -- a brief explanation of the underlying mechanics.
- **How to do it correctly** -- a practical pattern.

### Strong reference retention in an async method

**What happens:**
when you call an `async` method on an object, it is important to understand that within the `async` execution, `self` is retained by a strong reference until the method completes. If the method is "infinite" (or very long-running), the object may never be deinitialized, even if you set the reference to nil externally.

**Why:**
even if you captured `self` with `[weak self]` in a `Task`, upon entering an `async` method the object is needed for method execution, and the runtime retains it for the duration. If there is an `await` inside, the retention persists across suspension points.

The problem looks like this:

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
// Every second prints "Worker is working"
worker = nil
// Worker stays alive, keeps printing "Worker is working" every second
```

**How to do it correctly:**
- Tie the lifetime of "infinite" tasks to the lifetime of the object.
- Explicitly support stopping on cancel (either via `Task.checkCancellation()`, or through operations that throw `CancellationError` on their own, such as `Task.sleep`).

One possible solution is the following approach:

```swift
import EZAsyncKit
import EZHelpersKit

public final class SafeWorker: Sendable {
    let workAnchor = EZMutex<EZDeinitAnchor?>(nil)

    public func start() {
        // Option 1: store the anchor; when it is deinitialized the task will be cancelled (isCancelled == true)
        workAnchor.withLock {
            $0.value = Task.detached { [weak self] in
                try await Self._doWork(self: .init(value: self))
            }.ezMakeAnchor()
        }

        // Option 2 (ObjC platforms only): bind the anchor to the object.
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
// Every second prints "… is working"
worker = nil
// SafeWorker is released, task is marked isCancelled,
// and `try await Task.sleep(...)` throws CancellationError
```

---

### Task.cancel() does not cancel the task -- it marks it as cancelled

**What happens:**
calling `Task.cancel()` does not stop the task by itself -- it only marks it as cancelled (and triggers cancellation handlers, if any). If the algorithm does not check for cancellation, the code will continue executing.

**Why:**
cancellation in Swift Concurrency is cooperative: "stopping" is the responsibility of the executing code.

Example of the problem:

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
// keeps printing "Hello world!"
worker.stop()
// continues to print "Hello world!"
```

**How to do it correctly:**
- Regularly check for cancellation (`Task.isCancelled` / `Task.checkCancellation()`), especially in loops.
- Use cancellable suspending operations where appropriate (for example, `Task.sleep` throws `CancellationError`).

Correct approach:

```swift
final class Worker: Sendable {
    private let task: Task<Void, Error>

    init() {
        task = Task.detached {
            while true {
                try Task.checkCancellation() // Throws CancellationError if the task was cancelled
                print("Hello world!")
            }
        }
    }

    func stop() {
        task.cancel()
    }
}

let worker = Worker()
// keeps printing "Hello world!"
worker.stop()
// no longer prints
```

---

### Blocking a thread with an infinite or long-running task

**What happens:**
if you create a task with a very heavy, infinite, or blocking operation, you can block the thread (including the main thread) on which the task was started.

**Why:**
Swift Concurrency does not "magically" make code non-blocking: if you use blocking calls (`sleep`, synchronous waits, heavy CPU loops) on `@MainActor`, you block the UI and everything else that should execute on that same thread.

Example of the problem:

```swift
@MainActor
final class Worker: Sendable {
    private let task: Task<Void, Error>

    init() {
        task = Task {
            while true {
                try Task.checkCancellation()
                print("Hello world!")
                sleep(1) // ⚠️ blocks the thread (on @MainActor — blocks UI)
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
    // keeps printing "Hello world!"
    try? await Task.sleep(for: .seconds(1))

    worker.stop()
    // Task has finished
}
```

**How to do it correctly:**
- Do not block `@MainActor`: use non-blocking waits (`Task.sleep`) or move heavy work off the MainActor.
- In infinite loops, yield regularly to give the runtime a chance to execute other tasks.

Correct approach:

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
                // `Task.sleep` does not block the thread and automatically reacts to cancel.
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
    // keeps printing "Hello world!"
    try? await Task.sleep(for: .seconds(1))

    worker.stop()
    // Task has finished
}
```

---

### withCheckedContinuation does not complete on Task.cancel()

**What happens:**
standard `withCheckedContinuation` / `withCheckedThrowingContinuation` do not "wake up" on their own when `Task.cancel()` is called. If the external callback never calls `resume`, the task may remain suspended despite cancellation.

**Why:**
a continuation is a bridge to the callback world. Cancelling a `Task` does not automatically cancel the external operation. You need to explicitly tie cancel to whatever "wakes up" the continuation (or cancels the external operation).

Example of the problem:

```swift
final class Worker: Sendable {
    func wait() async {
        await withCheckedContinuation { cont in
            // Simulate an external callback that will resume the continuation later
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

    // Try to wait for task completion after cancel
    await task.value
    print("Await finished")
    // Despite cancel, the task may remain suspended
    // until the continuation is resumed (in this example ~60 seconds).
}
```

**How to do it correctly:**
- When bridging callbacks, plan for cancellation: either cancel the external operation, or resume the continuation with a cancellation error.
- Avoid situations where a continuation can get "lost" and never be resumed.

One possible solution is the following approach:

```swift
import EZAsyncKit

final class Worker: Sendable {
    func wait() async {
        try? await ezWithCheckedStoppableContinuation { cont in // Throws if the task was cancelled
            // Simulate an external callback that will resume the continuation later
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

    // Try to wait for task completion after cancel
    await task.value // Result will be available immediately
    print("Await finished")
}
```

ezWithCheckedStoppableContinuation is also protected against double `resume` calls,
and against losing the reference to the continuation: in case of loss, a deinitialization error will be thrown.

---

### Actor reentrancy: state can change "between awaits"

**What happens:**
in async methods of actors, at every `await` the actor "releases" execution, and while the current method is waiting, the actor can process other messages. As a result, state can change "between awaits".

**Why:**
an actor ensures isolation from data races, but allows interleaving upon suspension (reentrancy). Therefore, you cannot carry assumptions about state across an `await` if that state can change.

Example of the problem:

```swift
actor Cache {
    private var dict: [URL: Data] = [:]

    func get(_ url: URL) async throws -> Data {
        if let v = dict[url] { return v }
        // If two `get` calls arrive at once, both can get past dict
        // and run `download(url)` in parallel (then overwrite the value).
        let data = try await download(url)   // <-- while we wait, dict may have changed
        dict[url] = data
        return data
    }

    private func download(_ url: URL) async throws -> Data {
        try await Task.sleep(for: .seconds(0.1))
        return Data()
    }
}
```

**How to do it correctly:**
- For long-running operations, move the work outside and store a "promise"/operation identifier in the actor, so all competing requests wait for the same result.
- For short operations, you can serialize the critical section (but be careful not to turn the actor into a "queue that waits for everything" unnecessarily).

For long-running tasks, one possible solution is the following approach:

```swift
import EZAsyncKit

actor Cache {
    private var dict: [URL: EZAsyncValue<Data>] = [:] // Change Data to promise-like EZAsyncValue

    func get(_ url: URL) throws -> EZAsyncValue<Data> { // Remove async
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

For fast tasks, one possible solution is the following approach:

```swift
import EZAsyncKit

// RECOMMENDED ONLY IF YOU ARE SURE THE TASK WILL COMPLETE VERY QUICKLY
actor Cache {
    private let semaphore = EZAsyncSemaphore(value: 1) // Async semaphore: until the previous call is released, others cannot proceed
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

### Loss of isolation

**What happens:**
calling a synchronous function that is not marked with any isolation, even from an isolated context (e.g. `@MainActor`), does not guarantee that isolation is preserved inside new tasks.

**Why:**
- A synchronous function executes where it was called from.
- But if inside a synchronous function you create a task without binding to the current isolation (or use `Task.detached`), it may execute in a different context.
- For `async` functions, on the other hand, returning to isolation follows the rules of their declaration, not the call site.

Example of the problem:

```swift
// 1) Synchronous function without isolation.
// If called from MainActor, the function itself runs on MainActor,
// but inside Task.detached there is no isolation.
func syncHelperNoIsolation() {
    print("syncHelperNoIsolation on main:", Thread.isMainThread) // true (if called from MainActor)

    Task {
        print("detached task on main:", Thread.isMainThread) // false
        // Detached tasks do NOT inherit actor context.
        // Touching UI/MainActor state from here would be a problem.
    }
}

@MainActor
func case1_calledFromMainActor() {
    print("case1_calledFromMainActor on main:", Thread.isMainThread) // case1_calledFromMainActor on main: true
    syncHelperNoIsolation()
}

// 2) Async helper with explicit isolation in the signature.
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

**How to do it correctly:**
- Explicitly propagate isolation if you create new tasks inside a helper and expect the context to be preserved.
- For such utilities, it is convenient to accept `isolated (any Actor)? = #isolation` and run the work in the passed isolation.

One possible solution is the following approach:

```swift
import EZAsyncKit

// 1) Synchronous function inheriting the passed isolation.
func syncHelperNoIsolation(isolation: isolated (any Actor)? = #isolation) {
    print("syncHelperNoIsolation on main:", Thread.isMainThread) // syncHelperNoIsolation on main: true

    isolation?.ezTask { _ in // runs the task in the actor's isolation
        print("task in isolation on main:", Thread.isMainThread) // task in isolation on main: true
    }
}

@MainActor
func case1_calledFromMainActor() {
    print("case1_calledFromMainActor on main:", Thread.isMainThread) // case1_calledFromMainActor on main: true
    syncHelperNoIsolation()
}

// 2) Call async function with the passed isolation.
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

