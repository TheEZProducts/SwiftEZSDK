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
        EZPropertyWrapperMacro.self
    ]
    
    func resolveMacro(moduleName: String, typeName: String) -> (any Macro.Type, String)? {
        let components = typeName.components(separatedBy: "_")
        return _resolveMacro(moduleName: moduleName, typeName: components.first ?? "").map {
            ($0, components.count > 1 ? components.last! : "")
        }
    }
    
    private func _resolveMacro(moduleName: String, typeName: String) -> Macro.Type? {
        let qualifedName = "\(moduleName).\(typeName)"
        
        for type in providingMacros {
            let name = String(reflecting: type)
            if name == qualifedName {
                return type
            }
        }
        return nil
    }
}
#endif
