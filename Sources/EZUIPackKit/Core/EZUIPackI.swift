//
//  EZUIPackI.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation
import UIKit

extension EZUIPackWithMediatorIProtocol where Self: EZUIPackInteractorProtocol {
    public init(mediator: Mediator){
        self.init()
        self.access = mediator.accessI
    }
    
    public var transit: EZTransition<UIViewController> { access.packBridge.transit }
}

extension EZUIPackInteractorProtocol {
    public var packBridge: EZUIPackBridge {
        _read { yield access.packBridge }
    }
    
    public var storage: Mediator.Storage {
        _read { yield access.storage }
        nonmutating _modify { yield &access.storage }
    }
    
    public var parentShered: EZSharedStorage {
        _read { yield access.parentShered }
    }
    
    public var viewModel: Mediator.ViewModel {
        _read { yield access.viewModel }
        nonmutating _modify { yield &access.viewModel }
    }
    
    public var vActions: Mediator.ViewActionProvider {
        _read { yield access.vActions }
    }
}

@MainActor
public protocol EZUIPackInteractorProtocol: EZUIPackWithMediatorIProtocol {
    init()
    
    var keyCommands: [UIKeyCommand]? { get }
    
    func didInitialize()
    func setupActions() -> Mediator.InteractorActionProvider?
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
    public var pack: (any EZUIPackProtocol)? { access.packBridge.pack }
    
    public var keyCommands: [UIKeyCommand]? { nil }
    
    public func didInitialize(){}
    public func setupActions() -> Mediator.InteractorActionProvider? { nil }
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
