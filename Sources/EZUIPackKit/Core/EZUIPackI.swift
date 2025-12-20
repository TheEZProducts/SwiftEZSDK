//
//  EZUIPackI.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation
import UIKit

extension EZUIPackWithMediatorProtocol where Self: EZUIPackInteractorProtocol{
    public init(mediator: Mediator){
        self.init()
        self.mediator = mediator
    }
    
    public var transit: EZTransition<UIViewController> { packBridge.transit }
}

extension EZUIPackInteractorProtocol where Mediator: EZUIPackMediatorWithActionProviders{
    public var iActions: Mediator.InteractorActionProvider.Provider {
        _read{ yield mediator.iActions.provider }
        nonmutating _modify { yield &mediator.iActions.provider }
    }
    public var vActions: Mediator.ViewActionProvider.Provider  {
        _read{ yield mediator.vActions.provider }
    }
}

@MainActor
public protocol EZUIPackInteractorProtocol: EZUIPackWithMediatorProtocol{
    init()
    
    var keyCommands: [UIKeyCommand]? { get }
    
    func didInitialize()
    func setupActions()
    func start()
    func didCreate()
    func willOpen()
    func didOpen()
    func didInstall()
    func willClose()
    func didClose()

    
    func viewDidLoad()
    func viewWillAppear(_ animated: Bool)
    @available(iOS 13.0, tvOS 13.0, *)
    func viewIsAppearing(_ animated: Bool)
    func viewDidAppear(_ animated: Bool)
    func viewWillDisappear(_ animated: Bool)
    func viewDidDisappear(_ animated: Bool)
}

extension EZUIPackInteractorProtocol {
    public var pack: (any EZUIPackProtocol)? { mediator.packBridge.pack }
    
    public var keyCommands: [UIKeyCommand]? { nil }
    
    public func didInitialize(){}
    public func setupActions(){}
    public func start(){}
    public func didCreate(){}
    public func willOpen(){}
    public func didOpen(){}
    public func didInstall(){}
    public func willClose(){}
    public func didClose(){}
    
    
    public func viewDidLoad(){}
    public func viewWillAppear(_ animated: Bool){}
    @available(iOS 13.0, tvOS 13.0, *)
    public func viewIsAppearing(_ animated: Bool){}
    public func viewDidAppear(_ animated: Bool){}
    public func viewWillDisappear(_ animated: Bool){}
    public func viewDidDisappear(_ animated: Bool){}
}

public typealias EZUIPackI = EZUIPackInteractorProtocol

#endif
