//
//  File.swift
//  
//
//  Created by Александр Сенин on 01.06.2023.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif


#if canImport(UIKit) || canImport(Cocoa)
//MARK: - Controller
extension EZUIPacWithRouterProtocol where Self == EZUIPacControllerProtocol{
    public init(router: Router){
        self.init()
        self.router = router
    }
}

public protocol EZUIPacBaseControllerProtocol{}
public protocol EZUIPacControllerProtocol:
    EZViewController,
    EZUIPacBaseControllerProtocol,
    EZUIPacWithStateStorage,
    EZUIPacWithRouterProtocol
{
    init()
    
    func initActions()
    func start()
    func didCreate()
    func open()
    func completedOpen()
    func close()
    func completedClose()
}
extension EZUIPacControllerProtocol{
    public var pack: (any EZUIPacProtocol)? { stateStorage.pack }
    
    public func initActions(){}
    public func start(){}
    public func didCreate(){}
    public func open(){}
    public func completedOpen(){}
    public func close(){}
    public func completedClose(){}
}

public typealias EZUIPacC = EZViewController & EZUIPacControllerProtocol
#endif


