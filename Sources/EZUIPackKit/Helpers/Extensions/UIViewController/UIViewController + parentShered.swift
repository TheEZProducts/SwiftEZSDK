//
//  UIViewController + parentShered.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    public var parentShered: EZSharedStorage {
        checkShared(ezSourceViewController) ?? .init()
    }
    
    private func checkShared(_ vc: UIViewController?) -> EZSharedStorage?{
        guard let vc = vc else {return nil}
        var shared = (vc as? EZSharingProtocol)?.shared
        if let superShared = checkShared(vc.ezSourceViewController){ shared = superShared + shared }
        return shared
    }
}

#endif
