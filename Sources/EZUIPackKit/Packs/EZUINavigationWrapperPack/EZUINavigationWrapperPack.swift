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
    EZDummyUIPackM,
    EZDummyUIPackV<EZDummyUIPackM>
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
        make(interactor: .init(controllers))
    }
}

public class EZUINavigationWrapperPackI: EZUINavigationPackI {
    public let access = EZDummyUIPackM.accessI
    
    public func makeContext() -> Mediator.ContextI {
        .init(actions: (), viewModel: ())
    }
   
    public init(_ controllers: [UIViewController]) {
        super.init(nibName: nil, bundle: nil)
        transit.navigationSet(controllers).unsafeTransition().transit()
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
