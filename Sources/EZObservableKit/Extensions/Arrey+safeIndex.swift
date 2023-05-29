//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

extension Array{
    subscript(safe index: Int) -> Element?{
        indices.contains(index) ? self[index] : nil
    }
}
