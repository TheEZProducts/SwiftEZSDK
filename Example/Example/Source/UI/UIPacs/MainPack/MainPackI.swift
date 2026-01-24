//
//  MainPackI.swift
//  Example
//
//  Created by Александр Сенин on 16.02.2025.
//

import EZUIPackKit
import UIKit
import Foundation

class MainPackI: EZUINavigationPackI {
    let access = MainPackM.accessI
    
    func makeContext() -> Mediator.ContextI {
        .init(actions: self, viewModel: .init())
    }
    
    var firstPac = FirstPac.make(interactor: .init())
    
    
    func didInstall() {
            let r = self.ezTransit
                .present(FirstPac.make(interactor: FirstPacI()))
            //            .navigationSet([FirstPac.make()])
            //            .animate()
            //            .animation(.ezAppearance)
                .transit()
    }
    
    func start() {
        
        
        
//        let r = self.transit
//            .tabBarSet([self.firstPac])
//            .unsafeTransition()
//            .transit()
        
//        let viewC = SecondPac()
////            .apply(template: .custom({
////                $0.preferredContentSize = CGSize(width: 300, height: 400)
////            }))
//            
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5){
//            let r = self.transit
//                .present(viewC)
//                .unsafeTransition()
//                .animate()
//                .transit()
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 7){
//            let r = viewC.transit
//                .dismiss()
//                .unsafeTransition()
//                .animate()
//                .transit()
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 9){
////            let r = self.transit
////                .present(
////                    SecondPac().apply(template: .custom({
////                        $0.preferredContentSize = CGSize(width: 300, height: 400)
////                    }))
////                )
////                .unsafeTransition()
////                .presentationStyle(.pageSheet)
////                .animate()
////                .transit()
//            
//            self.pack?.present(
//                .tabBarWrapper(SecondPac())
//                .apply(template: .custom({
//                    $0.modalPresentationStyle = .pageSheet
//                    //$0.preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 400)
////                    $0.sheetPresentationController?.detents = [
////                        .custom { context in
////                            return context.maximumDetentValue * 0.4
////                        },
////                        .large()
////                    ]
////                    $0.sheetPresentationController?.prefersGrabberVisible = true
//                })),
//                animated: true
//            )
//        }
//        
       
        
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5){
//            let r = self.ezTransit
//                .tabBarSet([UIViewController()])
//                .animation(.ezOpen)
//                .transit()
////            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2){
//                print()
//                print()
//                print()
//                print()
//                print()
//                self.ezTransit
//                    .present(
////                        FirstPac()
//                        self.firstPac
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
//                                    $0.preferredContentSize = CGSize(width: 300, height: 200)
//                                }
//                            })
//                    )
////                    .presentationStyle(.automatic)
//                    .animate()
//                    .transit()
//            }
//        }
    }
}



//MARK: - Actions
extension MainPackI: MainPackM.IAction {
    func test() {
        print("Test")
    }
}

extension EZSharedKeyChain<MainPackM>{
    var test: EZSharedKey<Self, Int> { .init(key: "Test") }
}

extension EZSharedKey{
    static var mainPackMChain: EZSharedKeyChain<MainPackM> { .init() }
}

@MainActor
struct DGsg{
    var test: Int = 10
}

class MainPackM: EZUIPackM {
    var storage: Void = ()
    
    var viewModel: ViewModel
    @MainActor struct ViewModel {
        var test: Int = 10
        var sdf: DGsg = .init()
    }
        
    weak let inputI: IAction?
    @MainActor protocol IAction: AnyObject{
        func test()
    }
    
    weak let inputV: VAction?
    @MainActor protocol VAction: AnyObject{
        func test()
    }
    
    required init(contextI: BaseContextI, contextV: BaseContextV) {
        viewModel = contextI.viewModel
        inputI = contextI.actions
        inputV = contextV.actions
    }
}



class MainPackV: EZUIPackV {
    let access = MainPackM.accessV
    
    func makeContext() -> Mediator.ContextV {
        .init(actions: self)
    }
    
    func create() {
        createSelf()
        
        inputI?.test()
    }
    
    func willOpen() {
        print("MainPackV", "willOpen", frame)
    }
    
    func animateOpen() {
        print("MainPackV", "animateOpen", frame)
    }
    
    func didOpen() {
        print("MainPackV", "didOpen", frame)
    }
    
    private func createSelf(){
        self.backgroundColor = .blue
    }
}

extension MainPackV: MainPackM.VAction {
    func test() {
        print("MainPackV", "Test")
    }
}

protocol Teesfgds{
    associatedtype Provider = Self
    
    var provider: Provider { get }
}

extension Teesfgds where Provider == Self{
    var provider: Provider { self }
}


struct Dgfdg: Teesfgds{
    var provider: Int { 10 }
}
