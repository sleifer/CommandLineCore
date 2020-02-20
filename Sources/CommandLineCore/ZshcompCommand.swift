//
//  ZshcompCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

struct CompletionContext {
    let leftOfCursor: String
    let rightOfCursor: String
    let cursorIndex: Int
    let wordCount: Int
    let allArgs: [String]
    let last: String
    let args: [String]

    init?(_ parameters: [String]) {
        leftOfCursor = parameters[0]
        rightOfCursor = parameters[1]

        if let value = Int(parameters[2]) {
            cursorIndex = value
        } else {
            debugLog("Error Parsing CompletionContext")
            debugLog(parameters)
            return nil
        }

        if let value = Int(parameters[3]) {
            wordCount = value
        } else {
            debugLog("Error Parsing CompletionContext")
            debugLog(parameters)
            return nil
        }

        var temp = parameters
        temp.removeSubrange(0...3)
        allArgs = temp

        if wordCount > allArgs.count {
            last = ""
            args = allArgs
        } else {
            if let value = allArgs.last {
                last = value
            } else {
                debugLog("Error Parsing CompletionContext")
                debugLog(parameters)
                return nil
            }
            temp.removeLast()
            args = temp
        }
    }
}

open class ZshcompCommand: Command {
    required public init() {
    }

    var commands: [String] = []
    var options: [String] = []
    var showFiles: Bool = false

    // swiftlint:disable cyclomatic_complexity

    open func run(cmd: ParsedCommand, core: CommandCore) {
        guard let ctx = CompletionContext(cmd.parameters) else {
            return
        }

        commands = []
        options = []
        showFiles = false

        if let def = core.parser?.definition {
            var trailingSub = def.trailingSubcommand(for: ctx.args)
            if trailingSub == nil {
                let subs = def.subcommands.filter { (sub) -> Bool in
                    return sub.hidden == false
                }
                for item in subs {
                    commands.append("\(item.name):\(item.synopsis)")
                }

                trailingSub = def.defaultSubcommandDefinition()
            }
            let hasFileParams = def.hasTrailingFileParameter(for: ctx.args)
            if let trailingOpt = def.trailingOption(for: ctx.args) {
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
            } else if (ctx.last.count == 0 && hasFileParams == false) || (ctx.last.count > 0 && ctx.last[0] == "-") {
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
                        commands.append("\(item.longOption):\(item.help)")
                    }
                    lastLongOption = item.longOption
                }
            }
            if let param = def.trailingParameter(for: ctx.args, trailing: ctx.last.count == 0) {
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
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            if let jsonStr = String(data: data, encoding: .utf8) {
                print(jsonStr)
                // >> Testing
//                testDump(ctx: ctx, json: jsonStr)
                // << Testing
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

    func testDump(ctx: CompletionContext, json: String) {
        debugLog("zshcomp: allArgs:")
        debugLog(ctx.allArgs)
        debugLog("zshcomp: last:")
        debugLog(ctx.last)
        debugLog("zshcomp: args:")
        debugLog(ctx.args)
        debugLog("zshcomp: json reply:")
        debugLog(json)
    }
}
