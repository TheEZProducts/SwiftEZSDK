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
    EZDummyUIPackM,
    EZDummyUIPackV<EZDummyUIPackM>
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
        return make(interactor: .init(controllers))
    }
}

public class EZUITabBarWrapperPackI: EZUITabBarPackI {
    public let access = EZDummyUIPackM.accessI
    
    public func makeContext() -> Mediator.ContextI {
        .init(actions: (), viewModel: ())
    }
    
     public init(_ controllers: [UIViewController]) {
         super.init(nibName: nil, bundle: nil)
         transit.tabBarSet(controllers).unsafeTransition().transit()
     }
     
     @MainActor required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
}

#endif
