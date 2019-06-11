//
//  BashcompCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

open class BashcompCommand: Command {
    required public init() {
    }

    var items: [String] = []

    // swiftlint:disable cyclomatic_complexity

    open func run(cmd: ParsedCommand, core: CommandCore) {
        let allArgs = cmd.parameters
        let last = allArgs.last ?? ""
        let args = Array(allArgs.dropLast())

        items.removeAll()

        if let def = core.parser?.definition {
            var trailingSub = def.trailingSubcommand(for: args)
            if trailingSub == nil {
                let subs = def.subcommands.filter { (sub) -> Bool in
                    return sub.hidden == false
                }
                let cmdNames = subs.map({ (sub) -> String in
                    return sub.name
                })
                for item in cmdNames {
                    items.append(item)
                }

                trailingSub = def.defaultSubcommandDefinition()
            }
            let hasFileParams = def.hasTrailingFileParameter(for: args)
            if let trailingOpt = def.trailingOption(for: args) {
                if trailingOpt.hasFileArguments == true {
                    printFileCompletions()
                } else {
                    if let callback = trailingOpt.completionCallback {
                        let completions = callback()
                        for item in completions {
                            items.append(item)
                        }
                    } else {
                        for item in trailingOpt.completions {
                            items.append(item)
                        }
                    }
                }
            } else if (last.count == 0 && hasFileParams == false) || (last.count > 0 && last[0] == "-") {
                var optNames = def.options.map { (opt) -> String in
                    return opt.longOption
                }
                if let trailingSub = trailingSub {
                    let subOptNames = trailingSub.options.map { (opt) -> String in
                        return opt.longOption
                    }
                    optNames = Array(Set(optNames).union(Set(subOptNames)))
                }
                for item in optNames {
                    items.append(item)
                }
            }
            if let param = def.trailingParameter(for: args, trailing: last.count == 0) {
                if let callback = param.completionCallback {
                    let completions = callback()
                    for item in completions {
                        items.append(item)
                    }
                } else {
                    for item in param.completions {
                        items.append(item)
                    }
                }
            }
            if hasFileParams == true {
                printFileCompletions()
            }
        }

        for item in items {
            print(item)
        }

        // >> Testing
//        testDump(allArgs: allArgs, last: last, args: args, items: items)
        // << Testing
    }

    // swiftlint:enable cyclomatic_complexity

    public static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "bashcomp"
        command.hidden = true
        command.suppressesOptions = true
        command.warnOnMissingSpec = false

        return command
    }

    func printFileCompletions() {
        if items.count == 0 {
            items.append("!files!")
        }
    }

    func testDump(allArgs: [String], last: String, args: [String], items: [String]) {
        debugLog("bashcomp: allArgs:")
        debugLog(allArgs)
        debugLog("bashcomp: last:")
        debugLog(last)
        debugLog("bashcomp: args:")
        debugLog(args)
        debugLog("bashcomp: items reply:")
        debugLog(items)
    }
}
