//
//  ZshcompfileCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

open class ZshcompfileCommand: Command {
    let format1 = """
#compdef %@

_%@() {
    local -a commands
    local -a args
    local opt
    local showfiles
    local -a thearguments
    local -a thedescribe

    commands=(
    )

    args=(
    )

    if (( CURRENT >= 2 )); then
        opt=$($_comp_command2 zshcomp $LBUFFER $RBUFFER)
        showfiles=$(echo $opt | jq -r '.files')
        thearguments=$(echo $opt | jq -r '.arguments[]')
        thedescribe=$(echo $opt | jq -r '.describe[]')

        while IFS= read -r line ; do args+="$line"; done <<< "$thearguments"
        while IFS= read -r line ; do commands+="$line"; done <<< "$thedescribe"

        _describe -t commands 'commands' commands
        _arguments -s $args

        if [[ "$showfiles" == "true" ]]; then
            _files
        fi
    fi

    return 0
}
"""

    let format2 = """
compctl -K _%@ %@
"""

    required public init() {
    }

    open func run(cmd: ParsedCommand, core: CommandCore) {
        var text = ""
        text.append(String(format: format1, cmd.toolName))
        text.append("\n\n")
        text.append(String(format: format2, cmd.toolName, cmd.toolName))
        text.append("\n")
        for param in cmd.parameters {
            text.append(String(format: format2, cmd.toolName, param))
            text.append("\n")
        }

        if cmd.option("--write") != nil {
            let dir = "~/.zsh_completion".expandingTildeInPath
            let filename = "_\(cmd.toolName)"
            let file = dir.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: dir) == false {
                print("~/.zsh_completion is not set up, nothing written.")
            } else {
                do {
                    let url = URL(fileURLWithPath: file)
                    try text.write(toFileURL: url)
                    print("Completion written to ~/.zsh_completion/\(filename)")
                    print("Load with:")
                    print(". ~/.zsh_completion./\(filename)")
                } catch {
                    print("Error writing to ~/.zsh_completion/\(filename)")
                }
            }
        } else {
            print(text)
        }
    }

    public static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "zshcompfile"
        command.hidden = true
        command.warnOnMissingSpec = false
        command.hasFileParameters = true

        var option = CommandOption()
        option.longOption = "--write"
        option.shortOption = "-w"
        option.help = "Write to file in ~/.zsh_completion"
        command.options.append(option)

        return command
    }
}
