//
//  EZPropertyWrapperMacro.swift
//  EZSDK
//
//  Created by Александр Сенин on 18.12.2025.
//

#if !os(iOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)
import Foundation
import EZSwiftCompilerPluginLight

@available(macOS 13.0, *)
public struct EZConstantPropertyWrapperMacro: AttachedMacro {
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
        conformanceListSyntax: PluginMessage.Syntax?
    ) throws -> (expandedSource: String?, diagnostics: [PluginMessage.Diagnostic]) {
        guard let parts = RegexLib.extractSwiftDeclPartsSeparated(from: declSyntax.source) else { return ("error", []) }
        
        if macroRole == .accessor {
            return expandAccessor(
                lexicalContext: lexicalContext,
                parts: parts
            )
        } else {
            return try expandPeer(
                attributeSource: attributeSyntax.source,
                wrapperTypeName: macro.name,
                parts: parts
            )
        }
    }
}

//MARK: - expandAccessor
@available(macOS 13.0, *)
extension EZConstantPropertyWrapperMacro {
    private static func expandAccessor(
        lexicalContext: [PluginMessage.Syntax]?,
        parts: DeclParts
    ) -> (expandedSource: String?, diagnostics: [PluginMessage.Diagnostic]) {
        let containerSource = lexicalContext?.first?.source ?? ""
        let isStruct = containerSource.contains("struct")
        let isStatic = parts.modifiers.contains("static")
        let needsNonmutatingModify = isStruct && !isStatic
        
        return (makeGetSet(oh: needsNonmutatingModify, name: parts.name), [])
    }
    
    private static func makeGetSet(oh: Bool, name: String) -> String {
        """
        {
            _read { yield _\(name).wrappedValue }
            \(oh ? "nonmutating " : "")_modify { yield &_\(name).wrappedValue }
        }
        """
    }
}

//MARK: - expandPeer
@available(macOS 13.0, *)
extension EZConstantPropertyWrapperMacro {
    private static func expandPeer(
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
        
        let initializer = makeTypeValue(type: type, wrappedType: wrappedType, wrappedValue: wrappedValue, atr: atr)
        let setModsPrefix = setMods.isEmpty ? "" : "\(setMods) "
        let getModsPrefix = getMods.isEmpty ? "" : "\(getMods) "

        return makeTypes(
            setModsPrefix: setModsPrefix,
            getModsPrefix: getModsPrefix,
            name: name,
            wrapperType: wrapperType,
            initializer: initializer
        )
    }
    
    private static func makeTypes(
        setModsPrefix: String,
        getModsPrefix: String,
        name: String,
        wrapperType: String,
        initializer: String
    ) -> String {
        """
        \(getModsPrefix)var $\(name): \(wrapperType).ProjectedValue {
            _read { yield _\(name).projectedValue }
        }
        \(setModsPrefix)let _\(name): \(wrapperType)\(initializer)
        """
    }
    
    private static func makeWrapperType(
        type: String,
        wrappedType: String
    ) -> String {
        "\(type)<\(wrappedType)>"
    }
    
    private static func makeTypeValue(
        type: String,
        wrappedType: String?,
        wrappedValue: String?,
        atr: String?
    ) -> String {
        if let wrappedValue {
            return " = \(type)(wrappedValue: \(wrappedValue)\(makeTypeValueAtr(atr: atr)))"
        } else if
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
