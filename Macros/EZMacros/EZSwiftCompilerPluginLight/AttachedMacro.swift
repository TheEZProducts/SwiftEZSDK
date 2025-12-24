//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

/// Describes a macro that is attached, meaning that it is used with
/// custom attribute syntax and attached to another entity.
public protocol AttachedMacro: Macro {
    static func expandAttachedMacro(
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
    ) throws -> (
        expandedSource: String?,
        diagnostics: [PluginMessage.Diagnostic]
    )
}
