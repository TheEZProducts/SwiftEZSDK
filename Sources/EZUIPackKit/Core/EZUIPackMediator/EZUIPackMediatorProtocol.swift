//
//  EZUIPackM.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

import EZHelpersKit

@MainActor
public protocol EZUIPackBaseMediatorProtocol: AnyObject {
    var packBridge: EZUIPackBridge { get set }
}

@MainActor
public protocol EZUIPackMediatorProtocol: EZUIPackBaseMediatorProtocol {
    //MARK: - Required Objects
    associatedtype ViewModel
    var viewModel: ViewModel { get set }
    
    associatedtype InputI
    var inputI: InputI { get }
    
    associatedtype InputV
    var inputV: InputV { get }
    
    //MARK: - Access
    typealias AccessI = EZMediatorAccessI<Self, AccessMapI>
    typealias AccessV = EZMediatorAccessV<Self, AccessMapV>
    
    associatedtype AccessMapI
    static var accessMapI: AccessMapI { get }
    
    associatedtype AccessMapV
    static var accessMapV: AccessMapV { get }
    
    func didInitialize()
    
    //MARK: - Init
    typealias BaseContextI = EZUIPackMediatorContextI<Self>
    associatedtype ContextI = BaseContextI
    
    typealias BaseContextV = EZUIPackMediatorContextV<Self>
    associatedtype ContextV = BaseContextV
    init(contextI: ContextI, contextV: ContextV)
}


extension EZUIPackMediatorProtocol {
    public var parentShered: EZSharedStorage {
        packBridge.pack?.interactor?.parentShered ?? .init()
    }
    
    public func didInitialize() {}
}

extension EZUIPackMediatorProtocol where ViewModel == Void {
    public var viewModel: ViewModel {
        set {}
        get { () }
    }
}

extension EZUIPackMediatorProtocol where InputI == Void {
    public var inputI: InputI { () }
}

extension EZUIPackMediatorProtocol where InputV == Void {
    public var inputV: InputV { () }
}


@MainActor
open class EZUIPackMediator: EZUIPackBaseMediatorProtocol {
    public var packBridge = EZUIPackBridge()
    
    public init(){}
}

public typealias EZUIPackM = EZUIPackMediatorProtocol & EZUIPackMediator

#endif
