//
//  Command.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

public protocol Command: class {
    init()
    func run(cmd: ParsedCommand, core: CommandCore)
    static func commandDefinition() -> SubcommandDefinition
}
