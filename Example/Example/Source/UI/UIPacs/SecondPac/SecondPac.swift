//
//  SecondPac.swift
//  Example
//
//  Created by Александр Сенин on 04.06.2023.
//

import UIKit
import EZUIPacKit
import EZSwiftUIBridgeKit
import EZObservableKit
import SwiftUI

typealias SecondPac = EZUIPac<SecondPacC, SecondPacR, SecondPacSV>

func setUIInterfaceOrientation(_ value: UIInterfaceOrientation) {
    UIDevice.current.setValue(value.rawValue, forKey: "orientation")
}

class SecondPacC: EZUIPacC{
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    var router: SecondPacR!
    
    func close() {
        print("close")
    }
    
    func initActions() {
        cActions.next = {[weak self] in self?.next()}
        cActions.back = {[weak self] in self?.back()}
    }
    
    func start() {
        print("C - start")
        
//        _ = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: {[weak self] _ in
//            self?.transit()
//        })
    }
    
    private func next(){
        pack?.instead.pack(SecondPac()).archive().transit()
    }
    private func back(){
//        pack?.rootWindow?.rootUIPac = nil
        pack?.back.transit()
    }
}

class SecondPacR: EZUIPacR{
    var color: Color = Color(uiColor: .init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1))
    @Published var count: Int = 0
    @Published var count1: Bool = false
    
    var cActions = CAction()
    struct CAction: EZUIPacActionProviderProtocol{
        var next = {}
        var back = {}
    }
    
    var vActions = VAction()
    struct VAction: EZUIPacActionProviderProtocol{
        
    }
}

class SecondPacV: EZUIPacV{
    var router: SecondPacR!
    
    func create() {
        createSelf()
    }
    
    private func createSelf(){
        backgroundColor = .init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
        
        let view = UIView.ezWrap {
            Text("Hello")
        }
        view.frame = bounds
        addSubview(view)
    }
}

class MyViewStates: ObservableObject{
    @Published var test: Int = 0
    @Published var isPortrait: Bool = true

    init(){
        
    }
}

struct SecondPacSV: EZUIPacSV{
    var supportedOrientations: UIInterfaceOrientationMask { .all }
    var router: SecondPacR!
    var viewStorage = MyViewStates()
    
    @Environment(\.colorScheme) var color
    @State var count: Int = 0

    func didRotate(oldOrientation: UIInterfaceOrientation, newOrientation: UIInterfaceOrientation) {
        viewStorage.isPortrait = newOrientation.isPortrait
    }
    
    func open() {
        viewStorage.isPortrait = stateStorage.currentOrientation?.isPortrait ?? true
    }

    var body: some View{
        ZStack {
            
            router.color
            Text("Данька Гей")
//            TestR(bool: viewStorage.isPortrait){
//                Spacer()
//                Button{
//                    cActions.next()
//                } label: {
//                    Text("Next")
//                }
//
//                Button{
//                    cActions.back()
//                } label: {
//                    Text("Back")
//                }
//                Spacer()
//        //                MyView(router: router).id(router.count1)
//                    //.onReceive(router.$count1, perform: {_ in})
//                //.update(count: router.count)
//                Button{
//                    stateStorage.pack?.rootWindow?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
//                } label: {
//                    Text("Test")
//                }
//                Button{
//                    router.count += 1
//                } label: {
//                    Text("\(router.count)")
//                }
//                Text(String("\(color)"))
//                TestView()
//                Spacer()
//            }
        }
        //.animation(.easeOut, value: 10)
        
    }
    

}

struct TestR<V: View>: View{
    var view: V
    var bool: Bool
    init(bool: Bool, @ViewBuilder view: () -> (V)){
        self.bool = bool
        self.view = view()
    }
    
    var body: some View{
        ZStack{
            if bool{
                VStack{
                    view.id(2)
                }.id(10)
            }else{
                HStack{
                    view.id(2)
                }.id(10)
            }
        }//.animation(.easeOut, value: bool)
    }
}

var couter: Int = 0
struct TestView: View{
//    @Environment(\.colorScheme) var color
    @State var value: Int = 0
    init(){
        print("upadte")
    }
    var body: some View{
        Button{
            value += 1
        } label: {
            Text("\(value)")
        }
    }
}
