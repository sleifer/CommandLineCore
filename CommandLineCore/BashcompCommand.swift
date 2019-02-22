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
                for item in param.completions {
                    items.append(item)
                }
            }
            if hasFileParams == true {
                printFileCompletions()
            }
        }

        for item in items {
            print(item)
        }
    }

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
}

extension CommandDefinition {
    func defaultSubcommandDefinition() -> SubcommandDefinition? {
        if let defCmd = self.defaultSubcommand {
            let matches = self.subcommands.filter { (def) -> Bool in
                if def.name == defCmd {
                    return true
                }
                return false
            }
            if matches.count > 0 {
                return matches[0]
            }
        }
        return nil
    }

    func trailingSubcommand(for args: [String]) -> SubcommandDefinition? {
        for arg in args {
            let matches = self.subcommands.filter { (def) -> Bool in
                if def.name == arg {
                    return true
                }
                return false
            }
            if matches.count > 0 {
                return matches[0]
            }
        }
        return nil
    }

    func trailingOption(for args: [String]) -> CommandOption? {
        let rargs = args.reversed()
        for (idx, arg) in rargs.enumerated() {
            let matches = self.options.filter { (opt) -> Bool in
                if opt.longOption == arg || opt.shortOption == arg {
                    return true
                }
                return false
            }
            if matches.count > 0 && idx < matches[0].argumentCount {
                return matches[0]
            }
        }
        if let sub = trailingSubcommand(for: args) ?? defaultSubcommandDefinition() {
            for (idx, arg) in rargs.enumerated() {
                let matches = sub.options.filter { (opt) -> Bool in
                    if opt.longOption == arg || opt.shortOption == arg {
                        return true
                    }
                    return false
                }
                if matches.count > 0 && idx < matches[0].argumentCount {
                    return matches[0]
                }
            }
        }
        return nil
    }

    func trailingParameter(for args: [String], trailing: Bool) -> ParameterInfo? {
        if trailingOption(for: args) != nil {
            return nil
        }
        var subcommandFound: Bool = false
        var parametersFound: Int = 0
        var allOptions = self.options
        var allParameters: [ParameterInfo] = []
        if let sub = trailingSubcommand(for: args) ?? defaultSubcommandDefinition() {
            allOptions.append(contentsOf: sub.options)
            allParameters.append(contentsOf: sub.requiredParameters)
            allParameters.append(contentsOf: sub.optionalParameters)
        }

        let count = args.count
        var index: Int = 0
        while index < count {
            let arg = args[index]

            // subcommand
            if subcommandFound == false {
                let matches = self.subcommands.filter { (def) -> Bool in
                    return def.name == arg
                }
                if matches.count > 0 {
                    subcommandFound = true
                    index += 1
                    continue
                }
            }

            // options
            let matches = allOptions.filter { (opt) -> Bool in
                return opt.longOption == arg
            }
            if matches.count > 0 {
                index += matches[0].argumentCount + 1
                continue
            }

            // parameters
            if arg.count != 0 {
                parametersFound += 1
            }
            index += 1
        }

        if trailing == true {
            parametersFound += 1
        }

        if allParameters.count > 0 {
            if parametersFound >= allParameters.count {
                return allParameters.last
            } else if parametersFound == 0 {
                return allParameters[parametersFound]
            } else {
                return allParameters[parametersFound-1]
            }
        }

        return nil
    }

    func hasTrailingFileParameter(for args: [String]) -> Bool {
        if let sub = trailingSubcommand(for: args) ?? defaultSubcommandDefinition() {
            return sub.hasFileParameters
        }
        return false
    }
}
