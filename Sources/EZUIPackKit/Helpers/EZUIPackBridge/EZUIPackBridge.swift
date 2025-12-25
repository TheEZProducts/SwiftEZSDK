//
//  EZUIPackBridge.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

@MainActor
open class EZUIPackBridge {
    public weak var pack: (any EZUIPackProtocol)?
    
    public init(pack: (any EZUIPackProtocol)? = nil) {
        self.pack = pack
    }
}

#endif
