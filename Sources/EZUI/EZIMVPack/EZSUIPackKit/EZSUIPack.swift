//
//  EZSUIPack.swift
//  EZSUIPackKit
//
//  Created by Александр Сенин on 07.02.2026.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine



// MARK: - Container (persists across SwiftUI re-renders)

/// Internal container that holds the IMV components and persists across SwiftUI re-renders.
///
/// `EZSUIPackContainer` is stored as a `@StateObject` inside `EZSUIPack`, ensuring that the
/// interactor, mediator, and view survive SwiftUI's identity-based lifecycle. It also subscribes
/// to the view model's `objectWillChange` publisher to trigger SwiftUI updates.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@MainActor
public final class EZSUIPackContainer<
    I: EZSUIPackInteractorProtocol,
    M: EZSUIPackMediatorProtocol,
    V: EZSUIPackViewProtocol
>: ObservableObject where I.Mediator == M, V.Mediator == M {
    let interactor: I
    let mediator: M
    let view: V

    private var viewModelCancellable: AnyCancellable?

    init(
        interactor makeI: () -> I,
        mediator makeM: (M.InputI, M.InputV, I.Context) -> M,
        view makeV: @escaping () -> V
    ) {
        interactor = makeI()
        view = makeV()
        mediator = makeM(interactor.makeInput(), view.makeInput(), interactor.makeContext())

        if let vm = mediator.viewModel as? (any ObservableObject) {
            viewModelCancellable = vm.willChangeSync {[weak self] in
                self?.objectWillChange.send()
            }
        }

        interactor.access.setMediator(mediator)
        view.access.setMediator(mediator)

        mediator.didInitialize()
        interactor.didInitialize()
        interactor.start()
    }
}


// MARK: - SwiftUI Pack View

/// A SwiftUI view that assembles and manages an IMV (Interactor-Mediator-View) pack.
///
/// `EZSUIPack` is the SwiftUI equivalent of `EZPackMaker.make()` for UIKit. It creates
/// and connects all three IMV components, preserves them across re-renders via `@StateObject`,
/// and forwards SwiftUI lifecycle events (`onAppear`/`onDisappear`) to the interactor.
///
/// ### Example
/// ```swift
/// struct ProfileScreen: View {
///     var body: some View {
///         EZSUIPack(
///             interactor: { ProfilePackI() },
///             mediator: { inputI, inputV, context in ProfilePackM(inputI: inputI, inputV: inputV) },
///             view: { ProfileView() }
///         )
///     }
/// }
/// ```
///
/// When `I.Context == Void`, you can use the shorter form:
/// ```swift
/// EZSUIPack(
///     interactor: { ProfilePackI() },
///     mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
///     view: { ProfileView() }
/// )
/// ```
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct EZSUIPack<
    I: EZSUIPackInteractorProtocol,
    M: EZSUIPackMediatorProtocol,
    V: EZSUIPackViewProtocol
>: View where I.Mediator == M, V.Mediator == M {
    @StateObject private var container: EZSUIPackContainer<I, M, V>

    public var body: some View {
        AnyView(container.view)
            .onAppear {
                container.interactor.onAppear()
            }
            .onDisappear {
                container.interactor.onDisappear()
            }
    }

    public init(
        interactor: @escaping () -> I,
        mediator: @escaping (M.InputI, M.InputV, I.Context) -> M,
        view: @escaping () -> V
    ) {
        _container = StateObject(wrappedValue: EZSUIPackContainer<I, M, V>(
            interactor: interactor,
            mediator: mediator,
            view: view
        ))
    }
}

/// Convenience initializer for packs where the interactor's `Context` is `Void`.
///
/// This overload omits the context parameter from the mediator closure,
/// making the call site shorter for the most common case.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension EZSUIPack where I.Context == Void {
    public init(
        interactor: @escaping () -> I,
        mediator: @escaping (M.InputI, M.InputV) -> M,
        view: @escaping () -> V
    ) {
        self.init(
            interactor: interactor,
            mediator: { inputI, inputV, _ in mediator(inputI, inputV) },
            view: view
        )
    }
}
#endif
