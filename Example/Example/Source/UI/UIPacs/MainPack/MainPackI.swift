//
//  MainPackI.swift
//  Example
//
//  Created by Александр Сенин on 16.02.2025.
//

import EZUIPackKit
import UIKit
import Foundation

class MainPackI: EZUIPackI{
    var mediator: MainPackM!
    
    func setupActions() {
        iActions = self
    }
    
    var firstPac = FirstPac()
    
    func start() {
        
        let r = self.transit
            .navigationSet([FirstPac()])
            .animation(.ezOpen)
            .transit()
        
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
//            let r = self.transit
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
//                self.transit
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
    
    
    required init(){}
}

//MARK: - Actions
extension MainPackI: MainPackM.IActionProvider{
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

class MainPackM: EZUIPackM{
    var packBridge = EZUIPackBridge()
    
    var test: Int = 10
    
    var sdf: DGsg
    
    
    init(test: DGsg){
        self.sdf = test
        super.init()
    }
    
    required init() {
        sdf = .init()
        super.init()
    }
    
    weak var iActions: IActionProvider?
    @MainActor protocol IActionProvider: AnyObject{
        func test()
    }
    
    weak var vActions: VActionProvider?
    @MainActor protocol VActionProvider: AnyObject{
        func test()
    }
    
    var shared: EZSharedStorage? {
        .init([
            .init(key: .mainPackMChain.test, value: test)
        ])
    }
}

extension Optional: @retroactive EZUIPackActionProviderProtocol{}

class MainPackV: EZUIPackV{
    var mediator: MainPackM!
    
    func setupActions() {
        vActions = self
    }
    
    func create() {
        createSelf()
        
        iActions?.test()
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

extension MainPackV: MainPackM.VActionProvider{
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
