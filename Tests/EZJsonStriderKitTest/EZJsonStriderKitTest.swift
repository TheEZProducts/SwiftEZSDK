//
//  EZJsonKeysPluginTest.swift
//  
//
//  Created by Александр Сенин on 30.05.2023.
//

import XCTest
import EZJsonStriderKit

final class EZJsonStriderKitTest: XCTestCase {

    func test_Strider(){
        let keyStrider = KeyStrider(noWrite: MyJsonKey.hello)
        let strider = MyJsonStrider(
            url: getResourePath(MyJsonStrider.testJsonFileName)
        )
        
        XCTAssertEqual(
            strider[0].key.keyArreyJson[0].key(""),
            keyStrider[0].key.keyArreyJson[0].key.path()
        )
        XCTAssertEqual(
            strider[0].key.hello().string,
            keyStrider[0].key.hello.path()
        )
        XCTAssertEqual(
            strider[1].key.testInt().int,
            10
        )
        XCTAssertEqual(
            strider[1].key.doubleTest().double,
            1.2
        )
        XCTAssertEqual(
            strider[1].key.boolTestValue().bool,
            true
        )

        strider[1].key.testStringArr.forEach { i, strider in
            XCTAssertEqual(
                strider().string,
                keyStrider[1].key.testStringArr[i].path()
            )
        }
    }
    
    func test_StriderGroup(){
        let keyStrider = KeyStrider(noWrite: MyJsonKey.hello)
        let strider = MyJsonStrider(
            url: getResourePath(MyJsonStrider.testJsonFileName)
        )
        let striderDefault = MyJsonStrider(
            url: getResourePath(MyJsonStrider.testJsonDefaultFileName)
        )
        let groupStrider = EZJsonStriderGroup([strider, striderDefault])
        
        XCTAssertEqual(
            groupStrider[0].key.keyArreyJson[0].key(""),
            keyStrider[0].key.keyArreyJson[0].key.path()
        )
        XCTAssertEqual(
            groupStrider[1].key.testInt().int,
            10
        )
        XCTAssertEqual(
            groupStrider[1].key.testDefault(""),
            keyStrider[1].key.testDefault.path()
        )
        XCTAssertEqual(
            groupStrider[2].key.testDefault(""),
            keyStrider[2].key.testDefault.path()
        )
        
        var maxI = 0
        groupStrider.forEach { i, _ in
            maxI = i
            XCTAssertNotEqual(i, 2)
        }
        XCTAssertEqual(maxI, 1)
        
        XCTAssertEqual(groupStrider().count, 2)
        XCTAssertEqual(groupStrider(at: 1).count, 3)
    }

}

@dynamicMemberLookup
struct KeyStrider<Key: EZJsonKeyProtocol>{
    private var _path: String
    private var _lastKey: Key
    
    func path() -> String { _path }
    func lastKey() -> Key { _lastKey }
    
    init(noWrite key: Key){
        _path = ""
        _lastKey = key
    }
    init(path: String = "", key: Key){
        self._path = "\(path)/\(key.rawValue)"
        self._lastKey = key
    }
    init(path: String = "", key: Int, lastKey: Key){
        self._path = "\(path)/\(key)"
        self._lastKey = lastKey
    }
    
    subscript(dynamicMember key: KeyPath<Key, Key>) -> Self{
        .init(path: _path, key: _lastKey[keyPath: key])
    }
    
    subscript(key: Int) -> Self{
        .init(path: _path, key: key, lastKey: _lastKey)
    }
}

func getResourePath(_ name: String) -> URL{
    let thisSourceFile: URL
    if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
        thisSourceFile = URL(filePath: #file)
    } else {
        thisSourceFile = URL(fileURLWithPath: #file)
    }
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    return thisDirectory
        .appendingPathComponent("Resources")
        .appendingPathComponent(name)
}
