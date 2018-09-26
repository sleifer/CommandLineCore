//
//  BashcompfileCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

open class BashcompfileCommand: Command {
    let format1 = """
_%@()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="$(${COMP_WORDS[0]} bashcomp ${COMP_WORDS[@]:1:$COMP_CWORD} "${cur}")"

    if [[ $opts = *"!files!"* ]]; then
        COMPREPLY=( $(compgen -df -- ${cur}) )
    else
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    fi

    return 0
}
"""

    let format2 = """
complete -o filenames -F _%@ %@
"""

    required public init() {
    }

    open func run(cmd: ParsedCommand, core: CommandCore) {
        var text = ""
        text.append(String(format: format1, cmd.toolName))
        text.append("\n")
        text.append(String(format: format2, cmd.toolName, cmd.toolName))
        text.append("\n")
        for param in cmd.parameters {
            text.append(String(format: format2, cmd.toolName, param))
            text.append("\n")
        }

        if cmd.option("--write") != nil {
            let dir = "~/.bash_completion.d".expandingTildeInPath
            let file = dir.appendingPathComponent(cmd.toolName)
            if FileManager.default.fileExists(atPath: dir) == false {
                print("~/.bash_completion.d is not set up, nothing written.")
            } else {
                do {
                    let url = URL(fileURLWithPath: file)
                    try text.write(toFileURL: url)
                    print("Completion written to ~/.bash_completion.d/\(cmd.toolName)")
                    print("Load with '. ~/.bash_completion.d/\(cmd.toolName)'")
                } catch {
                    print("Error writing to ~/.bash_completion.d/\(cmd.toolName)")
                }
            }
        } else {
            print(text)
        }
    }

    public static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "bashcompfile"
        command.hidden = true
        command.warnOnMissingSpec = false
        command.hasFileParameters = true

        var option = CommandOption()
        option.longOption = "--write"
        option.shortOption = "-w"
        option.help = "Write to file in ~/.bash_completion.d"
        command.options.append(option)

        return command
    }
}
