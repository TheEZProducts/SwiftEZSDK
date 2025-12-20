//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

struct EZObserverAction<Value>: Sendable {
    let action: @Sendable (EZObserverValue<Value>) -> ()
    func use(value: EZObserverValue<Value>){
        if let wrapper = value.wrapper {
            wrapper.use { action(value) }
        }else{
            action(value)
        }
    }
}

