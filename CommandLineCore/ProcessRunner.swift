//
//  ProcessRunner.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

public typealias ProcessRunnerHandler = (_ runner: ProcessRunner) -> Void

open class ProcessRunner {
    public let command: String
    public let arguments: [String]
    var process: Process?
    public var status: Int32 = -999
    public var stdOut: String = ""
    public var stdErr: String = ""
    public var echo: Bool = false

    internal init(_ cmd: String, args: [String]) {
        command = cmd
        arguments = args
    }

    internal func start(_ completion: ProcessRunnerHandler? = nil) {
        let proc = Process()
        process = proc
        proc.launchPath = command
        proc.arguments = arguments
        let outPipe = Pipe()
        proc.standardOutput = outPipe
        let errPipe = Pipe()
        proc.standardError = errPipe

        if echo == true {
            outPipe.fileHandleForReading.readabilityHandler = { [weak self] (handle) in
                let outData = handle.availableData
                if let str = String(data: outData, encoding: .utf8) {
                    print(str, terminator: "")
                    self?.stdOut.append(str)
                }
            }

            errPipe.fileHandleForReading.readabilityHandler = { [weak self] (handle) in
                let outData = handle.availableData
                if let str = String(data: outData, encoding: .utf8) {
                    print(str, terminator: "")
                    self?.stdErr.append(str)
                }
            }
        }

        proc.terminationHandler = { (process: Process) -> Void in
            self.status = process.terminationStatus

            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            if let str = String(data: outData, encoding: .utf8) {
                if self.echo == true {
                    print(str)
                }
                self.stdOut.append(str)
            }

            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            if let str = String(data: errData, encoding: .utf8) {
                if self.echo == true {
                    print(str)
                }
                self.stdErr.append(str)
            }

            DispatchQueue.main.async {
                if let completion = completion {
                    completion(self)
                }
                CommandLineRunLoop.shared.endBackgroundTask()
                self.process = nil
            }
        }

        CommandLineRunLoop.shared.startBackgroundTask()
        proc.launch()
    }

    static let whichCmd = "/usr/bin/which"
    static var whichLookup: [String: String] = [:]

    class func which(_ cmd: String) -> String {
        if let lookup = whichLookup[cmd] {
            return lookup
        }
        let proc = ProcessRunner.runCommand(whichCmd, args: [cmd])
        if proc.status == 0 {
            let foundCmd = proc.stdOut.trimmingCharacters(in: .whitespacesAndNewlines)
            whichLookup[cmd] = foundCmd
            return foundCmd
        }
        whichLookup[cmd] = cmd
        return cmd
    }

    @discardableResult
    public class func runCommand(_ args: [String], echo: Bool = false, completion: ProcessRunnerHandler? = nil) -> ProcessRunner {
        let cmd = args[0]
        var sargs = args
        sargs.remove(at: 0)
        return runCommand(cmd, args: sargs, echo: echo, completion: completion)
    }

    @discardableResult
    public class func runCommand(_ cmd: String, args: [String], echo: Bool = false, completion: ProcessRunnerHandler? = nil) -> ProcessRunner {
        let fullCmd: String
        if cmd == whichCmd {
            fullCmd = cmd
        } else {
            fullCmd = which(cmd)
        }
        let runner = ProcessRunner(fullCmd, args: args)
        if cmd != whichCmd {
            runner.echo = echo
        }
        var done: Bool = false
        runner.start { (runner) in
            if let completion = completion {
                completion(runner)
            }
            done = true
        }
        if completion == nil {
            while done == false {
                CommandLineRunLoop.shared.spinRunLoop()
            }
            return runner
        }
        return runner
    }
}
