//
//  EZSafeContinuationTest.swift
//  EZSDK
//

import XCTest

import EZAsyncKit

private final class Box<T>: @unchecked Sendable {
    var v: T
    init(_ v: T) { self.v = v }
}

private func blockingSleep(_ seconds: TimeInterval) { Thread.sleep(forTimeInterval: seconds) }
private func blockingWait(_ semaphore: DispatchSemaphore) { semaphore.wait() }
private func blockingWait(_ semaphore: DispatchSemaphore, _ seconds: TimeInterval) -> Bool {
    semaphore.wait(timeout: .now() + seconds) == .success
}

@available(macOS 10.15, iOS 16.0, watchOS 6.0, tvOS 13.0, *)
final class EZSafeContinuationTest: XCTestCase, @unchecked Sendable {

    // MARK: - Lock inversion

    /// A cancellation handler runs while the runtime holds the cancelled task's status-record lock,
    /// and resuming a suspended task's continuation needs that same lock. Resuming the underlying
    /// `CheckedContinuation` while holding `EZSafeContinuation`'s own mutex therefore inverts the
    /// two locks against `onCancel`, which takes them in the opposite order.
    ///
    /// The nesting below is a hand-rolled `ezWithCheckedStoppableContinuation`: the outer
    /// `onCancel` is verbatim the one that function installs, and the inner handler exists only to
    /// pin the interleaving (cancellation handlers run innermost-first, so it runs before the outer
    /// one and holds the cancel in progress while the other thread resumes).
    func test_resumeDoesNotHoldItsMutexAcrossContinuationResume() {
        let safeContinuation = EZSafeContinuation<Int>()
        let continuationInstalled = DispatchSemaphore(value: 0)
        let cancelInProgress = DispatchSemaphore(value: 0)
        let outcome = Box<Result<Int, Error>?>(nil)
        let finished = expectation(description: "awaiting task finished")

        let task = Task.detached {
            do {
                let value: Int = try await withTaskCancellationHandler {
                    try await withTaskCancellationHandler {
                        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                            safeContinuation.set(continuation: continuation)
                            continuationInstalled.signal()
                        }
                    } onCancel: {
                        cancelInProgress.signal()
                        blockingSleep(0.5)
                    }
                } onCancel: {
                    safeContinuation.resume(throwing: CancellationError())
                }
                outcome.v = .success(value)
            } catch {
                outcome.v = .failure(error)
            }
            finished.fulfill()
        }

        blockingWait(continuationInstalled)
        blockingSleep(0.2) // the task is now suspended on the continuation, not merely pending

        let canceller = Thread { task.cancel() }
        canceller.start()
        blockingWait(cancelInProgress)

        let resumeReturned = DispatchSemaphore(value: 0)
        let resumer = Thread {
            safeContinuation.resume(returning: 42)
            resumeReturned.signal()
        }
        resumer.start()

        XCTAssertTrue(blockingWait(resumeReturned, 10), "resume(returning:) never returned — lock inversion")
        wait(for: [finished], timeout: 10)

        switch outcome.v {
        case .success(let value): XCTAssertEqual(value, 42)
        case .failure(let error): XCTFail("expected the resumed value, got \(error)")
        case .none: XCTFail("no outcome")
        }
    }

    /// A second `resume` from the same thread that already resumed must be a no-op and must not
    /// re-enter the non-recursive mutex.
    func test_sequentialDoubleResumeFromAnotherThreadIsANoOp() {
        let safeContinuation = EZSafeContinuation<Int>()
        let reentered = Box(false)
        let finished = expectation(description: "finished")
        let outcome = Box<Int?>(nil)

        Task.detached {
            let value = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                safeContinuation.set(continuation: continuation)
                Thread.detachNewThread {
                    safeContinuation.resume(returning: 1)
                    reentered.v = true
                    safeContinuation.resume(returning: 2) // ignored
                }
            }
            outcome.v = value
            finished.fulfill()
        }

        wait(for: [finished], timeout: 10)
        XCTAssertTrue(reentered.v)
        XCTAssertEqual(outcome.v, 1)
    }

    // MARK: - First resume wins

    func test_firstResumeWinsAndLaterResumesAreIgnored() {
        let safeContinuation = EZSafeContinuation<Int>()
        safeContinuation.resume(returning: 1)
        safeContinuation.resume(returning: 2)
        safeContinuation.resume(throwing: CancellationError())
        XCTAssertEqual(try? safeContinuation.result?.get(), 1)
    }

    /// Two threads resume the same wrapper while a real `CheckedContinuation` is attached.
    /// `CheckedContinuation` traps on a second resumption, so the runtime itself is the oracle for
    /// "resumed exactly once".
    func test_concurrentDoubleResumeResumesTheCheckedContinuationExactlyOnce() async {
        for _ in 0..<100 {
            let safeContinuation = EZSafeContinuation<Int>()
            let outcome = Box<Int?>(nil)
            let finished = expectation(description: "finished")
            let go = DispatchSemaphore(value: 0)
            let done = DispatchSemaphore(value: 0)

            Task.detached {
                let value = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                    safeContinuation.set(continuation: continuation)
                    for resumed in [1, 2] {
                        Thread.detachNewThread {
                            blockingWait(go)
                            safeContinuation.resume(returning: resumed)
                            done.signal()
                        }
                    }
                    go.signal(); go.signal()
                }
                outcome.v = value
                finished.fulfill()
            }

            await fulfillment(of: [finished], timeout: 10)
            XCTAssertTrue(blockingWait(done, 5))
            XCTAssertTrue(blockingWait(done, 5))
            XCTAssertTrue(outcome.v == 1 || outcome.v == 2, "unexpected outcome \(String(describing: outcome.v))")
        }
    }

    // MARK: - set(continuation:)

    func test_setContinuationAfterResultResumesImmediately() async {
        let safeContinuation = EZSafeContinuation<Int>()
        safeContinuation.resume(returning: 7)
        let value = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            safeContinuation.set(continuation: continuation)
        }
        XCTAssertEqual(value, 7)
    }

    func test_setNilContinuationAfterResultIsSafe() {
        let safeContinuation = EZSafeContinuation<Int>()
        safeContinuation.resume(returning: 7)
        safeContinuation.set(continuation: nil)
        XCTAssertEqual(try? safeContinuation.result?.get(), 7)
    }

    /// The second `set` replaces the stored continuation; only the surviving one is resumed.
    /// This is the pre-existing contract of the type — asserted so a future change is deliberate.
    func test_setTwiceKeepsTheLastContinuation() async {
        let safeContinuation = EZSafeContinuation<Int>()
        let value = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            safeContinuation.set(continuation: nil)
            safeContinuation.set(continuation: continuation)
            Thread.detachNewThread { safeContinuation.resume(returning: 5) }
        }
        XCTAssertEqual(value, 5)
    }

    // MARK: - deinit

    func test_deinitBeforeResumeFailsWithWasDeinit() async {
        let caught = Box<Error?>(nil)
        let finished = expectation(description: "wasDeinit delivered")
        Task.detached {
            do {
                _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                    let safeContinuation = EZSafeContinuation<Int>()
                    safeContinuation.set(continuation: continuation)
                    // safeContinuation goes out of scope without ever being resumed
                }
            } catch {
                caught.v = error
            }
            finished.fulfill()
        }
        await fulfillment(of: [finished], timeout: 10)
        XCTAssertEqual(caught.v as? EZContinuationError, .wasDeinit)
    }

    func test_deinitRacingResumeDeliversExactlyOneOutcome() async {
        for _ in 0..<100 {
            let outcome = Box<Result<Int, Error>?>(nil)
            let finished = expectation(description: "finished")
            Task.detached {
                do {
                    let value = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                        let safeContinuation = EZSafeContinuation<Int>()
                        safeContinuation.set(continuation: continuation)
                        Thread.detachNewThread { safeContinuation.resume(returning: 3) }
                    }
                    outcome.v = .success(value)
                } catch {
                    outcome.v = .failure(error)
                }
                finished.fulfill()
            }
            await fulfillment(of: [finished], timeout: 10)
            switch outcome.v {
            case .success(let value): XCTAssertEqual(value, 3)
            case .failure(let error): XCTAssertEqual(error as? EZContinuationError, .wasDeinit)
            case .none: XCTFail("no outcome")
            }
        }
    }

    // MARK: - Cancellation via ezWithCheckedStoppableContinuation

    func test_cancelBeforeBodyRegistersAnything() async {
        let outcome = Box<Error?>(nil)
        let finished = expectation(description: "finished")
        let task = Task.detached {
            blockingSleep(0.05) // let the cancel land first
            do {
                _ = try await ezWithCheckedStoppableContinuation { (_: EZSafeContinuation<Int>) in }
            } catch {
                outcome.v = error
            }
            finished.fulfill()
        }
        task.cancel()
        await fulfillment(of: [finished], timeout: 10)
        XCTAssertTrue(outcome.v is CancellationError, "expected CancellationError, got \(String(describing: outcome.v))")
    }

    func test_cancelAfterResumeKeepsTheResumedValue() async {
        let outcome = Box<Result<Int, Error>?>(nil)
        let finished = expectation(description: "finished")
        let task = Task.detached {
            do {
                let value = try await ezWithCheckedStoppableContinuation { (continuation: EZSafeContinuation<Int>) in
                    continuation.resume(returning: 11)
                }
                outcome.v = .success(value)
            } catch {
                outcome.v = .failure(error)
            }
            finished.fulfill()
        }
        await fulfillment(of: [finished], timeout: 10)
        task.cancel()
        XCTAssertEqual(try? outcome.v?.get(), 11)
    }

    func test_cancelOfAnAlreadyCancelledTaskIsIdempotent() async {
        let outcome = Box<Error?>(nil)
        let started = DispatchSemaphore(value: 0)
        let finished = expectation(description: "finished")
        let task = Task.detached {
            do {
                _ = try await ezWithCheckedStoppableContinuation { (_: EZSafeContinuation<Int>) in
                    started.signal()
                }
            } catch {
                outcome.v = error
            }
            finished.fulfill()
        }
        blockingWait(started)
        blockingSleep(0.1)
        task.cancel()
        task.cancel()
        task.cancel()
        await fulfillment(of: [finished], timeout: 10)
        XCTAssertTrue(outcome.v is CancellationError)
    }

    /// The canonical single-threaded shape: the cancelling thread runs `onCancel`, which resumes the
    /// very continuation the cancelled task is suspended on. Repeated, because a self-block here
    /// would make every cancellation a coin flip.
    func test_cancelWhileSuspendedNeverSelfBlocks() async {
        for _ in 0..<100 {
            let started = DispatchSemaphore(value: 0)
            let finished = expectation(description: "finished")
            let outcome = Box<Error?>(nil)
            let task = Task.detached {
                do {
                    _ = try await ezWithCheckedStoppableContinuation { (_: EZSafeContinuation<Int>) in
                        started.signal()
                    }
                } catch {
                    outcome.v = error
                }
                finished.fulfill()
            }
            blockingWait(started)
            blockingSleep(0.02)
            let cancelReturned = DispatchSemaphore(value: 0)
            Thread.detachNewThread { task.cancel(); cancelReturned.signal() }
            XCTAssertTrue(blockingWait(cancelReturned, 5), "cancel() wedged")
            await fulfillment(of: [finished], timeout: 10)
            XCTAssertTrue(outcome.v is CancellationError)
        }
    }

    // MARK: - Channels built on top

    func test_bufferedChannelCancelWhileSendingDoesNotWedge() async {
        for _ in 0..<50 {
            let channel = EZBufferedChannel<Int>(bufferSize: 1)
            let started = DispatchSemaphore(value: 0)
            let finished = expectation(description: "finished")
            let reader = Task.detached {
                started.signal()
                _ = try? await channel.get()
                finished.fulfill()
            }
            blockingWait(started)
            blockingSleep(0.02)
            Thread.detachNewThread { reader.cancel() }
            Task.detached { try? await channel.set(1) }
            await fulfillment(of: [finished], timeout: 10)
        }
    }
}
