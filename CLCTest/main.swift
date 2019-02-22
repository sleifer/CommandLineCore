//
//  main.swift
//  CLCTest
//
//  Created by Simeon Leifer on 9/25/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

let toolVersion = "0.1.1"

class CleanupCommand: Command {

    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        var derived: Bool = false
        var root: Bool = false
        var realm: Bool = false

        if cmd.option("--derived") != nil {
            derived = true
        }
        if cmd.option("--realm") != nil {
            realm = true
        }
        if cmd.option("--root") != nil {
            root = true
        }
        if derived == false && realm == false {
            derived = true
            realm = true
        }

        if root == true {
            print("Go from git root... dry-run")
        }

        if derived == true {
            print("Deleting DerivedData... dry-run")
        }

        if realm == true {
            print("Deleting Realm sync_bin... dry-run")
        }

        print("Done.")
    }

    static func commandDefinition() -> SubcommandDefinition {
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
        realm.argumentCount = 1
        realm.hasFileArguments = true
        command.options.append(realm)

        var opt = ParameterInfo()
        opt.help = "file param"
//        opt.completions = ["alpha", "bravo", "charlie"]
        opt.completionCallback = { () -> [String] in
            return ["delta", "echo", "foxtrot"]
        }
        command.optionalParameters.append(opt)
//        command.hasFileParameters = true

        return command
    }
}

func main() {
    #if DEBUG
    // for testing in Xcode
    let path = "~/Documents/Code/project-tool".expandingTildeInPath
    FileManager.default.changeCurrentDirectoryPath(path)
    #endif

    let core = CommandCore()
    core.set(version: toolVersion)
    core.set(help: "A command-line project tool coordinator.")
    core.set(defaultCommand: "cleanup")

    var root = CommandOption()
    root.shortOption = "-R"
    root.longOption = "--root"
    root.help = "Use git repository root directory, not current."

    core.addGlobal(option: root)

    core.add(command: CleanupCommand.self)

    #if DEBUG
    // for testing in Xcode
    let args = ["pt", "bashcomp", "cleanup", ""]
    #else
    let args = CommandLine.arguments
    #endif

    core.process(args: args)
}

main()
