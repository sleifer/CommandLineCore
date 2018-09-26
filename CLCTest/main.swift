//
//  main.swift
//  CLCTest
//
//  Created by Simeon Leifer on 9/25/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

// MARK: command implementation tool bootstrap

class CleanupCommand: Command {
    override func run(cmd: ParsedCommand) {
        var derived: Bool = false
        var ignored: Bool = false
        var realm: Bool = false

        if cmd.option("--derived") != nil {
            derived = true
        }
        if cmd.option("--realm") != nil {
            realm = true
        }
        if derived == false && ignored == false && realm == false {
            derived = true
            ignored = true
            realm = true
        }

        if derived == true {
            print("Deleting DerivedData... dry-run")
        }

        if realm == true {
            print("Deleting Realm sync_bin... dry-run")
        }

        print("Done.")
    }
}

// MARK: CommandDefinitions tool bootstrap

func makeCommandDefinition() -> CommandDefinition {
    var definition = CommandDefinition()
    definition.help = "A command-line project tool coordinator."

    var version = CommandOption()
    version.longOption = "--version"
    version.help = "Show tool version information"
    definition.options.append(version)

    var help = CommandOption()
    help.shortOption = "-h"
    help.longOption = "--help"
    help.help = "Show this help"
    definition.options.append(help)

    var root = CommandOption()
    root.shortOption = "-R"
    root.longOption = "--root"
    root.help = "Use git repository root directory, not current."
    definition.options.append(root)

    definition.subcommands.append(cleanupCommand())

    definition.defaultSubcommand = "project"

    return definition
}

private func cleanupCommand() -> SubcommandDefinition {
    var command = SubcommandDefinition()
    command.name = "cleanup"
    command.synopsis = "Delete build products."

    var derived = CommandOption()
    derived.shortOption = "-d"
    derived.longOption = "--derived"
    derived.help = "Delete derived data."
    command.options.append(derived)

    var realm = CommandOption()
    realm.shortOption = "-r"
    realm.longOption = "--realm"
    realm.help = "Delete Realm sync_bin."
    command.options.append(realm)

    return command
}

// MARK: main.swift tool bootstrap

import CommandLineCore

let toolVersion = "0.1.6"
var baseDirectory: String = ""
var commandName: String = ""

func main() {
    autoreleasepool {
        let parser = ArgParser(definition: makeCommandDefinition())

        do {
            #if DEBUG
            let args = ["pt", "cleanup"]
            commandName = args[0]
            let parsed = try parser.parse(args)
            #else
            let parsed = try parser.parse(CommandLine.arguments)
            commandName = CommandLine.arguments[0].lastPathComponent
            #endif

            #if DEBUG
            // for testing in Xcode
            let path = "~/Documents/Code/project-tool".expandingTildeInPath
            FileManager.default.changeCurrentDirectoryPath(path)
            #endif

            baseDirectory = FileManager.default.currentDirectoryPath

            if let cmd = commandFrom(parser: parser) {
                cmd.run(cmd: parsed)
            }
        } catch {
            print("Invalid arguments.")
            parser.printHelp()
        }

        CommandLineRunLoop.shared.waitForBackgroundTasks()
    }
}

func commandFrom(parser: ArgParser) -> Command? {
    var skipSubcommand = false
    var cmd: Command?
    let parsed = parser.parsed

    if parsed.option("--version") != nil {
        print("Version \(toolVersion)")
        skipSubcommand = true
    }
    if parsed.option("--help") != nil {
        parser.printHelp()
        skipSubcommand = true
    }

    if skipSubcommand == false {
        switch parsed.subcommand ?? "root" {
        case "bashcomp":
            cmd = BashcompCommand(parser: parser)
        case "bashcompfile":
            cmd = BashcompfileCommand()
        case "cleanup":
            cmd = CleanupCommand()
        case "root":
            if parsed.parameters.count > 0 {
                print("Unknown command: \(parsed.parameters[0])")
            }
        default:
            print("Unknown command.")
        }
    }

    return cmd
}

func baseSubPath(_ subpath: String) -> String {
    var path = subpath.standardizingPath
    if path.isAbsolutePath == false {
        path = baseDirectory.appendingPathComponent(path)
    }
    return path
}

func setCurrentDir(_ subpath: String) {
    FileManager.default.changeCurrentDirectoryPath(baseSubPath(subpath))
}

func resetCurrentDir() {
    setCurrentDir(baseDirectory)
}

main()
