//
//  AttributeValue.swift
//  Examples
//
//  Created by Александр Сенин on 01.08.2024.
//

#if !os(iOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)
import Foundation
import RegexBuilder

enum AttributeValue{
    case value(String)
    case keyedValue(key: String, value: String)
    
    var value: String{
        switch self {
            case .value(let value): value
            case .keyedValue(_, let value): value
        }
    }
    
    var raw: String {
        switch self {
            case .value(let value): value
            case .keyedValue(let key, let value): "\(key): \(value)"
        }
    }
    
    @available(macOS 13.0, *)
    static func getAttributeValues(attribute: String) throws -> [Self]{
        guard
            let attribut = attribute
                .cleanWhitespace()
                .firstMatch(of: .parenthesesContent)
        else {return []}
        
        return attribut.output.1
            .components(separatedBy: ",")
            .compactMap{
                let comp = $0.components(separatedBy: ":")
                guard let key = comp.first, let value = comp.last else { return nil }
                if key == value{
                    return .value(key)
                }else{
                    return .keyedValue(key: key, value: value)
                }
            }
    }
}
#endif



