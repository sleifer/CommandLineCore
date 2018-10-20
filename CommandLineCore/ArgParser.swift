//
//  ArgParser.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

public struct CommandOption {
    public var shortOption: String?
    public var longOption: String
    public var argumentCount: Int
    public var hasFileArguments: Bool
    public var help: String

    public init() {
        longOption = ""
        argumentCount = 0
        hasFileArguments = false
        help = ""
    }
}

public struct ParsedOption {
    public var longOption: String
    public var arguments: [String]

    public init() {
        longOption = ""
        arguments = []
    }
}

public struct ParameterInfo {
    public var hint: String
    public var help: String

    public init() {
        hint = ""
        help = ""
    }
}

public struct CommandDefinition {
    public var options: [CommandOption]
    public var help: String
    public var subcommands: [SubcommandDefinition]
    public var defaultSubcommand: String?

    public init() {
        options = []
        help = ""
        subcommands = []
    }
}

public struct SubcommandDefinition {
    public var options: [CommandOption]
    public var requiredParameters: [ParameterInfo]
    public var optionalParameters: [ParameterInfo]
    public var hasFileParameters: Bool
    public var name: String
    public var synopsis: String
    public var help: String
    public var hidden: Bool
    public var suppressesOptions: Bool
    public var warnOnMissingSpec: Bool

    public init() {
        options = []
        requiredParameters = []
        optionalParameters = []
        hasFileParameters = false
        name = ""
        synopsis = ""
        help = ""
        hidden = false
        suppressesOptions = false
        warnOnMissingSpec = true
    }
}

public struct ParsedCommand {
    public var toolName: String
    public var subcommand: String?
    public var options: [ParsedOption]
    public var parameters: [String]
    public var warnOnMissingSpec: Bool

    public init() {
        toolName = ""
        options = []
        parameters = []
        warnOnMissingSpec = true
    }

    public func option(_ name: String) -> ParsedOption? {
        var option: ParsedOption?

        option = self.options.first(where: { (option: ParsedOption) -> Bool in
            if option.longOption == name {
                return true
            }
            return false
        })

        return option
    }
}

public enum ArgParserError: Error {
    case invalidArguments
}

open class ArgParser {
    public let definition: CommandDefinition

    public var args: [String] = []
    public var parsed: ParsedCommand = ParsedCommand()
    public var subcommand: SubcommandDefinition?
    public var helpPrinted: Bool = false
    var subcommandSet: Bool = false

    public init(definition inDefinition: CommandDefinition) {
        definition = inDefinition
    }

    public func parse(_ inArgs: [String]) throws -> ParsedCommand {
        args = inArgs.splittingShortArgs()

        var availableOptions = optionMap(definition.options)
        let availableSubcommands = subcommandMap(definition.subcommands)
        subcommand = nil

        if let defaultSubcommandName = definition.defaultSubcommand, let defaultSubcommand = availableSubcommands[defaultSubcommandName] {
            parsed.subcommand = defaultSubcommandName
            subcommand = defaultSubcommand
            let subOptions = optionMap(defaultSubcommand.options)
            availableOptions = availableOptions.merging(subOptions, uniquingKeysWith: { (first, _) -> CommandOption in
                return first
            })
        }

        if subcommand == nil && args.count == 1 {
            printHelp()
            helpPrinted = true
        }

        parsed.toolName = args[0].lastPathComponent

        let sargs = Array(args.dropFirst())
        let cnt = sargs.count
        var idx = 0
        while idx < cnt {
            let arg = sargs[idx]
            if let value = availableOptions[arg], subcommand == nil || (subcommand != nil && subcommand?.suppressesOptions == false) {
                var option = ParsedOption()
                option.longOption = value.longOption
                idx += 1
                if value.argumentCount > 0 {
                    if cnt - idx <= value.argumentCount {
                        for _ in 0..<value.argumentCount {
                            option.arguments.append(sargs[idx])
                            idx += 1
                        }
                    } else {
                        throw ArgParserError.invalidArguments
                    }
                }
                parsed.options.append(option)
            } else if let value = availableSubcommands[arg], subcommandSet == false {
                parsed.subcommand = value.name
                subcommand = value
                subcommandSet = true

                if value.warnOnMissingSpec == false {
                    parsed.warnOnMissingSpec = false
                }

                availableOptions = optionMap(definition.options)
                let subOptions = optionMap(value.options)
                availableOptions = availableOptions.merging(subOptions, uniquingKeysWith: { (first, _) -> CommandOption in
                    return first
                })
                idx += 1
            } else {
                parsed.parameters.append(arg)
                idx += 1
            }
        }

        return parsed
    }

    func optionMap(_ optionArray: [CommandOption]) -> [String: CommandOption] {
        var map: [String: CommandOption] = [:]

        for option in optionArray {
            if let short = option.shortOption {
                map[short] = option
            }
            map[option.longOption] = option
        }

        return map
    }

    func subcommandMap(_ subcommandArray: [SubcommandDefinition]) -> [String: SubcommandDefinition] {
        var map: [String: SubcommandDefinition] = [:]

        for option in subcommandArray {
            map[option.name] = option
        }

        return map
    }

    fileprivate func printGlobalHelp() {
        if definition.options.count > 0 {
            print()
            print("Options:")
            var optionStrings: [[String]] = []
            for option in definition.options {
                var argCount = ""
                if option.argumentCount > 0 {
                    argCount = "<\(option.argumentCount) args>"
                }
                if let shortOption = option.shortOption {
                    optionStrings.append(["\(shortOption), \(option.longOption)", argCount, option.help])
                } else {
                    optionStrings.append(["\(option.longOption)", argCount, option.help])
                }
            }
            let maxOptionLength = optionStrings.map({ (item: [String]) -> String in
                return item[0]
            }).maxCount()
            let maxArgCountLength = optionStrings.map({ (item: [String]) -> String in
                return item[1]
            }).maxCount()
            let pad = String(repeating: " ", count: max(maxOptionLength, maxArgCountLength))
            for optionInfo in optionStrings {
                print("\(optionInfo[0].padding(toLength: maxOptionLength, withPad: pad, startingAt: 0)) \(optionInfo[1].padding(toLength: maxArgCountLength, withPad: pad, startingAt: 0)) \(optionInfo[2])")
            }
        }
    }

    fileprivate func printSubcommandHelp(_ sub: SubcommandDefinition) {
        if sub.options.count > 0 {
            print()
            print("Options:")
            var optionStrings: [[String]] = []
            for option in sub.options {
                var argCount = ""
                if option.argumentCount > 0 {
                    argCount = "<\(option.argumentCount) args>"
                }
                if let shortOption = option.shortOption {
                    optionStrings.append(["\(shortOption), \(option.longOption)", argCount, option.help])
                } else {
                    optionStrings.append(["\(option.longOption)", argCount, option.help])
                }
            }
            let maxOptionLength = optionStrings.map({ (item: [String]) -> String in
                return item[0]
            }).maxCount()
            let maxArgCountLength = optionStrings.map({ (item: [String]) -> String in
                return item[1]
            }).maxCount()
            let pad = String(repeating: " ", count: max(maxOptionLength, maxArgCountLength))
            for optionInfo in optionStrings {
                print("\(optionInfo[0].padding(toLength: maxOptionLength, withPad: pad, startingAt: 0)) \(optionInfo[1].padding(toLength: maxArgCountLength, withPad: pad, startingAt: 0)) \(optionInfo[2])")
            }
        }
        if sub.requiredParameters.count > 0 {
            print()
            print("Required Parameters:")
            let maxHintLength = sub.requiredParameters.map({ (item) -> String in
                return item.hint
            }).maxCount()
            let pad = String(repeating: " ", count: maxHintLength)
            for param in sub.requiredParameters {
                print("\(param.hint.padding(toLength: maxHintLength, withPad: pad, startingAt: 0))    \(param.help)")
            }
        }
        if sub.optionalParameters.count > 0 {
            print()
            print("Optional Parameters:")
            let maxHintLength = sub.optionalParameters.map({ (item) -> String in
                return item.hint
            }).maxCount()
            let pad = String(repeating: " ", count: maxHintLength)
            for param in sub.optionalParameters {
                print("\(param.hint.padding(toLength: maxHintLength, withPad: pad, startingAt: 0))    \(param.help)")
            }
        }
    }

    public func printHelp() {
        let toolname = args[0].lastPathComponent
        if let sub = subcommand, subcommandSet == true {
            print("Usage: \(toolname) [OPTIONS] \(sub.name) [ARGS]...")
            print()
            print("\(sub.synopsis)")
            if sub.help.count > 0 {
                print()
                print("\(sub.help)")
            }
        } else {
            print("Usage: \(toolname) [OPTIONS] COMMAND [ARGS]...")
            print()
            print("\(definition.help)")
        }
        printGlobalHelp()
        if let sub = subcommand, subcommandSet == true {
            printSubcommandHelp(sub)
        } else {
            let subs = definition.subcommands.filter { (item) -> Bool in
                return item.hidden == false
            }
            if subs.count > 0 {
                print()
                print("Commands:")
                let maxNameLength = subs.map({ (item: SubcommandDefinition) -> String in
                    return item.name
                }).maxCount()
                let pad = String(repeating: " ", count: maxNameLength)
                for sub in subs {
                    print("\(sub.name.padding(toLength: maxNameLength, withPad: pad, startingAt: 0))    \(sub.synopsis)")
                }
            }
        }
    }
}

extension Collection where Element == String {
    func maxCount() -> Int {
        var maxCount = 0
        for item in self {
            let count = item.count
            if count > maxCount {
                maxCount = count
            }
        }
        return maxCount
    }

    func splittingShortArgs() -> [String] {
        return self.map { (item) -> [String] in
            var items: [String] = []
            if item.hasPrefix("-") == true && item.hasPrefix("--") == false {
                for char in item {
                    if char != "-" {
                        items.append("-\(char)")
                    }
                }
            } else {
                return [item]
            }
            return items
            }.reduce([String](), +)
    }
}
