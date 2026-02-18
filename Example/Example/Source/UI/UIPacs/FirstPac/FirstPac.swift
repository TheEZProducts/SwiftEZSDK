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

typealias FirstPac = EZUIPack<FirstPacI, FirstPacM, FirstPacV>

extension FirstPac {
    static func make(interactor makeI: @autoclosure () -> FirstPacI = .init()) -> FirstPacI {
        make(
            interactor: makeI,
            mediator: { inputI, inputV in FirstPacM(inputI: inputI, inputV: inputV) },
            view: { FirstPacV() }
        )
    }
}

class FirstPacV: EZUIPackPlatformsV<FirstPacM>{
    override var iOS: (any EZUIPackViewProtocol<FirstPacM>)? { FirstPacIOSV() }
    override var macCatalyst: (any EZUIPackViewProtocol<FirstPacM>)? { FirstPacIOSV() }
}


class FirstPacI: EZUIPackI {
    let access = FirstPacM.accessI
    
    var value: Int = 10
    
    func makeInput() -> Mediator.InputI { .init() }
    
    
    func didInitialize() {
        
    }
    
    func start() {
    
    }
    
    func didCreate() {
//        self.ezTransit
//            .present(.tabBarWrapper([SecondPac.make(), SecondPac.make(), SecondPac.make()]))
//            .unsafeTransition()
//            .animation(.ezOpen)
//            .transit()
    
       
            self.transit()
        
        
//        packBridge.tabBarPack?.toolbarItems = []
//        packBridge.tabBarPack?.tabBar.isHidden = true
//        ezTransit
//            .tabBarSet(
//                [
//                    UIViewController().apply(template: .custom{ $0.view.backgroundColor = .init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1) }),
//                    UIViewController().apply(template: .custom{ $0.view.backgroundColor = .init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1) })
//                ])
//            .transit()
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2){
//            self.ezTransit
//                .tabBarSet([.tabBarWrapper([SecondPac.make(), SecondPac.make(), SecondPac.make()])])
//                .unsafeTransition()
//                .animation(.ezOpen)
//                .transit()
//        
//        
//            self.transit()
//        }
    }
    
    func didInstall() {
       
    }
    
    func willOpen() {
        print("aaa")
    }
    
    func didOpen() {

    }
    
    private func transit(){
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2){
//            let navigation = UINavigationController()
//            self.mediator.testView.ezTransit
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
        let tansition = self.viewModel.testView.ezTransit
//            .present(SecondPac())
                    .present(
                        .tabBarWrapper([SecondPac.make(), SecondPac.make(), SecondPac.make()])
//                        SecondPac()
                        //                .apply(template: .childAnimation(animation: .ezOpen))
                        //                .apply(template: .hiddenNavigationBar)
                        //                .apply(template: .childAnimations(push: .ezAppearance, pop: .ezDisappearance))
                            .apply(template: .custom {
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
                    .animate()
//                    .animate()
//                    .animation(.ezOpen)
                
                tansition.transit()
                print("open bbb")
//            }
//        }
//        }
        
    }
    
    
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FirstPacI: EZTransitionControllerProtocol{
    func transit(context: EZCustomTransitionContext) -> Bool {
        transitTabBar(context: context)
    }
    
    private func transitNavigation(context: EZCustomTransitionContext) -> Bool{
        if context.transitionType == .ezNext{
            return context.fromController?.ezTransit
                .navigationPush(SecondPac.make())
                .animate()
                .completion {
                    context.completion?()
                    print("next completion")
                }
                .transit() ?? false
        }else if context.transitionType == .ezBack{
            return context.fromController?.ezTransit
                .navigationPop()
                .animate()
                .completion {
                    context.completion?()
                    print("back completion")
                }
                .transit() ?? false
        }else if context.transitionType == .ezClose{
            return context.fromController?.ezTransit
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
            return context.fromController?.ezTransit
                .tabBarNext()
                .animation(.ezShift(direction: .up))
                .completion {
                    context.completion?()
                    print("next completion")
                }
                .transit() ?? false
        }else if context.transitionType == .ezBack{
            return context.fromController?.ezTransit
                .tabBarBack()
                .animation(.ezShift(direction: .down))
                .completion {
                    context.completion?()
                    print("back completion")
                }
                .transit() ?? false
        }else if context.transitionType == .ezClose{
            return context.fromController?.ezTransit
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

class FirstPacM: EZUIPackM {
    var viewModel: ViewModel
    @MainActor struct ViewModel {
        var test: Int = 10
        
        var testView: EZContainerView = .init()
    }
    
    
    var inputI = IAction()
    struct IAction {

    }

    let inputV: Void = ()

    init(inputI: InputI, inputV: InputV) {
        self.viewModel = .init()
        self.inputI = inputI
    }
}
 
extension UIView {
    var isPortrait: Bool { bounds.width < bounds.height }
}

class FirstPacIOSV: EZUIPackV {
    var supportedInterfaceOrientations: UIInterfaceOrientationMask? { .all }

    let access = FirstPacM.accessV
    
    
    
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
        addSubview(viewModel.testView)
        viewModel.testView.translatesAutoresizingMaskIntoConstraints = false
        viewModel.testView.layer.masksToBounds = true
        viewModel.testView.isUserInteractionEnabled = false
        NSLayoutConstraint.activate([
            viewModel.testView.centerXAnchor.constraint(equalTo: centerXAnchor),
            viewModel.testView.centerYAnchor.constraint(equalTo: centerYAnchor),
            viewModel.testView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),
            viewModel.testView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5)
        ])
        viewModel.testView.presentationStatusDidUpdateAction = { view, status in
            view.isUserInteractionEnabled = status
        }
    }
}

