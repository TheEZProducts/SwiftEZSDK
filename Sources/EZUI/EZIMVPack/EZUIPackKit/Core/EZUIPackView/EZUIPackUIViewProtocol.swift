//
//  EZUIPackUIViewProtocol.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

#if canImport(UIKit) && !os(watchOS)
/// Type alias for the platform-appropriate view type used throughout the IMV architecture.
///
/// `EZView` abstracts the platform differences:
/// - On UIKit platforms (iOS, tvOS, visionOS): `UIView`
/// - On macOS: `NSView`
///
/// This type alias allows you to write platform-agnostic code when working with views in packs.
/// All view-related APIs in `EZUIPackKit` use `EZView` instead of platform-specific types.
///
/// ### Example
/// ```swift
/// class MyView: EZView {
///     // Works on both iOS and macOS
/// }
/// ```
public typealias EZView = UIView
#elseif canImport(Cocoa)
/// Type alias for the platform-appropriate view type used throughout the IMV architecture.
///
/// `EZView` abstracts the platform differences:
/// - On UIKit platforms (iOS, tvOS, visionOS): `UIView`
/// - On macOS: `NSView`
///
/// This type alias allows you to write platform-agnostic code when working with views in packs.
/// All view-related APIs in `EZUIPackKit` use `EZView` instead of platform-specific types.
///
/// ### Example
/// ```swift
/// class MyView: EZView {
///     // Works on both iOS and macOS
/// }
/// ```
public typealias EZView = NSView
#endif


#if (canImport(UIKit) || canImport(Cocoa)) && !os(watchOS)
/// Protocol for views that are themselves `UIView` (or `NSView` on macOS) instances.
///
/// Views conforming to this protocol directly return themselves when `getView()` is called.
/// Use this for views that subclass `UIView` or `NSView`.
///
/// ### Example
/// ```swift
/// class ProfileIOSV: UIView, EZUIPackUIViewProtocol {
///     let access = ProfilePackM.accessV
///     
///     func makeInput() -> Mediator.InputV { self }
///     
///     func create() {
///         backgroundColor = .systemBackground
///         setupSubviews()
///     }
/// }
/// ```
public protocol EZUIPackUIViewProtocol: EZView, EZUIPackViewProtocol
    where Access == EZIMVPackAccessV<Mediator, Mediator.AccessMapV> {}
extension EZUIPackUIViewProtocol{
    /// Returns the view itself since it's already a `UIView`/`NSView`.
    public func getView() -> EZView { self }
}

/// The primary type for creating UIKit-based views in the IMV architecture.
///
/// `EZUIPackV` is a type alias that combines `EZView` (which is `UIView` on iOS/tvOS/visionOS
/// or `NSView` on macOS) with `EZUIPackUIViewProtocol`, providing everything you need to create
/// a UIKit-based view for packs. This is the **recommended base type** for all UIKit view implementations.
///
/// A view created with this type:
/// - Is itself a `UIView`/`NSView` instance (returns `self` from `getView()`)
/// - Automatically integrates with the IMV architecture
/// - Can access the mediator's view model and interactor's actions
/// - Supports UIKit lifecycle methods (`create()`, `willOpen()`, `animateOpen()`, etc.)
/// - Can customize interface orientation and status bar appearance
///
/// ## Example: Complete UIKit view implementation
///
/// ```swift
/// class ProfileIOSV: EZUIPackV {
///     let access = ProfilePackM.accessV
///
///     func makeInput() -> Mediator.InputV { self }
///
///     func create() {
///         backgroundColor = .systemBackground
///         setupSubviews()
///         configureConstraints()
///     }
///
///     func willOpen() {
///         // Prepare for appearance
///     }
///
///     func animateOpen() {
///         UIView.animate(withDuration: 0.3) {
///             self.alpha = 1.0
///         }
///     }
///
///     private func setupSubviews() {
///         // Add and configure subviews
///     }
/// }
///
/// extension ProfileIOSV: ProfilePackM.InputVProtocol {
///     func showError(message: String) {
///         // Display error alert
///     }
///
///     func refreshUI() {
///         // Update UI elements based on viewModel
///         if viewModel.isLoading {
///             showLoadingIndicator()
///         } else {
///             hideLoadingIndicator()
///             displayProfile(viewModel.profile)
///         }
///     }
/// }
/// ```
///
/// ## Lifecycle Methods
///
/// The view can override these lifecycle methods:
/// - `didInitialize()` - Called after mediator is created
/// - `create()` - Called when view is first created
/// - `willOpen()` / `animateOpen()` / `didOpen()` - Called when pack appears
/// - `didInstall()` - Called after first layout
/// - `willClose()` / `animateClose()` / `didClose()` - Called when pack disappears
///
/// ## Access Pattern
///
/// - Use `access.viewModel` to read/write shared state
/// - Use `access.inputI` to trigger interactor actions
/// - Implement `InputVProtocol` to provide actions the interactor can call
///
/// - Note: Always use `EZUIPackV` as your base type for UIKit views. It provides the necessary
///   infrastructure for IMV integration and proper view lifecycle management.
public typealias EZUIPackV = EZView & EZUIPackUIViewProtocol
#endif


#endif
