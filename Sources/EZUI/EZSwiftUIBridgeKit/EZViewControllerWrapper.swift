//
//  EZViewControllerWrapper.swift
//
//
//  Created by Александр Сенин on 18.02.2026.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

#if !os(watchOS)
/// A SwiftUI `ViewControllerRepresentable` wrapper for embedding a `UIViewController` / `NSViewController`.
///
/// `EZViewControllerWrapper` stores a factory closure that creates the view controller once.
/// An optional `update` closure is called on every SwiftUI update cycle.
///
/// This is a lightweight convenience alternative to writing a full
/// `UIViewControllerRepresentable` / `NSViewControllerRepresentable` type.
///
/// ### Example — wrap an existing controller
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         EZViewControllerWrapper(UIImagePickerController())
///     }
/// }
/// ```
///
/// ### Example — factory with update
/// ```swift
/// EZViewControllerWrapper({
///     let nav = UINavigationController()
///     return nav
/// }, update: { nav in
///     nav.isNavigationBarHidden = true
/// })
/// ```
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct EZViewControllerWrapper<VC: EZViewController>: EZViewControllerRepresentable {
    var factory: () -> VC
    var update: ((VC) -> Void)?

    /// Creates a wrapper from an autoclosure that produces the view controller.
    ///
    /// - Parameter factory: An expression that creates the view controller. Evaluated once.
    ///
    /// ### Example
    /// ```swift
    /// EZViewControllerWrapper(UIImagePickerController())
    /// ```
    public init(_ factory: @autoclosure @escaping () -> VC) {
        self.factory = factory
        self.update = nil
    }

    /// Creates a wrapper from a factory closure with an optional update handler.
    ///
    /// - Parameters:
    ///   - factory: Closure that creates the view controller. Called once.
    ///   - update: Called on every SwiftUI update cycle. `nil` by default.
    ///
    /// ### Example
    /// ```swift
    /// EZViewControllerWrapper({
    ///     MyViewController()
    /// }, update: { vc in
    ///     vc.title = "Updated"
    /// })
    /// ```
    public init(_ factory: @escaping () -> VC, update: ((VC) -> Void)? = nil) {
        self.factory = factory
        self.update = update
    }

#if canImport(UIKit)
    public func makeUIViewController(context: Context) -> VC { factory() }
    public func updateUIViewController(_ uiViewController: VC, context: Context) { update?(uiViewController) }
#elseif canImport(Cocoa)
    public func makeNSViewController(context: Context) -> VC { factory() }
    public func updateNSViewController(_ nsViewController: VC, context: Context) { update?(nsViewController) }
#endif
}

// MARK: - View + ezHostingController

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension View {
    /// Wraps `self` in an `EZHostingController` (`UIHostingController` / `NSHostingController`).
    ///
    /// Use this to turn any SwiftUI view into a view controller that can participate in
    /// UIKit/AppKit navigation (push, present, tab bar, etc.).
    ///
    /// ### Example
    /// ```swift
    /// let vc = Text("Hello").ezHostingController()
    /// navigationController?.pushViewController(vc, animated: true)
    /// ```
    public func ezHostingController() -> EZHostingController<Self> {
        EZHostingController(rootView: self)
    }
}
#endif
