//
//  File.swift
//  
//
//  Created by Александр Сенин on 04.06.2023.
//

import Foundation

#if canImport(EZAssociatedKit)
import EZAssociatedKit
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif


#if canImport(UIKit) || canImport(Cocoa)
class EZUIScrollViewContentOffSetObserve{
    private var key: NSKeyValueObservation?
    @EZObservable var ezContentOffSet: CGPoint = .zero
    private weak var view: EZScrollView?
    
    init(_ view: EZScrollView) {
        self.view = view
#if canImport(UIKit)
        ezContentOffSet = view.contentOffset
        key = view.observe(\.contentOffset) {[weak self] (scroll, _) in
            if self?.ezContentOffSet != scroll.contentOffset{
                self?.ezContentOffSet = scroll.contentOffset
            }
        }
#elseif canImport(Cocoa)
        ezContentOffSet = view.contentView.bounds.origin
        key = view.contentView.observe(\.bounds) {[weak self] (scroll, _) in
            if self?.ezContentOffSet != scroll.bounds.origin{
                self?.ezContentOffSet = scroll.bounds.origin
            }
        }
#endif
    }
}

extension EZScrollView{
    private var ezContentOffSetKey: String {"EZContentOffSet"}
    
    public var ezContentOffset: EZObservable<CGPoint>{
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
