//
//  File.swift
//  
//
//  Created by Александр Сенин on 02.06.2023.
//

import Foundation

public protocol EZUIPacRouterProtocol: AnyObject{
    var stateStorage: EZUIPacStateStorage { get set }
    init()
}

public protocol EZUIPacActionProviderProtocol{}
public protocol EZUIPacRouterWithActionProviders: EZUIPacRouterProtocol{
    associatedtype ControllerActionProvider: EZUIPacActionProviderProtocol
    associatedtype ViewActionProvider: EZUIPacActionProviderProtocol
    
    var cActions: ControllerActionProvider { get set }
    var vActions: ViewActionProvider { get set }
}


open class EZUIPacRouter: EZUIPacRouterProtocol{
    public var stateStorage = EZUIPacStateStorage()
    public required init(){}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPacRouter: ObservableObject{}


public typealias EZUIPacRProtocol = EZUIPacRouterProtocol
public typealias EZUIPacR = EZUIPacRouter & EZUIPacRouterWithActionProviders


