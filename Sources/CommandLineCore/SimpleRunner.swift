//
//  SimpleRunner.swift
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

public typealias SimpleRunnerCompletionHandler = (_ runner: SimpleRunner) -> Void

open class SimpleRunner {
    public var fullCmd: String
    public var command: String
    public var arguments: [String]
    var process: Process?
    public var status: Int32 = -999
    public var stdOut: String = ""
    public var stdErr: String = ""

    internal init(_ fullCmd: String) {
        let args = fullCmd.quoteSafeWords()
        let cmd = args[0]
        var sargs = args
        sargs.remove(at: 0)

        self.fullCmd = fullCmd
        command = cmd
        arguments = sargs
    }

    public func getOutput(_ trimmed: Bool = false) -> String? {
        if status == 0 {
            if trimmed == true {
                return stdOut.trimmed()
            }
            return stdOut
        }
        return nil
    }

    public func getError(_ trimmed: Bool = false) -> String? {
        if status == 0 {
            if trimmed == true {
                return stdErr.trimmed()
            }
            return stdErr
        }
        return nil
    }

    internal func run() {
        let proc = Process()
        process = proc
        proc.launchPath = command
        proc.arguments = arguments
        let outPipe = Pipe()
        proc.standardOutput = outPipe
        let errPipe = Pipe()
        proc.standardError = errPipe

        proc.terminationHandler = { (process: Process) -> Void in
            self.status = process.terminationStatus

            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            if let str = String(data: outData, encoding: .utf8) {
                self.stdOut.append(str)
            }

            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            if let str = String(data: errData, encoding: .utf8) {
                self.stdErr.append(str)
            }
        }

        proc.launch()
        proc.waitUntilExit()
        status = proc.terminationStatus
    }

    static let whichCmd = "/usr/bin/which"
    static var whichLookup: [String: String] = [:]

    class func which(_ cmd: String) -> String {
        if let lookup = whichLookup[cmd] {
            return lookup
        }
        let runner = SimpleRunner("\(whichCmd) \(cmd)")
        runner.run()
        if runner.status == 0 {
            let foundCmd = runner.stdOut.trimmingCharacters(in: .whitespacesAndNewlines)
            whichLookup[cmd] = foundCmd
            return foundCmd
        }
        whichLookup[cmd] = cmd
        return cmd
    }

    @discardableResult
    public class func run(_ fullCmd: String, queue: DispatchQueue = DispatchQueue.main, dryrun: Bool = false, completion: SimpleRunnerCompletionHandler? = nil) -> SimpleRunner {
        let runner = SimpleRunner(fullCmd)

        if dryrun == true {
            print("> \(fullCmd)")
            runner.status = 0
            return runner
        }

        if let completion = completion {
            DispatchQueue.global(qos: .background).async {
                runner.command = which(runner.command)
                runner.run()
                queue.async {
                    completion(runner)
                }
            }
        } else {
            runner.command = which(runner.command)
            runner.run()
        }
        return runner
    }
}
