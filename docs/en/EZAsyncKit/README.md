# EZAsyncKit

## **Swift Concurrency** Guide

1. [Guide](AsyncGuide/README.md) - A short guide on safe usage of Swift Concurrency

## Services

1. [EZChannel](Services/EZChannel/EZChannel/README.md) - Unbuffered asynchronous channel
2. [EZBufferedChannel](Services/EZChannel/EZBufferedChannel/README.md) - Buffered asynchronous channel
3. [EZAsyncValue](Services/EZAsyncValue/README.md) - Async container for a result

---

## Extensions

1. [Actor](Extensions/Actor%20%2B%20EZ/README.md) - Utilities for working with actor isolation and conveniently launching tasks with isolated Self
2. [AsyncStream](Extensions/AsyncStream%20%2B%20EZ/README.md) - Helpers for AsyncStream.Continuation: timeouts, auto-finishing, and lifecycle binding
3. [Task](Extensions/Task%20%2B%20EZ/README.md) - Anchors for auto-cancelling tasks and propagating cancellation of the current task into a Task
4. [MainActor](Extensions/MainActor%20%2B%20EZ/README.md) - Unsafe synchronous invocation of @MainActor closures from a nonisolated context


---

## Functions

1. [ezWithCheckedStoppableContinuation](Functions/ezWithCheckedStoppableContinuation/README.md) - Continuation wrapper with auto-resume of CancellationError on task cancellation
2. [ezWithTaskGroup](Functions/ezWithTaskGroup/README.md) - Run multiple EZTaskItem instances in a TaskGroup and return results as a tuple
3. [ezWithTaskGroupFirstCompleted](Functions/ezWithTaskGroupFirstCompleted/README.md) - Race tasks in a TaskGroup, return the first completed result (success or error)
4. [ezWithTaskGroupFirstSuccess](Functions/ezWithTaskGroupFirstSuccess/README.md) - Race tasks in a TaskGroup, return the first successful value, errors are ignored
5. [ezWithUnstructuredTaskGroup](Functions/ezWithUnstructuredTaskGroup/README.md) - Await a set of unstructured Tasks, return results as a tuple with proper cancellation

---

## Helpers

1. [EZContinuations](Helpers/EZContinuations/README.md) - Unified resume(...) + safe continuation wrappers for one-shot scenarios

---

## Wrappers

1. [EZActorWrapper](Wrappers/EZActorWrapper/README.md) - Simple actor container for safe state storage and updates
2. [EZThreadSafety](Wrappers/EZThreadSafety/README.md) - Thread-safe value access with sync+async API (actor isolation + semaphore bridge)
3. [EZSendableWrapper](Wrappers/EZSendableWrapper/README.md) - Semaphored property wrapper for thread-safe value access + @unchecked wrapper
4. [EZWeakWrapper](Helpers/EZWeakWrapper/README.md) - Weak wrapper for AnyObject (Sendable if the object is also Sendable)
