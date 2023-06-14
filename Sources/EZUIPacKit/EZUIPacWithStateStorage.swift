//
//  File.swift
//  
//
//  Created by Александр Сенин on 02.06.2023.
//

import Foundation

public protocol EZUIPacWithStateStorage{
    var stateStorage: EZUIPacStateStorage { get set }
}

extension EZUIPacWithStateStorage where Self: EZUIPacWithRouterProtocol{
    public var stateStorage: EZUIPacStateStorage{
        _read { yield router.stateStorage }
        _modify { yield &router.stateStorage }
    }
}

