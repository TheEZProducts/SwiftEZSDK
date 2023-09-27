//
//  EZUIViewWraper.swift
//  RelizApp
//
//  Created by Александр Сенин on 16.11.2020.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
public struct EZUIViewWrapper<V: EZView>: EZViewRepresentable{
    var view: V
    var update: (V) -> ()
    public init(_ init: () -> V, _ update: @escaping (V) -> () = {_ in}){
        self.init(`init`(), update)
    }
    public init(_ view: V, _ update: @escaping (V) -> ()){
        self.view = view
        self.update = update
        update(view)
    }
#if canImport(UIKit)
    public func makeUIView(context: Context) -> V { view }
    public func updateUIView(_ uiView: V, context: Context) { update(uiView) }
#elseif canImport(Cocoa)
    public func makeNSView(context: Context) -> V { view }
    public func updateNSView(_ nsView: V, context: Context) { update(nsView) }
#endif
}
