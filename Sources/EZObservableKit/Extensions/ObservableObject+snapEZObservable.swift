//
//  ObservableObject+snapEZObservable.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.02.2025.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ObservableObject{
    public func snapEZObservable(_ observers: [any EZObservableProtocol]){
        guard let objectWillChange = objectWillChange as? ObservableObjectPublisher else { return }
        observers.forEach {
            $0.unknownAddWithIsolation(isolation: MainActor.shared, wrapper: nil) {_ in
                objectWillChange.send()
            }.snapToObject(self)
        }
    }
    
    public func snapEZObservable(_ observers: any EZObservableProtocol...){
        snapEZObservable(observers)
    }
    
    public func snapEZObservable(){
        let mirror = Mirror(reflecting: self)
        snapEZObservable(
            mirror.children.compactMap{ $0.value as? (any EZObservableProtocol) }
        )
    }
}
#endif
