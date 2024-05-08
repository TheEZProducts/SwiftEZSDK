//
//  File.swift
//  
//
//  Created by Александр Сенин on 12.11.2023.
//

import Foundation
import UIKit

public protocol EZTransitionConfigProtocol{
    
}

extension EZTransitionConfigProtocol{
    static func `in`(
        _ fromPack: any EZUIPacProtocol,
        to pack: any EZUIPacProtocol
    ) -> Self where Self == EZInTransitionConfig {
        .init(_fromPack: fromPack, _toPack: pack)
    }
}

public struct EZInTransitionConfig: EZTransitionConfigProtocol{
#if canImport(UIKit) || canImport(Cocoa)
    var _fromPack: any EZUIPacProtocol
    var _toPack: any EZUIPacProtocol
    var _container: EZView?
#endif
    
    
}

public struct EZTransition1<Config: EZTransitionConfigProtocol, Return>{
    private(set) var config: Config
    private(set) var returnValue: Return
    
    init(config: Config, returnValue: Return) {
        self.config = config
        self.returnValue = returnValue
    }

}

extension EZTransition1 where Config == EZInTransitionConfig{
    init(config: Config) where Return == any EZUIPacProtocol {
        self.config = config
        self.returnValue = config._toPack
    }
    
    @MainActor
    static func `in`(
        _ fromPack: any EZUIPacProtocol,
        to pack: any EZUIPacProtocol
    ) -> Self where Return == any EZUIPacProtocol{
        .init(config: .init(_fromPack: fromPack, _toPack: pack))
    }
    
    @MainActor
    static func `in`(
        _ fromPack: any EZUIPacProtocol,
        to pack: Return
    ) -> Self where Return: EZUIPacProtocol {
        .init(config: .init(_fromPack: fromPack, _toPack: pack), returnValue: pack)
    }
    
//    public func from<From: EZUIPacProtocol, To: EZUIPacProtocol>(
//        _ pack: From
//    ) -> Self where Config == EZInTransitionConfig<From, To>{
//        var new = config
//        new._fromPack = pack
//        return .init(config: new)
//    }
//    public func pack(_ pack: (any EZUIPacProtocol)? = nil) -> Self{
//        var new = config
//        new._toPack = pack
//        return .init(config: new)
//    }
    
    public func container(_ view: EZView) -> Self{
        var new = config
        new._container = view
        return .init(config: new, returnValue: returnValue)
    }
    
    public func transit() -> Return?{
        return returnValue
    }
}

@MainActor func test(){
    let a: any EZUIPacProtocol = TestPack()
    EZTransition1.in(TestPack(), to: a)
}

typealias TestPack = EZUIPac<TestC, TestR, TestV>

class TestC: EZUIPacC{
    var router: TestR!
}

class TestR: EZUIPacRouter{
    
    
    
}

class TestV: EZUIPacV{
    var supportedOrientations: UIInterfaceOrientationMask { .portrait }
    
    var router: TestR!
}
