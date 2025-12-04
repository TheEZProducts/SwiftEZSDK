//
//  EZBufferedChannel.swift
//  EZSDK
//
//  Created by Александр Сенин on 03.12.2025.
//

import Foundation

/// A small buffered async channel for passing values between tasks.
///
/// `EZBufferedChannel` is like a rendezvous channel (`EZChannel`), but with an in-memory buffer:
/// - `set(_:)` appends into the buffer while there is capacity.
/// - `get()` drains the buffer first.
/// - When the buffer is full, `set(_:)` suspends until a receiver makes space.
///
/// Call `close()` to unblock all pending senders/receivers with `EZChannelError.closed`.
    
/// A buffered async channel.
///
/// Use `init(bufferSize:)` to choose a capacity (minimum 1).
/// The parameterless `init()` creates an unbuffered (rendezvous-style) channel where `set(_:)` waits
/// until a receiver is waiting.
///
/// ### Example
/// ```swift
/// let ch = EZBufferedChannel<Int>(bufferSize: 2)
///
/// let producer = Task {
///     try await ch.set(1)
///     try await ch.set(2)
///     try await ch.set(3) // may suspend until consumer makes space
///     ch.close()
/// }
///
/// let consumer = Task {
///     do {
///         while true {
///             print(try await ch.get())
///         }
///     } catch {
///         // closed
///     }
/// }
///
/// _ = await (producer.result, consumer.result)
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZBufferedChannel<T: Sendable> {
    /// `true` after `close()` was called.
    public private(set) var isClosed: Bool = false
    
    private var bufferSize: Int { buffer.capacity }
    private var buffer: [T] = []
    
    /// Creates a buffered channel with the specified capacity.
    ///
    /// `bufferSize` is clamped to a minimum of `1`.
    ///
    /// ### Example
    /// ```swift
    /// let ch = EZBufferedChannel<String>(bufferSize: 10)
    /// ```
    public init(bufferSize: Int) {
        buffer = .init(unsafeUninitializedCapacity: max(1, bufferSize), initializingWith: {_,_ in})
    }
    
    private var continuations = (
        setContinuations: [(value: T, continuation: EZSafeContinuation<Void>)](),
        getContinuations: [EZSafeContinuation<T>]()
    )
    
    /// Receives the next value from the channel.
    ///
    /// Drains the buffer first; if it's empty, suspends until a sender provides a value.
    /// Throws `EZChannelError.closed` if the channel is closed.
    ///
    /// ### Example
    /// ```swift
    /// let ch = EZBufferedChannel<Int>(bufferSize: 1)
    /// Task { try await ch.set(123) }
    /// let v = try await ch.get() // 123
    /// ```
    public func get() async throws -> T {
        try checkIsClosed()
        if let value = buffer.ezSafeRemoveFirst() {
            setNextValue()
            return value
        } else {
            return try await ezWithCheckedStoppableContinuation { getContinuation in
                continuations.getContinuations.append(getContinuation)
            }
        }
    }
    
    /// Sends a value into the channel.
    ///
    /// If a receiver is already waiting, resumes it immediately.
    /// Otherwise, appends into the buffer if there is capacity.
    /// If the buffer is full, suspends until space becomes available.
    /// Throws `EZChannelError.closed` if the channel is closed.
    ///
    /// ### Example
    /// ```swift
    /// let ch = EZBufferedChannel<Int>(bufferSize: 1)
    /// try await ch.set(1) // buffered
    /// // A second send may suspend until someone calls `get()`.
    /// ```
    public func set(_ value: T) async throws {
        try checkIsClosed()
        if let getContinuation = continuations.getContinuations.ezSafeRemoveFirst() {
            getContinuation.resume(returning: value)
        } else if buffer.count < bufferSize {
            buffer.append(value)
        } else {
            try await ezWithCheckedStoppableContinuation { continuation in
                continuations.setContinuations.append((value, continuation))
            }
        }
    }
    
    /// Closes the channel and resumes all pending senders/receivers with `EZChannelError.closed`.
    ///
    /// Calling `close()` multiple times is safe.
    ///
    /// ### Example
    /// ```swift
    /// let ch = EZBufferedChannel<Int>(bufferSize: 1)
    /// let t = Task { try await ch.get() }
    /// ch.close()
    /// do { _ = try await t.value } catch { /* closed */ }
    /// ```
    public func close() {
        isClosed = true
        continuations.getContinuations.forEach { $0.resume(throwing: EZChannelError.closed) }
        continuations.setContinuations.forEach { $0.continuation.resume(throwing: EZChannelError.closed) }
    }
    
    private func setNextValue() {
        guard
            buffer.count < bufferSize,
            let (value, continuation) = continuations.setContinuations.ezSafeRemoveFirst()
        else { return }
        buffer.append(value)
        continuation.resume()
    }
        
    /// Throws `EZChannelError.closed` if the channel is already closed.
    public func checkIsClosed() throws {
        guard !isClosed else { throw EZChannelError.closed }
    }
}
