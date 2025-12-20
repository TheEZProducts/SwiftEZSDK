//
//  StringExtension.swift
//  SavedCodable
//
//  Created by Александр Сенин on 03.08.2024.
//

#if !os(iOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)
import Foundation
import RegexBuilder

extension String{
    func cleanWhitespace() -> String{
        clean(" ","\n","\t")
    }
    
    func clean(_ symbols: String...) -> String{
        clean(symbols)
    }
    
    func clean(_ symbols: [String]) -> String{
        replacing(symbols.map{($0, "")})
    }
    
    func replacing(_ symbols: (from: String, to: String)...) -> String{
        replacing(symbols)
    }
    
    func replacing(_ symbols: [(from: String, to: String)]) -> String{
        var result = self
        symbols.forEach{
            result = result.replacingOccurrences(of: $0.from, with: $0.to)
        }
        return result
    }
    
    @available(macOS 13.0, *)
    func removeComments() -> String{
        var cleanedText = self
        while let match = cleanedText.firstMatch(of: .commentContent) {
            cleanedText.removeSubrange(match.range)
        }
        
        return cleanedText
    }
    
    @available(macOS 13.0, *)
    mutating func findAndRemove(of r: Regex<(Substring, Substring)>) -> (match: String, content: String)? {
        if let match = self.firstMatch(of: r) {
            self.removeSubrange(match.range)
            return (String(match.output.0), String(match.output.1))
        } else {
            return nil
        }
    }
}
#endif
