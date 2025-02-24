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
    public func snapEZObservable(_ observers: [EZObservableProtocol]){
        observers.forEach {
            $0.unknownAdd(wrapper: nil) {[weak self] _ in
                (self?.objectWillChange as? ObservableObjectPublisher)?.send()
            }.snapToObject(self)
        }
    }
    
    public func snapEZObservable(_ observers: EZObservableProtocol...){
        snapEZObservable(observers)
    }
}
#endif
