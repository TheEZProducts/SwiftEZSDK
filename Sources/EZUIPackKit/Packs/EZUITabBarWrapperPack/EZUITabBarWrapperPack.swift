//
//  EZUITabBarWrapperPack.swift
//  EZSDK
//
//  Created by Александр Сенин on 23.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

public typealias EZUITabBarWrapperPack = EZUITabBarPack<
    EZUITabBarWrapperPackI,
    EZUITabBarWrapperPackM,
    EZDummyUIPackV<EZUITabBarWrapperPackM>
>

extension UIViewController{
    public static func tabBarWrapper(_ controller: UIViewController) -> EZUITabBarWrapperPack{
        .init([controller])
    }
    
    public static func tabBarWrapper(_ controllers: [UIViewController]) -> EZUITabBarWrapperPack{
        .init(controllers)
    }
}

extension EZUITabBarWrapperPack {
    public convenience init(_ controllers: [UIViewController]){
        let mediator = Mediator()
        mediator.storage.controllers = controllers
        self.init(mediator: mediator)
    }
}

public class EZUITabBarWrapperPackI: EZUIPackI {
    public var access: EZUITabBarWrapperPackM.AccessI!
    
    public func didInitialize() {
        guard let controllers = storage.controllers else { return }
        storage.controllers = nil
        transit.tabBarSet(controllers).unsafeTransition().transit()
    }
    
    required public init(){}
}

public class EZUITabBarWrapperPackM: EZUIPackMediator, EZUIPackMediatorProtocol {
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
