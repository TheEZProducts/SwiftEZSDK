//
//  UIViewController + ezParentShared.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    /// Access to shared storage from parent view controllers.
    ///
    /// Searches up the view controller hierarchy (parent or presenting view controllers)
    /// for view controllers that conform to `EZSharingProtocol` and returns their combined
    /// shared storage. Returns an empty storage if no parent provides shared data.
    ///
    /// ### Example
    /// ```swift
    /// // In a child pack mediator:
    /// func start() {
    ///     if let userID = ezParentShared[.userID] {
    ///         // Use parent's user ID
    ///     }
    /// }
    /// ```
    public var ezParentShared: EZSharedStorage {
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
