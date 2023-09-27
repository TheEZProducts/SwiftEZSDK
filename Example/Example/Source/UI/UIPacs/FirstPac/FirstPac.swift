//
//  FirstPac.swift
//  Example
//
//  Created by Александр Сенин on 04.06.2023.
//

import UIKit
import EZUIPacKit
import EZAssociatedKit
import SwiftUI

@dynamicMemberLookup
class ColorSeter<Subject>{
    private var subject: Subject
    
    init(_ subject: Subject) {
        self.subject = subject
    }
    
    public subscript(dynamicMember key: WritableKeyPath<Subject, UIColor>) -> UIColor{
        set(new) { subject[keyPath: key] = new }
        get{ subject[keyPath: key] }
    }
    
    public subscript(dynamicMember key: WritableKeyPath<Subject, CGColor>) -> CGColor{
        set(new) { subject[keyPath: key] = new }
        get{ subject[keyPath: key] }
    }
    
    public subscript(dynamicMember key: WritableKeyPath<Subject, Optional<UIColor>>) -> Optional<UIColor>{
        set(new) { subject[keyPath: key] = new }
        get{ subject[keyPath: key] }
    }
    
    public subscript(dynamicMember key: WritableKeyPath<Subject, Optional<CGColor>>) -> Optional<CGColor>{
        set(new) { subject[keyPath: key] = new }
        get{ subject[keyPath: key] }
    }
}




typealias FirstPac = EZUIPac<FirstPacC, FirstPacR, FirstPacV>

class EZUIPacPlatformsV<R: EZUIPacRouterProtocol>: EZUIPacViewProtocol{
    var router: R!
    private(set) var view: (any EZUIPacViewProtocol<R>)?
    
    
    var iOS: (any EZUIPacViewProtocol<R>)? { nil }
    var iPadOS: (any EZUIPacViewProtocol<R>)? { nil }
    var macCatalyst: (any EZUIPacViewProtocol<R>)? { nil }
    var macOS: (any EZUIPacViewProtocol<R>)? { nil }
    var tvOS: (any EZUIPacViewProtocol<R>)? { nil }
    
    
    func getView(router: R) -> EZView {
        view?.getView(router: router) ?? EZView()
    }
    
    required init(router: R) {
        self.router = router
        setView()
    }
    
    open func setView(){
#if targetEnvironment(macCatalyst)
        view = macCatalyst
#elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone{
            view = iOS
        }else{
            view = iPadOS
        }
#elseif os(macOS)
        view = macOS
#elseif os(tvOS)
        view = tvOS
#endif
    }
    
    public var supportedOrientations: UIInterfaceOrientationMask { view?.supportedOrientations ?? .all }
    public func initActions(){ view?.initActions() }
    public func create(){ view?.create() }
    public func open(){ view?.open() }
    public func openWithAnimation(){ view?.openWithAnimation() }
    public func completedOpen(){ view?.completedOpen() }
    public func close(){ view?.close() }
    public func closeWithAnimation(){ view?.closeWithAnimation() }
    public func completedClose(){ view?.completedClose() }
    public func didResize(){ view?.didResize() }
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    public func didRotate(oldOrientation: UIInterfaceOrientation, newOrientation: UIInterfaceOrientation){
        view?.didRotate(oldOrientation: oldOrientation, newOrientation: newOrientation)
    }
#endif
}

class FirstPacV: EZUIPacPlatformsV<FirstPacR>{
    override var iOS: (any EZUIPacViewProtocol<FirstPacR>)? { FirstPacIOSV(router: router) }
    override var macCatalyst: (any EZUIPacViewProtocol<FirstPacR>)? { FirstPacIOSV(router: router) }
}


class FirstPacC: EZUIPacC{
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {.all}
    var router: FirstPacR!
    
    func start() {
       
        
        print("C - start")
        
//        _ = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { _ in
//            self.pack?.instead.pack(FirstPac()).transit()
//        })
        
    }
    
    func didCreate() {
//        transition(from: self, to: self, duration: 0.5, animations: {})
        
        transit()
    }
    
    private func transit(){
        let s = SecondPac()
//        s.currentOrientation = .portrait
        _ = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { _ in
            
            
//            self.pack?.container.superview?.addSubview(s.container)
//            s.startAction()
//            s.container.removeFromSuperview()
//            self.pack?.window?.rootViewController = s.controller
           
//            s.controller.beginAppearanceTransition(true, animated: false)
            EZTransition.instead(self.pack)
                .container(self.router.testView)
                .pack(s).safe(false).transit()
//            s.controller.endAppearanceTransition()
        })
        
    }
}

class FirstPacR: EZUIPacR{
    var testView: UIView = .init()
    
    var cActions = CAction()
    struct CAction: EZUIPacActionProviderProtocol{
        
    }
    
    var vActions = VAction()
    struct VAction: EZUIPacActionProviderProtocol{
        
    }
}

class FirstPacIOSV: EZUIPacV{
    var supportedOrientations: UIInterfaceOrientationMask { .all }
    
    var router: FirstPacR!
    
    func didRotate(oldOrientation: UIInterfaceOrientation, newOrientation: UIInterfaceOrientation) {
//        router.testView.frame.size = newOrientation.isPortrait == true ?
//            .init(width: 300, height: 500) :
//            .init(width: 500, height: 300)
        
        router.testView.center.x = bounds.midX
        router.testView.center.y = bounds.midY
    }
    
    func didResize() {
        router.testView.center.x = bounds.midX
        router.testView.center.y = bounds.midY
    }
    
    func create() {
        createSelf()
        
        resize()
        addSubview(router.testView)
    }
    
    func resize(){
        self.router.testView.backgroundColor = .black
        self.router.testView.frame.size = router.stateStorage.currentOrientation?.isPortrait == true ? .init(width: 300, height: 500) : .init(width: 500, height: 300)
        self.router.testView.center.x = self.bounds.midX
        self.router.testView.center.y = self.bounds.midY
    }
    
    private func createSelf(){
        backgroundColor = .blue
//        let aa = UIView()
//        aa.backgroundColor.updateSelf(new: #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1))
//        addSubview(aa)
       
//        EZAssociated(c).setDeinitObserver {
//            print("C i die")
//        }
//
//        EZAssociated(aa).setDeinitObserver {
//            print("i die")
//        }
//
        
        let testView = UIView()
        testView.frame.size.width = 200
        testView.frame.size.height = 200
        testView.backgroundColor = .black
        addSubview(testView)
    }
}

