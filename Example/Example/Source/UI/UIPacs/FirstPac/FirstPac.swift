//
//  FirstPac.swift
//  Example
//
//  Created by Александр Сенин on 04.06.2023.
//

import UIKit
import EZUIPackKit
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

typealias FirstPac = EZUITabBarPack<FirstPacI, FirstPacM, FirstPacV>

class FirstPacV: EZUIPackPlatformsV<FirstPacM>{
    override var iOS: (any EZUIPackViewProtocol<FirstPacM>)? { FirstPacIOSV(mediator: mediator) }
    override var macCatalyst: (any EZUIPackViewProtocol<FirstPacM>)? { FirstPacIOSV(mediator: mediator) }
}


class FirstPacI: EZUIPackI{
    var mediator: FirstPacM!
    
    func didInitialize() {
        
    }
    
    func start() {
    
    }
    
    func didCreate() {
//        packBridge.tabBarPack?.toolbarItems = []
//        packBridge.tabBarPack?.tabBar.isHidden = true
        transit
            .tabBarSet(
                [
                    UIViewController().apply(template: .custom{ $0.view.backgroundColor = .init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1) }),
                    UIViewController().apply(template: .custom{ $0.view.backgroundColor = .init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1) })
                ])
            .transit()
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2){
//            self.transit
//                .tabBarSet([.tabBarWrapper([SecondPac(), SecondPac(), SecondPac()])])
//                .unsafeTransition()
//                .animation(.ezOpen)
//                .transit()
//        }
        
    }
    
    func didInstall() {
//        transit()
    }
    
    func willOpen() {
    }
    
    func didOpen() {

    }
    
    private func transit(){
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2){
//            let navigation = UINavigationController()
//            self.mediator.testView.transit
//                .present(navigation)
//                .unsafeTransition()
//                .animation(.coverVertical)
//                .transit()
//            
//            EZTransition(navigation)
//                .navigationPush(SecondPac())
//                .unsafeTransition()
//                .transit()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5){
//            Task{
                var animator: UIPercentDrivenInteractiveTransition?
                var test: UIViewController?
        
            print()
            print()
            print()
            print()
            let tansition = self.mediator.testView.transit
//            .present(SecondPac())
                    .present(
                        .tabBarWrapper([SecondPac(), SecondPac(), SecondPac()])
//                        SecondPac()
                        //                .apply(template: .childAnimation(animation: .ezOpen))
                        //                .apply(template: .hiddenNavigationBar)
                        //                .apply(template: .childAnimations(push: .ezAppearance, pop: .ezDisappearance))
                            .apply(template: .custom{
                                $0.transitionController = .custom{[weak self] context in
                                    self?.transit(context: context) ?? false
                                }
                                test = $0
                                $0.tabBar.isHidden = true
                            })
//                            .apply(template: .custom({
//                                $0.preferredContentSize = .init(width: 200, height: 300)
//                            }))
//                            .apply(template: .custom{
//                                $0.modalPresentationStyle = .popover
//                                if
//                                    let popover = $0.popoverPresentationController,
//                                    let view = self.packBridge.pack!.view
//                                {
//                                    popover.sourceView = view  // или, например, сама кнопка
//                                    popover.sourceRect = CGRect(x: view.bounds.midX,
//                                                                y: view.bounds.midY,
//                                                                width: 0,
//                                                                height: 0)
//                                    popover.permittedArrowDirections = []
//                                    $0.preferredContentSize = CGSize(width: 400, height: 300)
//                                }
//                            })
                    )
//                    .presentationStyle(.automatic)
                    .unsafeTransition()
//                    .animate()
//                    .animation(.ezOpen)
                
                tansition.transit()
                print("open bbb")
//            }
//        }
//        }
        
    }
    
    required init(){}
}

extension FirstPacI: EZTransitionControllerProtocol{
    func transit(context: EZCustomTransitionContext) -> Bool {
        transitTabBar(context: context)
    }
    
    private func transitNavigation(context: EZCustomTransitionContext) -> Bool{
        if context.transitionType == .ezNext{
            return context.fromController?.transit
                .navigationPush(SecondPac())
                .animate()
                .completion {
                    context.completion?()
                    print("next completion")
                }
                .transit() ?? false
        }else if context.transitionType == .ezBack{
            return context.fromController?.transit
                .navigationPop()
                .animate()
                .completion {
                    context.completion?()
                    print("back completion")
                }
                .transit() ?? false
        }else if context.transitionType == .ezClose{
            return context.fromController?.transit
                .dismiss()
                .completion {
                    context.completion?()
                    print("close completion")
                }
                .transit() ?? false
        }else{ return false }
    }
    
    private func transitTabBar(context: EZCustomTransitionContext) -> Bool{
        if context.transitionType == .ezNext{
            return context.fromController?.transit
                .tabBarNext()
                .animation(.ezShift(direction: .up))
                .completion {
                    context.completion?()
                    print("next completion")
                }
                .transit() ?? false
        }else if context.transitionType == .ezBack{
            return context.fromController?.transit
                .tabBarBack()
                .animation(.ezShift(direction: .down))
                .completion {
                    context.completion?()
                    print("back completion")
                }
                .transit() ?? false
        }else if context.transitionType == .ezClose{
            return context.fromController?.transit
                .dismiss()
                .animation(.ezDisappearance(duration: 1))
                .completion {
                    context.completion?()
                    print("close completion")
                }
                .transit() ?? false
        }else{ return false }
    }
}

class FirstPacM: EZUIPackM{
    var packBridge = EZUIPackBridge()
    
    var testView: EZContainerView = .init()
    
    var iActions = iAction()
    struct iAction: EZUIPackActionProviderProtocol{
        
    }
    
    var vActions = VAction()
    struct VAction: EZUIPackActionProviderProtocol{
        
    }
}
 
extension UIView{
    var isPortrait: Bool { bounds.width < bounds.height }
}

class FirstPacIOSV: EZUIPackV{
    var supportedInterfaceOrientations: UIInterfaceOrientationMask? { .all }
    
    var mediator: FirstPacM!
    
    func create() {
        createSelf()
        createTestView()
    }
    
    func willOpen() {
        print("FirstPacIOSV", "willOpen", frame)
    }
    
    func animateOpen() {
        print("FirstPacIOSV", "animateOpen", frame)
    }
    
    func didOpen() {
        print("FirstPacIOSV", "didOpen", frame)
    }
        
    private func createSelf(){
        backgroundColor = .blue
    }
    
    private func createTestView(){
        addSubview(mediator.testView)
        mediator.testView.translatesAutoresizingMaskIntoConstraints = false
        mediator.testView.layer.masksToBounds = true
        mediator.testView.isUserInteractionEnabled = false
        NSLayoutConstraint.activate([
            mediator.testView.centerXAnchor.constraint(equalTo: centerXAnchor),
            mediator.testView.centerYAnchor.constraint(equalTo: centerYAnchor),
            mediator.testView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),
            mediator.testView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5)
        ])
        mediator.testView.presentationStatusDidUpdateAction = {view, status in
            view.isUserInteractionEnabled = status
        }
    }
}

