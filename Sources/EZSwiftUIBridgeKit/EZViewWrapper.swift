//
//  File.swift
//  
//
//  Created by Александр Сенин on 04.06.2023.
//

#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(Combine)
import Combine
#endif
#if canImport(Cocoa)
import Cocoa
#endif

#if canImport(Combine)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
public class EZObservableObjectGroup: ObservableObject{
    public var objects: [any ObservableObject]
    public var keys = [AnyCancellable]()
    
    public convenience init(_ objects: (any ObservableObject)...){
        self.init(objects: objects)
    }
    public init(objects: [any ObservableObject]){
        self.objects = objects
        keys = objects.map{ addObserver(observObj: $0) }
    }
    
    private func addObserver<ObservObj: ObservableObject>(observObj: ObservObj) -> AnyCancellable{
        observObj.objectWillChange.sink{[weak self] _ in self?.objectWillChange.send()}
    }
}
#endif
 
#if canImport(UIKit) || canImport(Cocoa)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZView{
    public static func ezWrap<V: View, ObservObj: ObservableObject>(
        _ observable: ObservObj = EZViewWraperObservable(),
        view: V
    ) -> EZView{ .ezWrap(observable){_ in view} }
    
    public static func ezWrap<V: View, ObservObj: ObservableObject>(
        _ observable: ObservObj = EZViewWraperObservable(),
        @ViewBuilder view: @escaping ()->V
    ) -> EZView{ .ezWrap(observable){_ in view()} }
    
    public static func ezWrap<V: View, ObservObj: ObservableObject>(
        _ observable: ObservObj = EZViewWraperObservable(),
        @ViewBuilder view: @escaping (ObservObj)->V
    ) -> EZView{
        if #available(iOS 16.0, tvOS 16.0, *) {
#if canImport(UIKit)
            return UIHostingConfiguration{
                EZObserveView(observable, view)
                    .ignoresSafeArea()
            }
            .margins(.all, .zero)
            .makeContentView()
#elseif canImport(Cocoa)
            return NSHostingView(rootView: EZObserveView(observable, view))
#endif
        }else{
            let ezController = EZHostingController(rootView: EZObserveView(observable, view))
            
#if canImport(UIKit)
            ezController._disableSafeArea = true
            ezController.view?.backgroundColor = .clear
            let view = ezController.view ?? EZView()
#else
            let view = ezController.view
#endif
            ezController.view = EZView()
            return view
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
public class EZViewWraperObservable: ObservableObject{
    public func update(){ objectWillChange.send() }
    public init(){}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
struct EZObserveView<V: View, ObservObj: ObservableObject>: View {
    @ObservedObject var obj: ObservObj
    private var view: (ObservObj)->V?
    
    init(_ obj: ObservObj, _ view: @escaping (ObservObj)->V){
        self.view = view
        self.obj = obj
    }
    var body: some View {
        view(obj)
    }
}
#endif
