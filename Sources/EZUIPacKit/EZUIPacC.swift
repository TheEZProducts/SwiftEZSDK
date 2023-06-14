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

#if canImport(UIKit)
public typealias EZViewController = UIViewController
#elseif canImport(Cocoa)
public typealias EZViewController = NSViewController
#endif

#if canImport(UIKit) || canImport(Cocoa)
//MARK: - Controller
extension EZUIPacWithRouterProtocol where Self: EZViewController{
    public init(router: Router){
        self.init(nibName: nil, bundle: nil)
        self.router = router
    }
}
public protocol EZUIPacControllerProtocol: EZViewController, EZUIPacWithStateStorage, EZUIPacWithRouterProtocol{
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


