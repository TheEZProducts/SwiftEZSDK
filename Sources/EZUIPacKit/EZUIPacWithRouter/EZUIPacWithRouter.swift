//
//  File.swift
//  
//
//  Created by Александр Сенин on 02.06.2023.
//

//import Foundation
//
//public protocol EZUIPacWithRouterProtocol{
//    associatedtype Router: EZUIPacRouterProtocol
//    func getRouter() -> Router
//    init(router: Router)
//}
//
//public extension EZUIPacWithRouterProtocol where Self: EZUIPacWithOptionalRouterProtocol{
//    func getRouter() -> Router {router}
//}
//public extension EZUIPacWithRouterProtocol where Self: EZUIPacWithNoOptionalRouterProtocol{
//    func getRouter() -> Router {router}
//}
//
//public typealias EZUIPacWithORouterProtocol = EZUIPacWithRouterProtocol & EZUIPacWithOptionalRouterProtocol
//public protocol EZUIPacWithOptionalRouterProtocol{
//    associatedtype Router: EZUIPacRouterProtocol
//    var router: Router! { get set }
//}
//
//public typealias EZUIPacWithNORouterProtocol = EZUIPacWithRouterProtocol & EZUIPacWithNoOptionalRouterProtocol
//public protocol EZUIPacWithNoOptionalRouterProtocol{
//    associatedtype Router: EZUIPacRouterProtocol
//    var router: Router { get }
//}
//
//extension EZUIPacWithRouterProtocol where Router: EZUIPacRouterWithActionProviders{
//    public var cActions: Router.ControllerActionProvider {
//        _read { yield getRouter().cActions }
//        nonmutating _modify { yield &getRouter().cActions }
//    }
//    public var vActions: Router.ViewActionProvider {
//        _read { yield getRouter().vActions }
//        nonmutating _modify { yield &getRouter().vActions }
//    }
//}
//
//extension EZUIPacWithRouterProtocol{
//    public var router: EZUIPacRouter! {
//        get{ EZUIPacRouter() }
//        set{}
//    }
//}

import Foundation

public protocol EZUIPacWithRouterProtocol{
    associatedtype Router: EZUIPacRouterProtocol
    var router: Router! { get set }
    init(router: Router)
}

extension EZUIPacWithRouterProtocol where Router: EZUIPacRouterWithActionProviders{
    public var cActions: Router.ControllerActionProvider {
        _read { yield router.cActions }
        nonmutating _modify { yield &router.cActions }
    }
    public var vActions: Router.ViewActionProvider {
        _read { yield router.vActions }
        nonmutating _modify { yield &router.vActions }
    }
}

extension EZUIPacWithRouterProtocol{
    public var router: EZUIPacRouter! {
        get{ EZUIPacRouter() }
        set{}
    }
}
