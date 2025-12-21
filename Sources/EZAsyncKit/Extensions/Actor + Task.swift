//
//  Actor + Task.swift
//  EZSDK
//
//  Created by Александр Сенин on 02.12.2025.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Actor {
#if compiler(>=6.2)
    /// Returns `true` when accessed while already running on this actor's executor.
    ///
    /// Treat this as a best-effort diagnostic / convenience API.
    ///
    /// The key detail: it stays `true` even when the check happens inside a synchronous `nonisolated`
    /// method, as long as that method was called from an isolated context of the same actor.
    ///
    /// ### Example
    /// ```swift
    /// actor Counter {
    ///     // Sync + nonisolated on purpose.
    ///     nonisolated func checkFromNonisolatedSync() -> Bool {
    ///         isIsolated
    ///     }
    ///
    ///     func demo() {
    ///         // We are on Counter's executor here.
    ///         print(checkFromNonisolatedSync()) // true
    ///     }
    /// }
    ///
    /// let counter = Counter()
    /// print(counter.checkFromNonisolatedSync()) // usually false (outside the actor)
    /// await counter.demo()
    /// ```
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
    nonisolated
    public var isIsolated: Bool {
        let isIsolated = EZSendableWrapper(wrappedValue: false)
        ezTaskImmediate { _ in isIsolated.wrappedValue = true }
        return isIsolated.wrappedValue
    }
#endif
    
    /// Executes `body` on this actor, preserving isolation.
    ///
    /// Use this when you want an explicit `isolated Self` parameter (e.g. to pass into helpers).
    ///
    /// ### Example
    /// ```swift
    /// actor Counter {
    ///     private var value = 0
    ///     func inc() { value += 1 }
    ///     func get() -> Int { value }
    /// }
    ///
    /// let counter = Counter()
    /// let current = try await counter.ezWithIsolation { actor in
    ///     actor.inc()
    ///     return actor.get()
    /// }
    /// ```
    public func ezWithIsolation<T>(_ body: @Sendable (isolated Self) async throws -> T) async rethrows -> T {
        try await body(self)
    }
    
    /// Creates a `Task` whose operation runs on this actor.
    ///
    /// ### Example
    /// ```swift
    /// actor Counter {
    ///     private var value = 0
    ///     func inc() { value += 1 }
    ///     func get() -> Int { value }
    /// }
    ///
    /// let counter = Counter()
    /// let task = counter.ezTask { actor in
    ///     actor.inc()
    ///     return actor.get()
    /// }
    /// let value = try await task.value
    /// ```
    @discardableResult
    nonisolated
    public func ezTask<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
        let body = EZUnsafeSendableWrapper(operation)
        return ezUnsafeRun { $0.makeTask(name: name, priority: priority, operation: body.value) }
    }
    
#if compiler(>=6.2)
    /// Like `ezTask`, but uses `Task.immediate` where available (Apple OS 26+).
    ///
    /// When you call this while already executing on the actor, the operation starts immediately,
    /// so side effects can be observed right after the call (even before awaiting `task.value`).
    ///
    /// This also holds if you call `ezTaskImmediate` from a synchronous `nonisolated` method,
    /// as long as that method itself is invoked from the actor's isolation.
    ///
    /// ### Example
    /// ```swift
    /// actor Box {
    ///     private var x = 0
    ///
    ///     // Sync + nonisolated on purpose.
    ///     nonisolated func bumpFromNonisolatedSync() {
    ///         ezTaskImmediate { actor in
    ///             actor.x += 1
    ///         }
    ///     }
    ///
    ///     func demoImmediate() {
    ///         x = 0
    ///
    ///         // Already isolated → runs immediately.
    ///         ezTaskImmediate { actor in
    ///             actor.x += 1
    ///         }
    ///         print(x) // 1
    ///
    ///         // Still immediate: the nonisolated method is called from inside the actor.
    ///         bumpFromNonisolatedSync()
    ///         print(x) // 2
    ///     }
    /// }
    ///
    /// let box = Box()
    ///
    /// if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
    ///     await box.demoImmediate()
    /// }
    /// ```
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
    @discardableResult
    nonisolated
    public func ezTaskImmediate<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
        let body = EZUnsafeSendableWrapper(operation)
        return ezUnsafeRun { $0.makeTaskImmediate(name: name, priority: priority, operation: body.value) }
    }
#endif
    
    /// Creates a detached `Task` and then hops onto this actor for the operation.
    ///
    /// ### Example
    /// ```swift
    /// actor Counter {
    ///     private var value = 0
    ///     func inc() { value += 1 }
    ///     func get() -> Int { value }
    /// }
    ///
    /// let counter = Counter()
    /// let task = counter.ezTaskDetached { actor in
    ///     actor.inc()
    ///     return actor.get()
    /// }
    /// let value = try await task.value
    /// ```
    @discardableResult
    nonisolated
    public func ezTaskDetached<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @Sendable @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
        let body = EZUnsafeSendableWrapper(operation)
        return ezUnsafeRun { $0.makeTaskDetached(name: name, priority: priority, operation: body.value) }
    }
    
    /// Runs `body` assuming the caller already has actor isolation.
    ///
    /// This uses `unsafeBitCast` and is intentionally sharp—prefer the task helpers above when possible.
    /// Both throwing and non-throwing overloads exist.
    ///
    /// ### Example
    /// ```swift
    /// actor Store {
    ///     private var items: [String] = []
    ///
    ///     func append(_ s: String) {
    ///         items.append(s)
    ///     }
    ///
    ///     func snapshot() -> [String] {
    ///         ezUnsafeRun { (actor: isolated Store) in
    ///             actor.items
    ///         }
    ///     }
    /// }
    /// ```
    nonisolated
    public func ezUnsafeRun<R>(_ body: @escaping (isolated Self) throws -> (R)) throws -> R {
        let unsafeAction = unsafeBitCast(body, to: ((Self) throws -> (R)).self)
        return try unsafeAction(self)
    }
    
    /// Runs `body` assuming the caller already has actor isolation.
    ///
    /// This uses `unsafeBitCast` and is intentionally sharp—prefer the task helpers above when possible.
    /// Both throwing and non-throwing overloads exist.
    ///
    /// ### Example
    /// ```swift
    /// actor Store {
    ///     private var items: [String] = []
    ///
    ///     func append(_ s: String) {
    ///         items.append(s)
    ///     }
    ///
    ///     func snapshot() -> [String] {
    ///         ezUnsafeRun { (actor: isolated Store) in
    ///             actor.items
    ///         }
    ///     }
    /// }
    /// ```
    nonisolated
    public func ezUnsafeRun<R>(_ body: @escaping (isolated Self) -> (R)) -> R {
        let unsafeAction = unsafeBitCast(body, to: ((Self) -> (R)).self)
        return unsafeAction(self)
    }
        
    private func makeTask<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
#if compiler(>=6.2)
        .init(name: name, priority: priority) { try await operation(self) }
#else
        .init(priority: priority) { try await operation(self) }
#endif
    }
    
#if compiler(>=6.2)
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
    private func makeTaskImmediate<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
        .immediate(name: name, priority: priority) { try await operation(self) }
    }
#endif
    
    private func makeTaskDetached<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @Sendable @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
#if compiler(>=6.2)
        .detached(name: name, priority: priority) { try await self.ezWithIsolation {
            try await operation($0)
        }}
#else
        .detached(priority: priority) { try await self.ezWithIsolation {
            try await operation($0)
        }}
#endif
    }
}
