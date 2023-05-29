//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

public struct EZObserverAction<Value>: @unchecked Sendable{
    private(set) var action: (EZObserverValue<Value>) -> ()
    func use(value: EZObserverValue<Value>){
        if let wreapper = value.wreapper {
            wreapper.use { action(value) }
        }else{
            action(value)
        }
    }
}

