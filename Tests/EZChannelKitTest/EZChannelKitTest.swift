//
//  EZChannelKitTest.swift
//  
//
//  Created by Александр Сенин on 30.05.2023.
//

import XCTest
import EZChannelKit
import EZThreadSafetyKit

final class EZChannelKitTest: XCTestCase {
    @available(watchOS 6.0, *)
    @available(tvOS 13.0.0, *)
    @available(iOS 13.0, *)
    func test_ChannelTest() async{
        print("start")
        
        let c = EZChannel<String>()
        
        for i in 0..<100{
            Task{
                for j in 0..<100{
                    c <- "\(i) \(j)"
                }
            }
        }
        
        await Task{
            var testBuffer: String = ""
            var counter = 0
            for await value in c{
                testBuffer = testBuffer + value
                counter += 1
                if counter >= 10000{ c <- .finish }
            }
        }.value
        print("end")
    }

}
