//
//  MainActor + ezUnsafeRun.swift
//  EZSDK
//
//  Created by Александр Сенин on 03.12.2025.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension MainActor {
    /// Executes a non-throwing `@MainActor` closure synchronously.
    ///
    /// This is useful when you have a sync method that cannot be annotated `@MainActor`,
    /// but is guaranteed (by design) to be called from the MainActor.
    ///
    /// ### Example (sync API, called from MainActor)
    /// ```swift
    /// protocol Renderer {
    ///     func render() // sync; cannot be `async`
    /// }
    ///
    /// @MainActor
    /// final class UIState {
    ///     var title: String = ""
    /// }
    ///
    /// final class Presenter: Renderer {
    ///     let state: UIState
    ///     init(state: UIState) { self.state = state }
    ///
    ///     // Not `@MainActor`, but guaranteed to be called on MainActor.
    ///     func render() {
    ///         MainActor.ezUnsafeRun {
    ///             state.title = "Ready" // ok
    ///         }
    ///     }
    /// }
    ///
    /// let presenter = Presenter(state: UIState())
    /// await MainActor.run { presenter.render() }
    /// ```
    nonisolated
    public static func ezUnsafeRun<Result>(
        @_implicitSelfCapture
        action: @MainActor @escaping @Sendable () -> (Result)
    ) -> Result {
        let action = unsafeBitCast(action, to: (() -> (Result)).self)
        return action()
    }
    
    /// Executes a throwing `@MainActor` closure synchronously.
    ///
    /// Same idea as the non-throwing overload, but for sync APIs that need to throw.
    ///
    /// ### Example (sync + throws, called from MainActor)
    /// ```swift
    /// enum MyError: Error { case failed }
    ///
    /// @MainActor
    /// final class Store {
    ///     func load() throws -> Int { 1 }
    /// }
    ///
    /// final class Service {
    ///     let store: Store
    ///     init(store: Store) { self.store = store }
    ///
    ///     // Not `@MainActor`, but guaranteed to be called on MainActor.
    ///     func loadSync() throws -> Int {
    ///         try MainActor.ezUnsafeRun {
    ///             try store.load()
    ///         }
    ///     }
    /// }
    ///
    /// let service = Service(store: Store())
    /// let value = try await MainActor.run { try service.loadSync() }
    /// print(value)
    /// ```
    nonisolated
    public static func ezUnsafeRun<Result>(
        @_implicitSelfCapture
        action: @MainActor @escaping @Sendable () throws -> (Result)
    ) throws -> Result {
        let action = unsafeBitCast(action, to: (() throws -> (Result)).self)
        return try action()
    }
}
