//
//  EZChannel.swift
//  EZSDK
//
//  Created by Александр Сенин on 05.05.2025.
//

import Foundation

/// A tiny async channel for passing values between tasks.
///
/// `EZChannel` lets one task `set(_:)` a value while another task `get()`s it.
/// If no value is available, `get()` suspends; if no receiver is waiting, `set(_:)` suspends.
///
/// The channel can be `close()`d to unblock all waiters with `EZChannelError.closed`.
/// 
/// Errors produced by `EZChannel`.
public enum EZChannelError: String, LocalizedError, Sendable {
    case closed = "Channel is closed"
    
    public var errorDescription: String? {
        "EZChannel.ChannelError: \(rawValue)"
    }
}

/// A rendezvous-style async channel.
///
/// - `get()` waits for a value.
/// - `set(_:)` waits for a receiver.
/// - `close()` fails all current and future waiters.
///
/// ### Example
/// ```swift
/// let ch = EZChannel<Int>()
///
/// let producer = Task {
///     try await ch.set(1)
///     try await ch.set(2)
///     ch.close()
/// }
///
/// let consumer = Task {
///     do {
///         while true {
///             let v = try await ch.get()
///             print(v)
///         }
///     } catch is EZChannelError {
///         // closed
///     }
/// }
///
/// _ = await (producer.result, consumer.result)
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZChannel<T: Sendable> {
    /// `true` after `close()` was called.
    public private(set) var isClosed: Bool = false
    
    private var continuations = (
        setContinuations: [EZSafeContinuation<EZSafeContinuation<T>>](),
        getContinuations: [EZSafeContinuation<T>]()
    )
    
    /// Receives the next value from the channel.
    ///
    /// Suspends if no sender is currently waiting.
    /// Throws `EZChannelError.closed` if the channel is closed.
    ///
    /// ### Example
    /// ```swift
    /// let ch = EZChannel<String>()
    /// Task { try await ch.set("hi") }
    /// let s = try await ch.get() // "hi"
    /// ```
    public func get() async throws -> T {
        try checkIsClosed()
        return try await ezWithCheckedStoppableContinuation { getContinuation in
            if let continuation = continuations.setContinuations.ezSafeRemoveFirst() {
                continuation.resume(returning: getContinuation)
            }else{
                continuations.getContinuations.append(getContinuation)
            }
        }
    }
    
    /// Sends a value into the channel.
    ///
    /// Suspends if no receiver is currently waiting.
    /// Throws `EZChannelError.closed` if the channel is closed.
    ///
    /// ### Example
    /// ```swift
    /// let ch = EZChannel<Int>()
    /// Task { print(try await ch.get()) }
    /// try await ch.set(123)
    /// ```
    public func set(_ value: T) async throws {
        try checkIsClosed()
        try await ezWithCheckedStoppableContinuation { continuation in
            if let getContinuation = continuations.getContinuations.ezSafeRemoveFirst() {
                continuation.resume(returning: getContinuation)
            } else {
                continuations.setContinuations.append(continuation)
            }
        }.resume(returning: value)
    }
    
    /// Closes the channel and resumes all pending senders/receivers with `EZChannelError.closed`.
    ///
    /// Calling `close()` multiple times is safe.
    ///
    /// ### Example
    /// ```swift
    /// let ch = EZChannel<Int>()
    /// let t = Task { try await ch.get() }
    /// ch.close()
    /// do { _ = try await t.value } catch { /* closed */ }
    /// ```
    public func close() {
        isClosed = true
        continuations.getContinuations.forEach { $0.resume(throwing: EZChannelError.closed) }
        continuations.setContinuations.forEach { $0.resume(throwing: EZChannelError.closed) }
    }
    
    /// Throws `EZChannelError.closed` if the channel is already closed.
    ///
    /// You typically don't need to call this directly—it's used internally by `get()`/`set(_:)`.
    public func checkIsClosed() throws {
        guard !isClosed else { throw EZChannelError.closed }
    }
    
    /// Creates an open channel.
    ///
    /// ### Example
    /// ```swift
    /// let ch = EZChannel<Data>()
    /// ```
    public init(){}
}
