//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

public protocol EZObserverWrapperProtocol: Sendable{
    func use(action: @escaping () -> ())
}
