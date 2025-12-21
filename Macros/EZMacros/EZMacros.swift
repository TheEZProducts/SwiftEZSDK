//
//  EZMacros.swift
//  EZSDK
//
//  Created by Александр Сенин on 18.12.2025.
//

#if !os(iOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)

@main
@available(macOS 13.0, *)
struct EZMacros: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EZConstantPropertyWrapperMacro.self,
        EZConstantImmutablePropertyWrapperMacro.self
    ]
}
#endif
