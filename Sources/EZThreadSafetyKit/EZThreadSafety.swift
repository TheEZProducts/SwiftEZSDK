//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

@propertyWrapper
public class EZThreadSafety<T>: @unchecked Sendable{
    private let semaphore = DispatchSemaphore(value: 1)
    private var value: T
    
    public var wrappedValue: T{
        set(value){
            semaphore.wait(); defer { semaphore.signal() }
            self.value = value
        }
        get{
            semaphore.wait(); defer { semaphore.signal() }
            return value
        }
    }
    
    public init(wrappedValue: T){
        semaphore.wait(); defer { semaphore.signal() }
        self.value = wrappedValue
    }
}
