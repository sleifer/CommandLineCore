//
//  ZshcompCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

open class ZshcompCommand: Command {
    required public init() {
    }

    var commands: [String] = []
    var options: [String] = []
    var showFiles: Bool = false

    // swiftlint:disable cyclomatic_complexity

    open func run(cmd: ParsedCommand, core: CommandCore) {
        let allArgs = cmd.parameters
        let last = allArgs.last ?? ""
        let args = Array(allArgs.dropLast())

        commands = []
        options = []
        showFiles = false

        if let def = core.parser?.definition {
            var trailingSub = def.trailingSubcommand(for: args)
            if trailingSub == nil {
                let subs = def.subcommands.filter { (sub) -> Bool in
                    return sub.hidden == false
                }
                for item in subs {
                    commands.append("\(item.name):\(item.synopsis)")
                }

                trailingSub = def.defaultSubcommandDefinition()
            }
            let hasFileParams = def.hasTrailingFileParameter(for: args)
            if let trailingOpt = def.trailingOption(for: args) {
                if trailingOpt.hasFileArguments == true {
                    showFiles = true
                } else {
                    if let callback = trailingOpt.completionCallback {
                        let completions = callback()
                        for item in completions {
                            commands.append(item)
                        }
                    } else {
                        for item in trailingOpt.completions {
                            commands.append(item)
                        }
                    }
                }
            } else if (last.count == 0 && hasFileParams == false) || (last.count > 0 && last[0] == "-") {
                var collectedOptions: [CommandOption] = []
                collectedOptions.append(contentsOf: def.options)
                if let trailingSub = trailingSub {
                    collectedOptions.append(contentsOf: trailingSub.options)
                }
                collectedOptions.sort { (lhs, rhs) -> Bool in
                    return lhs.longOption < rhs.longOption
                }

                var lastLongOption: String = ""

                for item in collectedOptions {
                    if lastLongOption != item.longOption {
                        if let short = item.shortOption {
                            options.append("(\(short) \(item.longOption))'{\(short),\(item.longOption)}'[\(item.help)]")
                        } else {
                            options.append("\(item.longOption)[\(item.help)]")
                        }
                    }
                    lastLongOption = item.longOption
                }
            }
            if let param = def.trailingParameter(for: args, trailing: last.count == 0) {
                if let callback = param.completionCallback {
                    let completions = callback()
                    for item in completions {
                        commands.append(item)
                    }
                } else {
                    for item in param.completions {
                        commands.append(item)
                    }
                }
            }
            if hasFileParams == true {
                showFiles = true
            }
        }

        do {
            let json: [String: Any] = ["arguments": options, "describe": commands, "files": showFiles ? "true" : "false"]
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            if let jsonStr = String(data: data, encoding: .utf8) {
                print(jsonStr)
                return
            }
        } catch {
        }
    }

    // swiftlint:enable cyclomatic_complexity

    public static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "zshcomp"
        command.hidden = true
        command.suppressesOptions = true
        command.warnOnMissingSpec = false

        return command
    }
}
