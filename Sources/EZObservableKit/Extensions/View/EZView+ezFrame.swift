//
//  UIViewExtension.swift
//  EZObservableKit
//
//  Created by Александр Сенин on 23.03.2021.
//

/// Observable geometry helpers for `EZView` (UIKit `UIView` / AppKit `NSView`).
///
/// This file exposes KVO-backed `EZObservable` projections for a view's geometry:
/// - `ezFrame`, `ezBounds`
/// - derived components: `ezX`, `ezY`, `ezWidth`, `ezHeight`
///
/// The observation is stored via associated objects on the view instance, so it is created lazily
/// on first access and kept alive as long as the view is alive.
///
/// All updates are delivered on the main actor.

#if canImport(EZAssociatedKit)
import EZAssociatedKit
#endif

import EZAsyncKit

#if canImport(UIKit) && !os(watchOS)
import UIKit
public typealias EZView = UIView
public typealias EZScrollView = UIScrollView
#elseif canImport(Cocoa)
import Cocoa
public typealias EZView = NSView
public typealias EZScrollView = NSScrollView
#endif

#if (canImport(UIKit) || canImport(Cocoa)) && !os(watchOS)
@MainActor
class EZUIViewFrameObserve {
    private var keys: [NSKeyValueObservation?] = []
    @EZObservable var ezFrame: CGRect = .zero
    @EZObservable var ezBounds: CGRect = .zero
    
    @EZObservable var ezX: CGFloat = .zero
    @EZObservable var ezY: CGFloat = .zero
    @EZObservable var ezWidth: CGFloat = .zero
    @EZObservable var ezHeight: CGFloat = .zero
        
    init(_ view: EZView) {
        ezFrame = view.frame
        ezBounds = view.bounds
        setObserve(view)
    }
    
    private func setObserve(_ view: EZView) {
        keys.append(view.observe(\.frame, options: [.old, .new]) {[weak self] (view, value) in
            if value.oldValue == value.newValue {return}
            EZUnsafeMainWrapper.run {
                self?.ezFrame = view.frame
                if self?.ezBounds != view.bounds { self?.ezBounds = view.bounds }
            }
        })
#if canImport(UIKit)
        keys.append(view.observe(\.center, options: [.old, .new]) {[weak self] (view, value) in
            if value.oldValue == value.newValue {return}
            EZUnsafeMainWrapper.run {
                self?.ezFrame = view.frame
            }
        })
#endif
        keys.append(view.observe(\.bounds, options: [.old, .new]) {[weak self] (view, value) in
            if value.oldValue == value.newValue { return }
            EZUnsafeMainWrapper.run {
                if self?.ezFrame != view.frame { self?.ezFrame = view.frame }
                self?.ezBounds = view.bounds
            }
        })
        $ezFrame.addWithUnsafeIsolation {[weak self] value in
            if value.new.minX != self?.ezX        {self?.ezX = value.new.minX}
            if value.new.minY != self?.ezY        {self?.ezY = value.new.minY}
            if value.new.width != self?.ezWidth   {self?.ezWidth = value.new.width}
            if value.new.height != self?.ezHeight {self?.ezHeight = value.new.height}
        }.use()
    }
}


extension EZView{
    private var ezFrameKey: String { "EZFrame" }
    private var ezFrameObserve: EZUIViewFrameObserve {
        if let ezFrameO = EZAssociated(self).get(.hashable(ezFrameKey)) as? EZUIViewFrameObserve{
            return ezFrameO
        } else {
            let ezFrameO = EZUIViewFrameObserve(self)
            EZAssociated(self).set(ezFrameO, .hashable(ezFrameKey), .OBJC_ASSOCIATION_RETAIN)
            return ezFrameO
        }
    }
    
    /// Observable view of the receiver's current `frame`.
    ///
    /// Use this projected value to read the current frame (`wrappedValue`) or subscribe to frame
    /// changes (`add...`).
    ///
    /// ### Example
    /// ```swift
    /// let token = view.ezFrame.add { change in
    ///     print("frame:", change.new)
    /// }
    /// _ = token
    /// ```
    public var ezFrame: EZObservable<CGRect>.ProjectedValue { ezFrameObserve.$ezFrame }
    
    /// Observable view of the receiver's current `bounds`.
    ///
    /// ### Example
    /// ```swift
    /// _ = view.ezBounds.add { print("bounds:", $0.new) }
    /// ```
    public var ezBounds: EZObservable<CGRect>.ProjectedValue { ezFrameObserve.$ezBounds }
    
    /// Observable view of `frame.minX`.
    public var ezX: EZObservable<CGFloat>.ProjectedValue { ezFrameObserve.$ezX }
    
    /// Observable view of `frame.minY`.
    public var ezY: EZObservable<CGFloat>.ProjectedValue { ezFrameObserve.$ezY }
    
    /// Observable view of `frame.width`.
    public var ezWidth: EZObservable<CGFloat>.ProjectedValue { ezFrameObserve.$ezWidth }
    
    /// Observable view of `frame.height`.
    public var ezHeight: EZObservable<CGFloat>.ProjectedValue { ezFrameObserve.$ezHeight }
    
    /// Keeps the receiver's `frame.size` in sync with another view's `bounds.size`.
    ///
    /// Internally this subscribes to `view.ezBounds` and assigns the observed `bounds.size` to
    /// `self.frame.size`.
    ///
    /// - Parameter view: The view whose `bounds.size` should be mirrored.
    /// - Returns: An observation token. Keep it alive for as long as you want mirroring.
    ///
    /// ### Example
    /// ```swift
    /// final class Owner {}
    /// let owner = Owner()
    ///
    /// viewA.scaleLike(bounds: viewB)
    ///     .snapToObject(owner)
    /// ```
    @discardableResult
    public func scaleLike(bounds view: EZView) -> EZObserverToken<CGRect> {
        view.ezBounds.addWithUnsafeIsolation {[weak self] in self?.frame.size = $0.new.size }.use()
    }
    
    /// Keeps the receiver's `frame.size` in sync with another view's `frame.size`.
    ///
    /// Internally this subscribes to `view.ezFrame` and assigns the observed `frame.size` to
    /// `self.frame.size`.
    ///
    /// - Parameter view: The view whose `frame.size` should be mirrored.
    /// - Returns: An observation token. Keep it alive for as long as you want mirroring.
    ///
    /// ### Example
    /// ```swift
    /// final class Owner {}
    /// let owner = Owner()
    ///
    /// viewA.scaleLike(frame: viewB)
    ///     .snapToObject(owner)
    /// ```
    @discardableResult
    public func scaleLike(frame view: EZView) -> EZObserverToken<CGRect> {
        view.ezFrame.addWithUnsafeIsolation {[weak self] in self?.frame.size = $0.new.size }.use()
    }
}
#endif
