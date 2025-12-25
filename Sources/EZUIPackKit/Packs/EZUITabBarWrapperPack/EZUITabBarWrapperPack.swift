//
//  EZUITabBarWrapperPack.swift
//  EZSDK
//
//  Created by Александр Сенин on 23.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

public typealias EZUITabBarWrapperPack = EZUIPack<
    EZUITabBarWrapperPackI,
    EZUITabBarWrapperPackM,
    EZDummyUIPackV<EZUITabBarWrapperPackM>
>

extension UIViewController {
    public static func tabBarWrapper(_ controller: UIViewController) -> EZUITabBarWrapperPackI {
        tabBarWrapper([controller])
    }
    
    public static func tabBarWrapper(_ controllers: [UIViewController]) -> EZUITabBarWrapperPackI {
        EZUITabBarWrapperPack.make(controllers)
    }
}

extension EZUITabBarWrapperPack {
    public static func make(_ controllers: [UIViewController]) -> Interactor {
        let mediator = Mediator()
        mediator.storage.controllers = controllers
        return make(mediator)
    }
}

public class EZUITabBarWrapperPackI: EZUITabBarPackI {
    public var access: EZUITabBarWrapperPackM.AccessI!
    
    public func didInitialize() {
        guard let controllers = storage.controllers else { return }
        storage.controllers = nil
        transit.tabBarSet(controllers).unsafeTransition().transit()
    }
}

public class EZUITabBarWrapperPackM: EZUIPackMediator, EZUIPackMediatorProtocol {
    public var storage = Storage()
    public struct Storage {
        public var controllers: [UIViewController]?
    }
}
#endif
