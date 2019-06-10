//
//  CommandDefinition-Completion.swift
//  CommandLineCore
//
//  Created by Simeon Leifer on 6/10/19.
//  Copyright © 2019 droolingcat.com. All rights reserved.
//

import Foundation

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
