//
//  EZPropertyWrapperMacro.swift
//  EZSDK
//
//  Created by Александр Сенин on 18.12.2025.
//

#if !os(iOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)
import Foundation

@available(macOS 13.0, *)
extension EZPropertyWrapperMacro {
    public struct Parameters: Sendable {
        let isConstant: Bool
        let isImmutable: Bool
        let isProjected: Bool
        
        init(isConstant: Bool = true, isImmutable: Bool = true, isProjected: Bool = true) {
            self.isConstant = isConstant
            self.isImmutable = isImmutable
            self.isProjected = isProjected
        }
        
        public static func make(parameters: String) -> Parameters {
            guard parameters.count >= 3 else { return .init() }
            let isConstant = parameters[parameters.index(parameters.startIndex, offsetBy: 0)] == "C"
            let isImmutable = parameters[parameters.index(parameters.startIndex, offsetBy: 1)] == "I"
            let isProjected = parameters[parameters.index(parameters.startIndex, offsetBy: 2)] == "P"
            return .init(
                isConstant: isConstant,
                isImmutable: isImmutable,
                isProjected: isProjected
            )
        }
    }
}

@available(macOS 13.0, *)
public struct EZPropertyWrapperMacro: AttachedMacro {
    private typealias DeclParts = (
        modifiers: [String],
        accessModifiers: [String],
        setterRestrictedAccess: String?,
        name: String,
        type: String?,
        value: String?
    )
    
    public static func expandAttachedMacro(
        data: Data,
        macro: PluginMessage.MacroReference,
        macroRole: PluginMessage.MacroRole,
        discriminator: String,
        attributeSyntax: PluginMessage.Syntax,
        declSyntax: PluginMessage.Syntax,
        lexicalContext: [PluginMessage.Syntax]?,
        parentDeclSyntax: PluginMessage.Syntax?,
        extendedTypeSyntax: PluginMessage.Syntax?,
        conformanceListSyntax: PluginMessage.Syntax?,
        parameters: String
    ) throws -> (expandedSource: String?, diagnostics: [PluginMessage.Diagnostic]) {
        try makeResult(
            parameters: Parameters.make(parameters: parameters),
            macro: macro,
            macroRole: macroRole,
            attributeSyntax: attributeSyntax,
            declSyntax: declSyntax,
            lexicalContext: lexicalContext
        )
    }
    
    public static func makeResult(
        parameters: Parameters,
        macro: PluginMessage.MacroReference,
        macroRole: PluginMessage.MacroRole,
        attributeSyntax: PluginMessage.Syntax,
        declSyntax: PluginMessage.Syntax,
        lexicalContext: [PluginMessage.Syntax]?,
    ) throws -> (expandedSource: String?, diagnostics: [PluginMessage.Diagnostic]) {
        guard let parts = RegexLib.extractSwiftDeclPartsSeparated(from: declSyntax.source) else { return ("error", []) }
        
        if macroRole == .accessor {
            return expandAccessor(
                parameters: parameters,
                lexicalContext: lexicalContext,
                parts: parts
            )
        } else {
            return try expandPeer(
                parameters: parameters,
                attributeSource: attributeSyntax.source,
                wrapperTypeName: macro.name,
                parts: parts
            )
        }
    }
}

//MARK: - expandAccessor
@available(macOS 13.0, *)
extension EZPropertyWrapperMacro {
    private static func expandAccessor(
        parameters: Parameters,
        lexicalContext: [PluginMessage.Syntax]?,
        parts: DeclParts
    ) -> (expandedSource: String?, diagnostics: [PluginMessage.Diagnostic]) {
        if parts.value?.hasPrefix("{") == true {
            return (
                parameters.isImmutable || parts.value?.contains("set") == false ?
                    "{ get }" :
                    "{ get \(parameters.isConstant ? "nonmutating" : "") set }",
                []
            )
        } else {
            let containerSource = lexicalContext?.first?.source ?? ""
            let isStruct = containerSource.contains("struct")
            let isStatic = parts.modifiers.contains("static")
            let needsNonmutatingModify = parameters.isConstant && isStruct && !isStatic
            
            return (makeGetSet(
                isImmutable: parameters.isImmutable,
                needsNonmutatingModify: needsNonmutatingModify,
                name: parts.name
            ), [])
        }
    }
    
    private static func makeGetSet(
        isImmutable: Bool,
        needsNonmutatingModify: Bool,
        name: String
    ) -> String {
        """
        {
            _read { yield _\(name).wrappedValue }
            \(makeSet(isImmutable: isImmutable, needsNonmutatingModify: needsNonmutatingModify, name: name))
        }
        """
    }
    private static func makeSet(
        isImmutable: Bool,
        needsNonmutatingModify: Bool,
        name: String
    ) -> String {
        if !isImmutable {
            return "\(needsNonmutatingModify ? "nonmutating " : "")_modify { yield &_\(name).wrappedValue }"
        } else {
            return ""
        }
    }
}

//MARK: - expandPeer
@available(macOS 13.0, *)
extension EZPropertyWrapperMacro {
    private static func expandPeer(
        parameters: Parameters,
        attributeSource: String,
        wrapperTypeName: String,
        parts: DeclParts
    ) throws -> (expandedSource: String?, diagnostics: [PluginMessage.Diagnostic]) {
        let attributeArgs = try makeAttributeArgs(from: attributeSource)

        var wrapperTypeName = wrapperTypeName.cleanWhitespace()
        var setModifiers: [String] = parts.modifiers
        var getModifiers: [String] = parts.modifiers
        if let setterRestrictedAccess = parts.setterRestrictedAccess {
            setModifiers.append(setterRestrictedAccess.replacingOccurrences(of: "(set)", with: ""))
            getModifiers.append(contentsOf: parts.accessModifiers)
            getModifiers.removeAll(where: { $0 == setterRestrictedAccess })
        } else {
            setModifiers.append(contentsOf: parts.accessModifiers)
            getModifiers = setModifiers
        }
        
        let wrappedTypeFromWrapper = wrapperTypeName.findAndRemove(of: .typeContent)?.content
        if let wrappedType = wrappedTypeFromWrapper ?? parts.type {
            return (makeType(
                parameters: parameters,
                setMods: joinTokens(setModifiers),
                getMods: joinTokens(getModifiers),
                name: parts.name,
                type: wrapperTypeName,
                wrappedType: wrappedType,
                wrappedValue: parts.value,
                atr: attributeArgs
            ), [])
        } else {
            return (
                """
                //Example:
                //@\(wrapperTypeName) var example: String = ""
                //or
                //@\(wrapperTypeName)<String> var example = ""
                """,
                [.init(
                    message: "Please provide a type for the wrapper.",
                    severity: .error,
                    position: .invalid,
                    highlights: [],
                    notes: [],
                    fixIts: []
                )]
            )
        }
    }
    private static func makeAttributeArgs(from attributeSource: String) throws -> String? {
        var values = try AttributeValue.getAttributeValues(attribute: attributeSource)
        values.removeAll { $0.raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !values.isEmpty else { return nil }
        return values.map { $0.raw }.joined(separator: ", ")
    }

    private static func joinTokens(_ tokens: [String]) -> String {
        tokens
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    
    private static func makeType(
        parameters: Parameters,
        setMods: String,
        getMods: String,
        name: String,
        type: String,
        wrappedType: String,
        wrappedValue: String?,
        atr: String?
    ) -> String {
        let wrapperType = makeWrapperType(
            type: type,
            wrappedType: wrappedType.replacingOccurrences(of: "!", with: "?")
        )
        let setModsPrefix = setMods.isEmpty ? "" : "\(setMods) "
        let getModsPrefix = getMods.isEmpty ? "" : "\(getMods) "
        
        if let wrappedValue, wrappedValue.hasPrefix("{") {
            return (
                """
                \(parameters.isProjected ? "\(getModsPrefix) var $\(name): \(wrapperType).ProjectedValue { get }" : "")
                \(
                    wrappedValue.contains("set") || parameters.isImmutable ?
                        "\(getModsPrefix) var _\(name): \(wrapperType) { get \(!parameters.isConstant ? "set" : "") }" :
                        ""
                )
                """
            )
        } else {
            let initializer = makeTypeValue(
                parameters: parameters,
                type: wrapperType,
                wrappedType: wrappedType,
                wrappedValue: wrappedValue,
                atr: atr
            )
    
            return makeTypes(
                parameters: parameters,
                setModsPrefix: setModsPrefix,
                getModsPrefix: getModsPrefix,
                name: name,
                wrapperType: wrapperType,
                initializer: initializer
            )
        }
    }
    
    private static func makeTypes(
        parameters: Parameters,
        setModsPrefix: String,
        getModsPrefix: String,
        name: String,
        wrapperType: String,
        initializer: String
    ) -> String {
        """
        \(
            parameters.isProjected ?
                """
                \(getModsPrefix)var $\(name): \(wrapperType).ProjectedValue {
                    _read { yield _\(name).projectedValue }
                }
                """ :
                ""
        )
        \(setModsPrefix)\(parameters.isConstant ? "let" : "var") _\(name): \(wrapperType)\(initializer)
        """
    }
    
    private static func makeWrapperType(
        type: String,
        wrappedType: String
    ) -> String {
        "\(type)<\(wrappedType)>"
    }
    
    private static func makeTypeValue(
        parameters: Parameters,
        type: String,
        wrappedType: String?,
        wrappedValue: String?,
        atr: String?
    ) -> String {
        if let wrappedValue {
            return " = \(type)(wrappedValue: \(wrappedValue)\(makeTypeValueAtr(atr: atr)))"
        } else if
            !parameters.isImmutable || !parameters.isConstant,
            let wrappedType,
            wrappedType.hasSuffix("?") ||
            wrappedType.hasPrefix("Optional<")
        {
            return " = \(type)(wrappedValue: nil\(makeTypeValueAtr(atr: atr)))"
        } else {
            return ""
        }
    }
    
    private static func makeTypeValueAtr(atr: String?) -> String {
        if let atr {
            return ", \(atr)"
        } else {
            return ""
        }
    }
}
#endif

