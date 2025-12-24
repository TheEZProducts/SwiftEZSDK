//
//  File.swift
//
//
//  Created by John Scott on 02/09/2023.
//
import Foundation

extension CompilerPluginMessageHandler {
    /// Expand `@freestainding(XXX)` macros.
    func expandFreestandingMacro(
        message: HostToPluginMessage,
        macro: PluginMessage.MacroReference,
        macroRole: PluginMessage.MacroRole?,
        discriminator: String,
        expandingSyntax: PluginMessage.Syntax
    ) throws {
        let response: PluginToHostMessage
        var diagnostics: [PluginMessage.Diagnostic]
        var expandedSource: String? = nil
        let result = provider.resolveMacro(moduleName: macro.moduleName, typeName: macro.typeName)
        if let result, let macroType = result.0 as? FreestandingMacro.Type {
            let result = try macroType.expandFreestandingMacro(
                macro: macro,
                macroRole: macroRole,
                discriminator: discriminator,
                expandingSyntax: expandingSyntax,
                parameters: result.1
            )
            expandedSource = result.expandedSource
            diagnostics = result.diagnostics
        } else {
            diagnostics = []
            diagnostics.append(PluginMessage.Diagnostic(message: "\(#function) is not implemented for moduleName \(macro.moduleName) typeName: \(macro.typeName)", severity: .error, position: PluginMessage.Diagnostic.Position(fileName: expandingSyntax.location.fileName, offset: expandingSyntax.location.offset), highlights: [], notes: [], fixIts: []))
        }
        
      
        if hostCapability.hasExpandMacroResult {
            response = .expandMacroResult(expandedSource: expandedSource, diagnostics: diagnostics)
        } else {
            // TODO: Remove this  when all compilers have 'hasExpandMacroResult'.
            response = .expandFreestandingMacroResult(expandedSource: expandedSource, diagnostics: diagnostics)
        }
        try self.sendMessage(response)
    }
    
    /// Expand `@attached(XXX)` macros.
    func expandAttachedMacro(
        data: Data,
        message: HostToPluginMessage,
        macro: PluginMessage.MacroReference,
        macroRole: PluginMessage.MacroRole,
        discriminator: String,
        attributeSyntax: PluginMessage.Syntax,
        declSyntax: PluginMessage.Syntax,
        lexicalContext: [PluginMessage.Syntax]?,
        parentDeclSyntax: PluginMessage.Syntax?,
        extendedTypeSyntax: PluginMessage.Syntax?,
        conformanceListSyntax: PluginMessage.Syntax?
    ) throws {
        let response: PluginToHostMessage
        var diagnostics: [PluginMessage.Diagnostic]
        var expandedSource: String? = nil
        let result = provider.resolveMacro(moduleName: macro.moduleName, typeName: macro.typeName)
        if let result, let macroType = result.0 as? AttachedMacro.Type {
            let result = try macroType.expandAttachedMacro(
                data: data,
                macro: macro,
                macroRole: macroRole,
                discriminator: discriminator,
                attributeSyntax: attributeSyntax,
                declSyntax: declSyntax,
                lexicalContext: lexicalContext,
                parentDeclSyntax: parentDeclSyntax,
                extendedTypeSyntax: extendedTypeSyntax,
                conformanceListSyntax: conformanceListSyntax,
                parameters: result.1
            )
            expandedSource = result.expandedSource
            diagnostics = result.diagnostics
        } else {
            diagnostics = []
            diagnostics.append(PluginMessage.Diagnostic(message: "\(#function) is not implemented for moduleName \(macro.moduleName) typeName: \(macro.typeName)", severity: .error, position: PluginMessage.Diagnostic.Position(fileName: attributeSyntax.location.fileName, offset: attributeSyntax.location.offset), highlights: [], notes: [], fixIts: []))
        }

    

        if hostCapability.hasExpandMacroResult {
            response = .expandMacroResult(expandedSource: expandedSource, diagnostics: diagnostics)
        } else {
            response = .expandAttachedMacroResult(expandedSources: expandedSource.map({[$0]}), diagnostics: diagnostics)
        }
        try self.sendMessage(response)
    }
    
    func prettyDescription<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try! encoder.encode(value)
        let string = String(data: data, encoding: .utf8)
        return string!
    }
}
