//
//  UIViewExtension.swift
//  EZObservableKit
//
//  Created by Александр Сенин on 23.03.2021.
//

#if canImport(EZAssociatedKit)
import EZAssociatedKit
#endif

import EZAsyncKit

#if canImport(UIKit)
import UIKit
public typealias EZView = UIView
public typealias EZScrollView = UIScrollView
#elseif canImport(Cocoa)
import Cocoa
public typealias EZView = NSView
public typealias EZScrollView = NSScrollView
#endif

#if canImport(UIKit) || canImport(Cocoa)
@MainActor
class EZUIViewFrameObserve{
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
    
    private func setObserve(_ view: EZView){
        keys.append(view.observe(\.frame, options: [.old, .new]) {[weak self] (view, value) in
            if value.oldValue == value.newValue {return}
            MainActor.ezUnsafeRun {
                self?.ezFrame = view.frame
                if self?.ezBounds != view.bounds { self?.ezBounds = view.bounds }
            }
        })
#if canImport(UIKit)
        keys.append(view.observe(\.center, options: [.old, .new]) {[weak self] (view, value) in
            if value.oldValue == value.newValue {return}
            MainActor.ezUnsafeRun {
                self?.ezFrame = view.frame
            }
        })
#endif
        keys.append(view.observe(\.bounds, options: [.old, .new]) {[weak self] (view, value) in
            if value.oldValue == value.newValue {return}
            MainActor.ezUnsafeRun {
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
    private var ezFrameKey: String {"EZFrame"}
    private var ezFrameObserve: EZUIViewFrameObserve{
        if let ezFrameO = EZAssociated(self).get(.hashable(ezFrameKey)) as? EZUIViewFrameObserve{
            return ezFrameO
        }else{
            let ezFrameO = EZUIViewFrameObserve(self)
            EZAssociated(self).set(ezFrameO, .hashable(ezFrameKey), .OBJC_ASSOCIATION_RETAIN)
            return ezFrameO
        }
    }
    
    public var ezFrame: EZObservable<CGRect>{ ezFrameObserve.$ezFrame }
    public var ezBounds: EZObservable<CGRect>{ ezFrameObserve.$ezBounds }
    public var ezX: EZObservable<CGFloat>{ ezFrameObserve.$ezX }
    public var ezY: EZObservable<CGFloat>{ ezFrameObserve.$ezY }
    public var ezWidth: EZObservable<CGFloat>{ ezFrameObserve.$ezWidth }
    public var ezHeight: EZObservable<CGFloat>{ ezFrameObserve.$ezHeight }
    
    @discardableResult
    public func scaleLike(bounds view: EZView) -> EZObserverToken<CGRect>{
        view.ezBounds.addWithUnsafeIsolation {[weak self] in self?.frame.size = $0.new.size }.use()
    }
    
    @discardableResult
    public func scaleLike(frame view: EZView) -> EZObserverToken<CGRect>{
        view.ezFrame.addWithUnsafeIsolation {[weak self] in self?.frame.size = $0.new.size }.use()
    }
}
#endif
