//
//  File.swift
//  
//
//  Created by Александр Сенин on 02.06.2023.
//

import Foundation
import SwiftUI

public struct EZUIPacStateStorage{
#if canImport(UIKit) || canImport(Cocoa)
    weak var _pack: (any EZUIPacProtocol)?
    public var pack: (any EZUIPacProtocol)? { _pack }
#endif
    
    public var currentOrientation: UIInterfaceOrientation?
    public internal(set) var isTransiting: Bool = false
    public internal(set) var isStarted: Bool = false
        
#if canImport(UIKit) || canImport(Cocoa)
    mutating func setup<Pack: EZUIPacProtocol>(_ pack: Pack){
        self._pack = pack
    }
#endif
}
