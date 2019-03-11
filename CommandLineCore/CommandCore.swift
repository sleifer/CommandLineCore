//
//  CommandCore.swift
//  CommandLineCore
//
//  Created by Simeon Leifer on 9/25/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

open class CommandCore {
    public static var core: CommandCore?

    public private(set) var version: String
    public private(set) var commandPath: String
    public private(set) var commandName: String
    public private(set) var baseDirectory: String
    public private(set) var definition: CommandDefinition
    var commandMap: [String: Command.Type]
    public private(set) var parser: ArgParser?
    public private(set) var parsed: ParsedCommand?

    public init() {
        version = "0.1"
        commandPath = "?"
        commandName = "?"
        baseDirectory = FileManager.default.currentDirectoryPath
        definition = CommandDefinition()
        commandMap = [:]
        addDefaultGlobalOptions()
        addInternalCommands()

        if CommandCore.core == nil {
            CommandCore.core = self
        }
    }

    func addDefaultGlobalOptions() {
        var version = CommandOption()
        version.longOption = "--version"
        version.help = "Show tool version information"
        definition.options.append(version)

        var help = CommandOption()
        help.shortOption = "-h"
        help.longOption = "--help"
        help.help = "Show this help"
        definition.options.append(help)
    }

    func addInternalCommands() {
        add(command: BashcompCommand.self)
        add(command: BashcompfileCommand.self)
    }

    public func set(version: String) {
        self.version = version
    }

    public func set(baseDirectory: String) {
        self.baseDirectory = baseDirectory
    }

    public func set(help: String) {
        definition.help = help
    }

    public func set(defaultCommand: String?) {
        definition.defaultSubcommand = defaultCommand
    }

    public func addGlobal(option: CommandOption) {
        definition.options.append(option)
    }

    public func add<T: Command>(command commandClass: T.Type) {
        let def = commandClass.commandDefinition()
        commandMap[def.name] = commandClass
        definition.subcommands.append(def)
    }

    public func process(args: [String]) {
        autoreleasepool {
            let theParser = ArgParser(definition: definition)
            parser = theParser

            do {
                commandPath = args[0].fullPath
                commandName = args[0].lastPathComponent
                let theParsed = try theParser.parse(args)
                parsed = theParsed

                var skipSubcommand = false

                if theParsed.option("--version") != nil {
                    print("Version \(version)")
                    skipSubcommand = true
                }
                if theParsed.option("--help") != nil {
                    theParser.printHelp()
                    skipSubcommand = true
                }

                if skipSubcommand == false {
                    var commandClass: Command.Type?
                    if let subcommand = theParsed.subcommand {
                        commandClass = commandMap[subcommand]
                    }

                    if let commandClass = commandClass {
                        let cmd = commandClass.init()
                        cmd.run(cmd: theParsed, core: self)
                    } else {
                        if theParsed.parameters.count > 0 {
                            print("Unknown command: \(theParsed.parameters[0])")
                        }
                    }
                }
            } catch {
                print("Invalid arguments.")
                theParser.printHelp()
            }

            CommandLineRunLoop.shared.waitForBackgroundTasks()
        }
    }

    public func baseSubPath(_ subpath: String) -> String {
        var path = subpath.standardizingPath
        if path.isAbsolutePath == false {
            path = baseDirectory.appendingPathComponent(path)
        }
        return path
    }

    public func setCurrentDir(_ subpath: String) {
        FileManager.default.changeCurrentDirectoryPath(baseSubPath(subpath))
    }

    public func resetCurrentDir() {
        setCurrentDir(baseDirectory)
    }
}
