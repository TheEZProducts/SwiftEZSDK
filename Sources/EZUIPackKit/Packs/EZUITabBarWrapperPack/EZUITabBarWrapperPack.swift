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

extension EZUITabBarWrapperPack{
    public convenience init(_ controllers: [UIViewController]){
        let mediator = Mediator()
        mediator.controllers = controllers
        self.init(mediator: mediator)
    }
}

public class EZUITabBarWrapperPackI: EZUIPackI{
    public var mediator: EZUITabBarWrapperPackM!
    
    public func didInitialize() {
        guard let controllers = mediator.controllers else { return }
        mediator.controllers = nil
        transit.tabBarSet(controllers).unsafeTransition().transit()
    }
    
    required public init(){}
}

public class EZUITabBarWrapperPackM: EZUIPackMediator, EZUIPackMediatorProtocol{
    public var packBridge = EZUIPackBridge()
    
    public var controllers: [UIViewController]?
}
#endif
