//
//  File.swift
//
//
//  Created by Александр Сенин on 04.06.2023.
//

import Foundation

import EZAsyncKit

#if canImport(EZAssociatedKit)
import EZAssociatedKit
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

#if (canImport(UIKit) || canImport(Cocoa)) && !os(watchOS)
@MainActor
class EZUIScrollViewContentOffSetObserve {
    private var key: NSKeyValueObservation?
    @EZObservable var ezContentOffSet: CGPoint = .zero
    private weak var view: EZScrollView?
    
    init(_ view: EZScrollView) {
        self.view = view
#if canImport(UIKit)
        ezContentOffSet = view.contentOffset
        key = view.observe(\.contentOffset) {[weak self] (scroll, _) in
            EZUnsafeMainWrapper.run {
                if self?.ezContentOffSet != scroll.contentOffset{
                    self?.ezContentOffSet = scroll.contentOffset
                }
            }
        }
#elseif canImport(Cocoa)
        ezContentOffSet = view.contentView.bounds.origin
        key = view.contentView.observe(\.bounds) {[weak self] (scroll, _) in
            EZUnsafeMainWrapper.run {
                if self?.ezContentOffSet != scroll.bounds.origin{
                    self?.ezContentOffSet = scroll.bounds.origin
                }
            }
        }
#endif
    }
}

extension EZScrollView{
    private var ezContentOffSetKey: String {"EZContentOffSet"}
    
    /// Observable view of the scroll view's current content offset.
    ///
    /// This property exposes an `EZObservable<CGPoint>.ProjectedValue` that you can use to:
    /// - read the current offset (`wrappedValue`),
    /// - subscribe to offset changes (`add...`).
    ///
    /// Under the hood it installs a KVO observer and stores the observation in an associated object
    /// tied to the scroll view instance.
    ///
    /// Platform notes:
    /// - On UIKit, it observes `contentOffset`.
    /// - On AppKit, it observes the scroll view's `contentView.bounds.origin`.
    ///
    /// ### Example
    /// ```swift
    /// let token = scrollView.ezContentOffset.add { change in
    ///     print("offset:", change.new)
    /// }
    /// _ = token
    ///
    /// // Read current offset:
    /// let current = scrollView.ezContentOffset.wrappedValue
    /// print(current)
    /// ```
    public var ezContentOffset: EZObservable<CGPoint>.ProjectedValue {
        if let scrollViewContentOffSetObserve = EZAssociated(self)
            .get(.hashable(ezContentOffSetKey)) as? EZUIScrollViewContentOffSetObserve
        {
            return scrollViewContentOffSetObserve.$ezContentOffSet
        }else{
            let scrollViewContentOffSetObserve = EZUIScrollViewContentOffSetObserve(self)
            EZAssociated(self)
                .set(scrollViewContentOffSetObserve, .hashable(ezContentOffSetKey), .OBJC_ASSOCIATION_RETAIN)
            return scrollViewContentOffSetObserve.$ezContentOffSet
        }
    }
}
#endif
