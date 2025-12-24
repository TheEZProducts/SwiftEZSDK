//
//  Regexes.swift
//  Examples
//
//  Created by Александр Сенин on 02.08.2024.
//

#if !os(iOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)
import Foundation
import RegexBuilder

@available(macOS 13.0, *)
extension RegexComponent where Self == Regex<(Substring, Substring)>{
    static var parenthesesContent: Self {
        RegexLib.parenthesesContent
    }
    
    static var typeContent: Self {
        RegexLib.typeContent
    }
    
    static var parenthesesStringContent: Self {
        RegexLib.parenthesesStringContent
    }
    
    static var propperyNameContent: Self {
        RegexLib.propperyNameContent
    }
    
    static var lib: RegexLib.Type { RegexLib.self }
}

@available(macOS 13.0, *)
extension RegexComponent where Self == Regex<(Substring)>{
    static var commentContent: Self {
        RegexLib.commentContent
    }
    
    static var lineCommentContent: Self {
        RegexLib.lineCommentContent
    }
    
    static var multiLineCommentContent: Self {
        RegexLib.multiLineCommentContent
    }
}

@available(macOS 13.0, *)
struct RegexLib {
    static var commentContent: Regex<(Substring)> {
        Regex{
            ChoiceOf {
                lineCommentContent
                multiLineCommentContent
            }
        }
    }
    
    static var lineCommentContent: Regex<(Substring)> {
        Regex{
            "//"
            ZeroOrMore(.any, .reluctant)
            Anchor.endOfLine
        }
    }
    
    static var multiLineCommentContent: Regex<(Substring)> {
        Regex{
            "/*"
            ZeroOrMore(.any, .reluctant)
            "*/"
        }
    }
    
    static var typeContent: Regex<(Substring, Substring)> {
        betweenСontext(from: "<", to: ">")
    }
    
    static var parenthesesContent: Regex<(Substring, Substring)> {
        betweenСontext(from: "(", to: ")")
    }
    
    static var parenthesesStringContent: Regex<(Substring, Substring)> {
        betweenСontext(from: "(\"", to: "\")")
    }
    
    static var propperyNameContent: Regex<(Substring, Substring)> {
        betweenOrСontext(from: { "var"; "let" }, to: { "="; ":" })
    }
    
    
    static func betweenСontext(from: String, to: String) -> Regex<(Substring, Substring)> {
        betweenСontext(from: { from }, to: { to })
    }
    static func betweenOrСontext<R, R1>(
        @AlternationBuilder from: () -> ChoiceOf<R>,
        @AlternationBuilder to: () -> ChoiceOf<R1>
    ) -> Regex<(Substring, Substring)>{
        betweenСontext(from: { from() }, to: { to() })
    }
    static func betweenСontext(
        @RegexComponentBuilder from: () -> some RegexComponent,
        @RegexComponentBuilder to: () -> some RegexComponent
    ) -> Regex<(Substring, Substring)>{
        Regex {
            from()
            Capture {
                ZeroOrMore(.any, .eager)
            }
            to()
        }
    }
}

// MARK: - Swift declaration extraction (var/let [modifiers] name : Type = value)

@available(macOS 13.0, *)
extension RegexLib {
    /// Extracts declaration parts but splits modifier tokens into:
    /// - `modifiers`: non-access modifiers (e.g. `static`, `lazy`, `unowned(safe)`)
    /// - `accessModifiers`: plain access modifiers without `(set)` (e.g. `public`, `internal`)
    /// - `setterRestrictedAccess`: first `X(set)` access modifier if present (e.g. `private(set)`)
    static func extractSwiftDeclPartsSeparated(from decl: String) -> (
        modifiers: [String],
        accessModifiers: [String],
        setterRestrictedAccess: String?,
        name: String,
        type: String?,
        value: String?
    )? {
        guard let m = decl.firstMatch(of: SwiftDecl.regex) else { return nil }

        let modifiersStr = m[SwiftDecl.modifiersRef] ?? ""
        let allTokens = tokenizeSwiftModifierTokens(from: modifiersStr)
        let split = splitAccessTokens(allTokens)

        let name = m[SwiftDecl.nameRef]
        let type = m[SwiftDecl.typeRef].flatMap { $0.isEmpty ? nil : $0 }
        let value = m[SwiftDecl.valueRef].flatMap { $0.isEmpty ? nil : $0 }

        return (
            modifiers: split.other,
            accessModifiers: split.access,
            setterRestrictedAccess: split.setterRestricted,
            name: name,
            type: type,
            value: value
        )
    }

    /// Tokenizes the captured modifier prefix using the same `modifierToken` regex.
    ///
    /// Why: splitting by whitespace breaks cases like `private ( set )`.
    static func tokenizeSwiftModifierTokens(from modifiersPrefix: String) -> [String] {
        guard !modifiersPrefix.isEmpty else { return [] }

        return modifiersPrefix
            .matches(of: SwiftDecl.modifierToken)
            .map { match in
                normalizeModifierToken(String(match.0))
            }
    }

    /// Splits modifier tokens into non-access, access (without set), and the first `X(set)`.
    private static func splitAccessTokens(_ tokens: [String]) -> (other: [String], access: [String], setterRestricted: String?) {
        var other: [String] = []
        var access: [String] = []
        var setterRestricted: String? = nil

        for t in tokens {
            if setterRestricted == nil, t.wholeMatch(of: SwiftDecl.setterRestrictedAccessModifier) != nil {
                setterRestricted = t
                continue
            }
            if t.wholeMatch(of: SwiftDecl.plainAccessModifier) != nil {
                access.append(t)
                continue
            }
            other.append(t)
        }

        return (other: other, access: access, setterRestricted: setterRestricted)
    }

    /// Normalizes tokens like `private ( set )` -> `private(set)` and `unowned ( safe )` -> `unowned(safe)`.
    private static func normalizeModifierToken(_ token: String) -> String {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("(") else { return trimmed }

        // remove any whitespace/newlines inside paren-style modifiers
        return trimmed.filter { !$0.isWhitespace && !$0.isNewline }
    }
}

@available(macOS 13.0, *)
extension Reference: @retroactive @unchecked Sendable {}

@available(macOS 13.0, *)
extension ZeroOrMore: @retroactive @unchecked Sendable {}

@available(macOS 13.0, *)
extension Regex: @retroactive @unchecked Sendable {}

@available(macOS 13.0, *)
extension OneOrMore: @retroactive @unchecked Sendable {}

@available(macOS 13.0, *)
extension ChoiceOf: @retroactive @unchecked Sendable {}

@available(macOS 13.0, *)
private enum SwiftDecl {
    static let modifiersRef = Reference(String?.self)
    static let nameRef      = Reference(String.self)
    static let typeRef      = Reference(String?.self)
    static let valueRef     = Reference(String?.self)

    // spaces/tabs only (no newlines)
    static let sp = ZeroOrMore { CharacterClass(.whitespace) }

    // whitespace OR newline
    static let wsn = Regex {
        ChoiceOf {
            CharacterClass(.whitespace)
            CharacterClass(.newlineSequence)
        }
    }

    static let ws  = ZeroOrMore { wsn }
    static let ws1 = OneOrMore { wsn }

    // Approximation for Swift identifiers (Unicode XID_Start / XID_Continue)
    static let xidStart = try! Regex(#"\p{XID_Start}"#)
    static let xidCont  = try! Regex(#"\p{XID_Continue}"#)

    static let identifier = Regex {
        ChoiceOf {
            // `backtickedIdentifier`
            Regex {
                "`"
                OneOrMore {
                    NegativeLookahead { "`" }
                    CharacterClass.any
                }
                "`"
            }

            // regular identifier (approx)
            Regex {
                ChoiceOf { xidStart; "_" }
                ZeroOrMore { ChoiceOf { xidCont; "_" } }
            }
        }
    }

    static let dottedIdentifier = Regex {
        identifier
        ZeroOrMore {
            "."
            identifier
        }
    }

    // Heuristic attribute: @Name or @Name(...) (paren content is not fully Swift-parsed)
    static let attribute = Regex {
        "@"
        dottedIdentifier
        Optionally {
            "("
            ZeroOrMore(.any, .reluctant)
            ")"
        }
    }

    static let accessModifier = Regex {
        ChoiceOf { "private"; "fileprivate"; "internal"; "public"; "open"; "package" }
        Optionally {
            sp
            "("
            sp
            "set"
            sp
            ")"
        }
    }

    /// Matches only `X(set)` access modifiers (allowing whitespace), e.g. `private(set)` or `private ( set )`.
    static var setterRestrictedAccessModifier: Regex<Substring> {
        Regex {
            ChoiceOf { "private"; "fileprivate"; "internal"; "public"; "open"; "package" }
            ZeroOrMore { CharacterClass(.whitespace) }
            "("
            ZeroOrMore { CharacterClass(.whitespace) }
            "set"
            ZeroOrMore { CharacterClass(.whitespace) }
            ")"
        }
    }

    /// Matches only plain access modifiers (no `(set)`), e.g. `public`, `internal`.
    static var plainAccessModifier: Regex<Substring> {
        Regex {
            ChoiceOf { "private"; "fileprivate"; "internal"; "public"; "open"; "package" }
        }
    }

    static let unownedModifier = Regex {
        ChoiceOf { "unowned"; "nonisolated" }
        Optionally {
            sp
            "("
            sp
            ChoiceOf { "safe"; "unsafe" }
            sp
            ")"
        }
    }

    static let otherModifier = ChoiceOf {
        "static"
        "class"
        "lazy"
    }

    static var modifierToken: Regex<Substring> {
        Regex {
            ChoiceOf {
                accessModifier
                unownedModifier
                otherModifier
            }
        }
    }

    // Body for explicit type: read until (optional whitespace) '=' or '{' (computed property) or end.
    static let typeBody = OneOrMore {
        // stop before "=" or "{" with/without whitespace
        NegativeLookahead { ws; ChoiceOf { "="; "{" } }
        NegativeLookahead { ChoiceOf { "="; "{" } }
        NegativeLookahead { Anchor.endOfSubject }
        CharacterClass.any
    }

    static let regex = Regex {
        ws

        // leading attributes like @EZTestMacro(...)
        ZeroOrMore {
            attribute
            ws1
        }

        // capture modifiers that appear before var/let
        Capture(as: modifiersRef) {
            ZeroOrMore {
                modifierToken
                ws1
            }
        } transform: { raw in
            let s = String(raw).trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : s
        }

        ChoiceOf { "var"; "let" }
        ws1

        // name
        Capture(as: nameRef) {
            identifier
        } transform: { raw in
            var s = String(raw)
            if s.hasPrefix("`"), s.hasSuffix("`"), s.count >= 2 {
                s.removeFirst()
                s.removeLast()
            }
            return s
        }

        ws

        // optional ": Type"
        Optionally {
            ":"
            ws
            Capture(as: typeRef) {
                typeBody
            } transform: { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            ws
        }

        // optional "= expr" OR computed-property body "{ ... }"
        Optionally {
            Capture(as: valueRef) {
                ChoiceOf {
                    Regex {
                        "="
                        ws
                        ZeroOrMore { CharacterClass.any }
                    }
                    Regex {
                        "{" 
                        ZeroOrMore { CharacterClass.any }
                    }
                }
            } transform: { raw in
                var s = String(raw).trimmingCharacters(in: .whitespacesAndNewlines)
                // drop leading '=' for initializers, keep '{' for computed properties
                if s.first == "=" {
                    s.removeFirst()
                    s = s.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return s
            }
        }

        ws
        Anchor.endOfSubject
    }
}
#endif
