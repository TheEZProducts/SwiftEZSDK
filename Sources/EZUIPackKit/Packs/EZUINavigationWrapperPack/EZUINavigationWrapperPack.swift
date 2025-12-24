//
//  EZUINavigationWrapperPack.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

public typealias EZUINavigationWrapperPack = EZUINavigationPack<
    EZUINavigationWrapperPackI,
    EZUINavigationWrapperPackM,
    EZDummyUIPackV<EZUINavigationWrapperPackM>
>

extension UIViewController{
    public static func navigationWrapper(_ controller: UIViewController) -> EZUINavigationWrapperPack{
        .init([controller])
    }
    
    public static func navigationWrapper(_ controllers: [UIViewController]) -> EZUINavigationWrapperPack{
        .init(controllers)
    }
}

extension EZUINavigationWrapperPack {
    public convenience init(_ controllers: [UIViewController]){
        let mediator = Mediator()
        mediator.storage.controllers = controllers
        self.init(mediator: mediator)
    }
}

public class EZUINavigationWrapperPackI: EZUIPackI {
    public var access: EZUINavigationWrapperPackM.AccessI!
    
    public func didInitialize() {
        guard let controllers = storage.controllers else { return }
        storage.controllers = nil
        transit.navigationSet(controllers).unsafeTransition().transit()
    }
    
    required public init(){}
}

public class EZUINavigationWrapperPackM: EZUIPackMediator, EZUIPackMediatorProtocol{
    public var packBridge = EZUIPackBridge()
    
    public var storage = Storage()
    public struct Storage {
        public var controllers: [UIViewController]?
    }
    
    
    public var viewModel: Void = ()
    public var iActions: Void = ()
    public var vActions: Void = ()
}
#endif
