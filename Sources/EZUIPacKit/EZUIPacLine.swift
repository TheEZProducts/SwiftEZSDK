//
//  File.swift
//  
//
//  Created by Александр Сенин on 13.06.2023.
//

import Foundation
import EZObservableKit

open class EZUIPacLine{
    open var rootPack: (any EZUIPacProtocol)?
    @EZObservable open var currentPack: any EZUIPacProtocol
    
    public init(_ pack: any EZUIPacProtocol, useRootPack: Bool = false) {
        self.currentPack = pack
        if useRootPack { rootPack = pack }
    }
    
    open func setPack(_ pack: any EZUIPacProtocol){
        currentPack = pack
        pack.line = self
    }
}
