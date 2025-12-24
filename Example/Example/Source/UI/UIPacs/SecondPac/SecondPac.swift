//
//  SecondPac.swift
//  Example
//
//  Created by Александр Сенин on 04.06.2023.
//

import UIKit
import EZUIPackKit
import EZSwiftUIBridgeKit
import EZObservableKit
import SwiftUI

typealias SecondPac = EZUIPack<SecondPacI, SecondPacM, SecondPacSV>

class SecondPacI: EZUIPackI{
    var access: SecondPacM.AccessI!
    
    func setupActions() -> SecondPacM.IAction? {
        var iActions = SecondPacM.IAction()
        iActions.next = {[weak self] in self?.next() }
        iActions.back = {[weak self] in self?.back() }
        iActions.close = {[weak self] in self?.close() }
        return iActions
    }
    
    func start() {
        print("C - start")
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {[weak self] _ in
            Task{@MainActor in
                self?.viewModel.count += 1
            }
        })
    }
    
    private func next(){
        print("next")
//        transit
////            .tabBarNext()
//            .navigationPush(SecondPac())
//            .animate()
////            .animation(.ezOpen)
//            .transit()
        
        transit
            .custom()
            .transitionType(.ezNext)
            .animate()
            .transit()
    }
    
    private func back(){
        print("back")
//        transit
//            .navigationPop()
////            .tabBarBack()
////            .animation(.ezClose)
////            .navigationPop()
//            .animate()
//            .transit()
        
        transit
            .custom()
            .transitionType(.ezBack)
            .animate()
            .transit()
    }
    
    private func close(){
        print("close")
        transit
            .custom()
            .transitionType(.ezClose)
            .animate()
            .transit()
    }
    
    required init(){}
}



class SecondPacM: EZUIPackM {
    var packBridge = EZUIPackBridge()
    
    var storage: Void = ()
    
    var viewModel = ViewModel()
    class ViewModel: ObservableObject {
        var color: Color = Color(uiColor: .init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1))
        @Published var count: Int = 0
        @Published var count1: Bool = false
    }
    
    var iActions = IAction()
    struct IAction {
        var next = {}
        var back = {}
        var close = {}
    }
    
    var vActions = VAction()
    struct VAction {
        var next = {}
    }
}

class SecondPacV: EZUIPackV{
    var supportedInterfaceOrientations: UIInterfaceOrientationMask? { .all }
    
    var access: SecondPacM.AccessV!
    
    func animateOpen() {
        print("aaaaa")
    }
    
    func create() {
        print("huh", frame,  UIView.inheritedAnimationDuration)
        createSelf()
    }
    
    func didOpen() {
        print("huh1", frame)
        print()
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
    var test1: Int = 0
    var placeTocken = PlaceTocken()
    init(){
        
    }
}

class SecondPacSV1: EZUIPackSUIV{
    var access: SecondPacM.AccessV!
    
    var viewStorage = MyViewStates()
    var additionalObservableObjects: [any ObservableObject] {[viewStorage]}
    
    var body: some View{
        ZStack{
            viewModel.color
            VStack{
                Button{[viewModel] in
                    viewModel.count += 1
                } label: {
                    Text("up")
                }
                Text("hello \(viewModel.count)")
                
                Button{[viewStorage] in
                    viewStorage.test += 1
                } label: {
                    Text("up 1")
                }
                Text("hello1 \(viewStorage.test)")
            }
        }
    }
}

struct SecondPacSV: EZUIPackSV {
    var supportedInterfaceOrientations: UIInterfaceOrientationMask? { .all }
    var access: SecondPacM.AccessV!
    
    @ObservedObject var viewStorage1 = MyViewStates()
    
    @Environment(\.colorScheme) var color
    @State var count: Int = 0
    
    func create() {
//        print("create", uiView?.bounds, parentShered[.mainPackMChain.test])
        print("huh", UIView.inheritedAnimationDuration)
    }
    
    func willOpen() {
        print("willOpen", uiView?.bounds)
    }
    
    func animateOpen() {
        print("animateOpen", uiView?.bounds)
        print("huh1", UIView.inheritedAnimationDuration)
    }
    
    func didOpen() {
        print("didOpen", uiView?.bounds)
    }
    
    func gsdg() -> Bool{
        return uiView?.isPortrait ?? false
    }
    
    var body: some View{
//        ContentView(content: "Test")
            
        ZStack {
            viewModel.color
            TestR(bool: gsdg()){
                Spacer()
            
                Button{
                    iActions.back()
                } label: {
                    Text("Back")
                }
                
                Button{
                    print("tut")
                    iActions.next()
                } label: {
                    Text("Next")
                }
                Spacer()
        //                MyView(router: router).id(router.count1)
                    //.onReceive(router.$count1, perform: {_ in})
                //.update(count: router.count)
                Button{
                    iActions.close()
                    //packBridge.pack?.rootWindow?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                } label: {
                    Text("Test")
                }
                Button{
                    viewStorage1.placeTocken.view = AnyView(ContentView(content: "Test"))
                } label: {
                    Text("Change Place")
                }
                Text(String("\(color)"))
                Button{
                    viewStorage1.test += 1
                } label: {
                    Text("\(viewStorage1.test)")
                }
                
                Button{
                    viewStorage1.test += 1
                } label: {
                    Text("\(viewStorage1.test)")
                }
//                ContentView(content: "Test")
                Place(viewStorage1.placeTocken)
                Spacer()


            }
        }
        //.animation(.easeOut, value: 10)
        
    }
    
    init(){}
}

struct TestR<V: View>: View{
    var view: V
    var bool: Bool
    init(bool: Bool, @ViewBuilder view: () -> (V)){
        self.bool = bool
        self.view = view()
    }
    
    var body: some View{
        
        (bool ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())){
            view.id(2)
        }//.animation(.easeOut, value: bool)
    }
}

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

class PlaceTocken: ObservableObject{
    @Published var view: AnyView?
}

struct Place: View{
    @ObservedObject var plaseTocken: PlaceTocken
    
    init(_ plaseTocken: PlaceTocken) {
        self.plaseTocken = plaseTocken
    }
    
    var body: some View{
        VStack{
            plaseTocken.view
        }
    }
}

struct ContentView: View {
    @State private var content: String = "Первый контент"
    
    init(content: String) {
        self.content = content
    }

    var body: some View {
        NavigationView {
            Text("Hello, World!")
        }
//        NavigationView {
//            VStack {
//                NavigationLink(destination: ContentView(content: content + "Next ")) {
//                    Text("Hello!")
//                }
//            }
//        }
    }
}
