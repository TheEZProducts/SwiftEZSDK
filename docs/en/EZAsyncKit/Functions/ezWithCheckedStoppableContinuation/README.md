# ezWithCheckedStoppableContinuation

`ezWithCheckedStoppableContinuation` is a wrapper around `withCheckedThrowingContinuation`
that automatically **resumes with a `CancellationError` when the current task is cancelled**.

It is used to build APIs where you need to "suspend" on a continuation while correctly
handling `Task` cancellation (without leaving the continuation hanging forever).

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
public func ezWithCheckedStoppableContinuation<Result: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ body: (EZSafeContinuation<Result>) -> Void
) async throws -> Result
```

---

## Behavior

- Creates an `EZSafeContinuation<Result>` and passes it to `body`.
- Returns the result via `await` when the continuation is `resume(...)`d.
- If the current task is cancelled, the function automatically resumes with `CancellationError`.
- The `isolation` parameter is forwarded to `withCheckedThrowingContinuation` and `withTaskCancellationHandler`
  (by default uses `#isolation`).

---

## Example

Below is an example of converting a callback API to `async` with proper cancellation:

```swift
func doWork(_ completion: @escaping (Result<Int, Error>) -> Void) {
    // simulate async operation
    Task.detached {
        try? await Task.sleep(nanoseconds: 500_000_000)
        completion(.success(123))
    }
}

func doWorkAsync() async throws -> Int {
    return try await ezWithCheckedStoppableContinuation { continuation in
        doWork { result in
            continuation.resume(with: result)
        }
    }
    // if the outer Task is cancelled — continuation receives CancellationError
    // you can additionally cancel the original operation via a token
}

let task = Task {
    do {
        let value = try await doWorkAsync()
        print(value)
    } catch is CancellationError {
        print("cancelled")
    } catch {
        print("error:", error)
    }
}

try? await Task.sleep(nanoseconds: 300_000_000)
task.cancel()
```

> If your callback API has its own cancel token, you should typically trigger it on task cancellation
> (for example, via `withTaskCancellationHandler` alongside), but this function already guarantees
> basic "stoppability" of the continuation.
