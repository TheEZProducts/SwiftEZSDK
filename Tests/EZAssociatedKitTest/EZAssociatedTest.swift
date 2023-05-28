//
//  EZAssociated.swift
//  
//
//  Created by Александр Сенин on 28.05.2023.
//

import XCTest
import EZAssociatedKit

class TargetObject{}

final class EZAssociatedTest: XCTestCase {

    func test_AssociateObject(){
        let object = TargetObject()
        let value = "Hello"
        
        let key = EZAssociated(object).set(value, .random, .OBJC_ASSOCIATION_RETAIN)!
        var savedValue: String? = EZAssociated(object).get(key)
        XCTAssertEqual(value, savedValue, "Set/Get Value Random")
        
        EZAssociated(object).set(nil, key, .OBJC_ASSOCIATION_RETAIN)
        savedValue = EZAssociated(object).get(key)
        XCTAssertNil(savedValue, "Remove Value")
        
        EZAssociated(object).set(value, .hashable("Key"), .OBJC_ASSOCIATION_RETAIN)
        savedValue = EZAssociated(object).get(.hashable("Key"))
        XCTAssertEqual(value, savedValue, "Set/Get Value Hashable")
        
        EZAssociated(object).set(value, .pointer(.init(bitPattern: 10)!), .OBJC_ASSOCIATION_RETAIN)
        savedValue = EZAssociated(object).get(.pointer(.init(bitPattern: 10)!))
        XCTAssertEqual(value, savedValue, "Set/Get Value Pointer")
    }

    func test_DeinitObserver(){
        var object: TargetObject? = TargetObject()
        var flag = false
        EZAssociated(object!).setDeinitObserver { flag = true }
        object = nil
        XCTAssert(flag, "Observer Worked")
        
        object = TargetObject()
        flag = false
        EZAssociated(object!).setDeinitObserver { flag = true }
        XCTAssert(!flag, "Observer No Worked")
    }
}
