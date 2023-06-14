//
//  File.swift
//  
//
//  Created by Александр Сенин on 09.06.2023.
//

import Foundation
#if canImport(EZObservableKit)
import EZObservableKit
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

#if canImport(UIKit) ||  canImport(Cocoa)
open class EZContainerView: EZView{
    public var parentObserver: EZObserveAnchorObject?
    public weak var parentView: EZView?
    
    public var childObserver: EZObserveAnchorObject?
    public var childView: EZView?
    
    public var autoResizeParentOnRotation: Bool = false
   
    public init(){
        super.init(frame: .zero)
    }
    
    public init(frame like: EZView){
        super.init(frame: like.frame)
        parentObserver = scaleLike(frame: like).anchorObject
    }
    
    public init(bounds like: EZView){
        super.init(frame: like.bounds)
        parentObserver = scaleLike(bounds: like).anchorObject
    }
    
    @discardableResult
    public func addChildView(_ view: EZView?) -> Self{
        if let view{
            childView = view
            addSubview(view)
        }
        childObserver = childView?.scaleLike(bounds: self).anchorObject
        return self
    }
    
    open override func didMoveToSuperview() {
        addParentView(superview)
    }
    
    @discardableResult
    private func addParentView(_ parent: EZView?) -> Self{
//        removeFromSuperview()
        parentObserver = nil
        guard let parent = parent else {return self}
        self.parentView = parent
//        parent.addSubview(self)
        parentObserver = parent.ezBounds.add {[weak self] in
            print("oooo", $0.new.size)
            self?.frame = .init(origin: .zero, size: $0.new.size)
        }.use().anchorObject
//        parentObserver = scaleLike(frame: parent).anchorObject
        return self
    }
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    public func rotate(pi value: CGFloat, needToResize: Bool){
        
        if value != 0{ setTransform(pi: value) }
        
        if autoResizeParentOnRotation{
            superview?.frame.size = needToResize ? frame.size.swaped() : frame.size
        }else if frame.size != superview?.bounds.size{
////            superview?.needsUpdateConstraints()
//            print("oh", value, transform, superview?.frame.size)
//            print("oh", CGRect(origin: .zero, size: superview?.bounds.size ?? bounds.size))
            frame = .init(origin: .zero, size: superview?.bounds.size ?? bounds.size)
//            print("oh", frame)
//            print("oh", bounds)
        }
    }
#endif
    
    private func setTransform(pi value: CGFloat){
        transform = transform.rotated(by: value / 2)
        transform = transform.rotated(by: value / 2)
    }
    
    public func updateChild(){
        childView?.frame = bounds
    }
    
    @discardableResult
    public func scaleLike(frame view: EZView) -> Self{
        parentObserver = view.scaleLike(frame: view).anchorObject
        return self
    }
    
    @discardableResult
    public func scaleLike(bounds view: EZView) -> Self{
        parentObserver = view.scaleLike(bounds: view).anchorObject
        return self
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
