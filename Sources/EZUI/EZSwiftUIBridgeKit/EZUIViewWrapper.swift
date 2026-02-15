//
//  EZUIViewWraper.swift
//  RelizApp
//
//  Created by Александр Сенин on 16.11.2020.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

#if !os(watchOS)
/// A tiny SwiftUI `ViewRepresentable` wrapper for embedding an `EZView` (UIKit/AppKit view).
///
/// `EZUIViewWrapper` holds a pre-created view instance and forwards SwiftUI update cycles to an
/// `update` closure. The closure is invoked once during initialization and then on every SwiftUI
/// update.
///
/// This is a lightweight convenience alternative to writing a full `UIViewRepresentable` /
/// `NSViewRepresentable` type.
///
/// ### Example
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         EZUIViewWrapper({
///             let label = UILabel()
///             label.textAlignment = .center
///             return label
///         }) { label in
///             label.text = "Hello"
///         }
///         .frame(height: 44)
///     }
/// }
/// ```
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct EZUIViewWrapper<V: EZView>: EZViewRepresentable {
    var view: V
    var update: (V) -> ()
    
    /// Creates the wrapped view by calling `init` and applies `update`.
    ///
    /// - Parameters:
    ///   - init: Factory closure that creates the underlying view.
    ///   - update: Called once immediately and then on every SwiftUI update.
    ///
    /// ### Example
    /// ```swift
    /// EZUIViewWrapper({ UILabel() }) { label in
    ///     label.text = "Updated"
    /// }
    /// ```
    public init(_ init: () -> V, _ update: @escaping (V) -> () = {_ in}){
        self.init(`init`(), update)
    }
    /// Wraps an existing view instance and applies `update`.
    ///
    /// `update` is called immediately during initialization and then on every SwiftUI update.
    ///
    /// ### Example
    /// ```swift
    /// let label = UILabel()
    /// let wrapped = EZUIViewWrapper(label) { $0.text = "Hello" }
    /// _ = wrapped
    /// ```
    public init(_ view: V, _ update: @escaping (V) -> ()){
        self.view = view
        self.update = update
        update(view)
    }
#if canImport(UIKit)
    public func makeUIView(context: Context) -> V { view }
    public func updateUIView(_ uiView: V, context: Context) { update(uiView) }
#elseif canImport(Cocoa)
    public func makeNSView(context: Context) -> V { view }
    public func updateNSView(_ nsView: V, context: Context) { update(nsView) }
#endif
}
#endif
