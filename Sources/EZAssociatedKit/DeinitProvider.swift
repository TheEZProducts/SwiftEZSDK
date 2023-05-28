//
//  File.swift
//  
//
//  Created by Александр Сенин on 28.05.2023.
//

import Foundation

class DeinitProvider{
    private var closure: () -> ()

    
    init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }
    
    deinit{ closure() }
}

