//
//  EZUINavigationWrapperPack.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

public typealias EZUINavigationWrapperPack = EZUIPack<
    EZUINavigationWrapperPackI,
    EZUINavigationWrapperPackM,
    EZDummyUIPackV<EZUINavigationWrapperPackM>
>

extension UIViewController {
    public static func navigationWrapper(_ controller: UIViewController) -> EZUINavigationWrapperPackI {
        navigationWrapper([controller])
    }
    
    public static func navigationWrapper(_ controllers: [UIViewController]) -> EZUINavigationWrapperPackI {
        EZUINavigationWrapperPack.make(controllers)
    }
}

extension EZUINavigationWrapperPack {
    public static func make(_ controllers: [UIViewController]) -> Interactor {
        let mediator = Mediator()
        mediator.storage.controllers = controllers
        return make(mediator)
    }
}

public class EZUINavigationWrapperPackI: EZUINavigationPackI {
    public var access: EZUINavigationWrapperPackM.AccessI!
    
    public func didInitialize() {
        guard let controllers = storage.controllers else { return }
        storage.controllers = nil
        transit.navigationSet(controllers).unsafeTransition().transit()
    }
}

public class EZUINavigationWrapperPackM: EZUIPackMediator, EZUIPackMediatorProtocol{
    public var storage = Storage()
    public struct Storage {
        public var controllers: [UIViewController]?
    }
}
#endif
