//
//  File.swift
//  
//
//  Created by Александр Сенин on 30.05.2023.
//

import Foundation
import PackagePlugin

@main
@available(macOS 13.0, *)
struct EZJsonKeysPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        let outputDirectoryPath = context.pluginWorkDirectory.appending(subpath: target.name)
        try FileManager.default.createDirectory(atPath: outputDirectoryPath.string, withIntermediateDirectories: true)
        let filePath = outputDirectoryPath.appending(subpath: "EZJsonKeysPlugin.generated.swift")
        
       
        let sourceFiles = target.sourceFiles
            .filter { $0.path.string.hasSuffix(".ez.json") }
            .map(\.path)

        return [
            .buildCommand(
                displayName: "Generate Code",
                executable: try context.tool(named: "EZJsonKeysGenerator").path,
                arguments: [filePath] + sourceFiles,
                environment: [:],
                inputFiles: [],
                outputFiles: [filePath])
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

@available(macOS 13.0, *)
extension EZJsonKeysPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let outputDirectoryPath = context.pluginWorkDirectory
            .appending(subpath: target.displayName)
            .appending(subpath: "Resources")

        try FileManager.default.createDirectory(atPath: outputDirectoryPath.string, withIntermediateDirectories: true)
        let filePath = outputDirectoryPath.appending(subpath: "EZJsonKeysPlugin.generated.swift")
        
       
        let sourceFiles = target.inputFiles
            .filter { $0.path.string.hasSuffix(".ez.json") }
            .map(\.path)

        return [
            .buildCommand(
                displayName: "Generate Code",
                executable: try context.tool(named: "EZJsonKeysGenerator").path,
                arguments: [filePath] + sourceFiles,
                environment: [:],
                inputFiles: [],
                outputFiles: [filePath])
        ]
    }
}

#endif

