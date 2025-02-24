//
//  EZUIPackM.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

import Foundation

@MainActor
public protocol EZUIPackMediatorProtocol: AnyObject, EZSharingProtocol{
    var packBridge: EZUIPackBridge { get set }
    
    func didInitialize()
    
    init()
}

extension EZUIPackMediatorProtocol{
    public var shared: EZSharedStorage? { nil }
    public var parentShered: EZSharedStorage {
        packBridge.pack?.parentShered ?? .init()
    }
    
    public func didInitialize() {}
}

public protocol EZUIPackActionProviderProtocol{
    associatedtype Provider: EZUIPackActionProviderProtocol = Self
    
    var provider: Provider { get set }
}

extension EZUIPackActionProviderProtocol where Provider == Self{
    public var provider: Provider {
        _read{ yield self }
        _modify { yield &self }
    }
}

public protocol EZUIPackMediatorWithActionProviders: EZUIPackMediatorProtocol{
    associatedtype InteractorActionProvider: EZUIPackActionProviderProtocol
    associatedtype ViewActionProvider: EZUIPackActionProviderProtocol
    
    var iActions: InteractorActionProvider { get set }
    var vActions: ViewActionProvider { get set }
}

@MainActor
public protocol EZUIPackWithMediatorProtocol{
    associatedtype Mediator: EZUIPackMediatorProtocol
    var mediator: Mediator! { get set }
    init(mediator: Mediator)
}

extension EZUIPackWithMediatorProtocol{
    public var packBridge: EZUIPackBridge {
        _read{ yield mediator.packBridge }
    }
    
    public var parentShered: EZSharedStorage {
        _read{ yield mediator.parentShered }
    }
}

@MainActor
open class EZUIPackMediator{
    
    @MainActor
    required public init(){}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPackMediator: ObservableObject{}

public typealias EZUIPackM = EZUIPackMediatorProtocol & EZUIPackMediatorWithActionProviders & EZUIPackMediator

