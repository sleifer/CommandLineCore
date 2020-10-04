//
//  SimpleRunner.swift
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

public typealias SimpleRunnerCompletionHandler = (_ runner: SimpleRunner) -> Void
public typealias SimpleRunnerOutputHandler = (_ runner: SimpleRunner, _ stdOutLine: String?, _ stdErrLine: String?) -> Void

open class SimpleRunner {
    public var fullCmd: String
    public var command: String
    public var arguments: [String]
    var process: Process?
    public var status: Int32 = -999
    public var stdOut: String = ""
    public var stdErr: String = ""
    public var outputHandler: SimpleRunnerOutputHandler?

    internal init(_ fullCmd: String) {
        let args = fullCmd.quoteSafeWords()
        let cmd = args[0]
        var sargs = args
        sargs.remove(at: 0)

        self.fullCmd = fullCmd
        command = cmd
        arguments = sargs
    }

    public func getOutput(_ trimmed: Bool = false) -> String {
        if trimmed == true {
            return stdOut.trimmed()
        }
        return stdOut
    }

    public func getError(_ trimmed: Bool = false) -> String {
        if trimmed == true {
            return stdErr.trimmed()
        }
        return stdErr
    }

    func terminate() {
        process?.terminate()
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

        if outputHandler != nil {
            outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let outData = handle.availableData
                if let str = String(data: outData, encoding: .utf8) {
                    if str.trimmed().count > 0 {
                        if let self = self, let outputHandler = self.outputHandler {
                            outputHandler(self, str, nil)
                        }
                    }
                    self?.stdOut.append(str)
                }
            }

            errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let outData = handle.availableData
                if let str = String(data: outData, encoding: .utf8) {
                    if str.trimmed().count > 0 {
                        if let self = self, let outputHandler = self.outputHandler {
                            outputHandler(self, nil, str)
                        }
                    }
                    self?.stdErr.append(str)
                }
            }
        }

        proc.launch()
        proc.waitUntilExit()

        process = nil
        status = proc.terminationStatus

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        if let str = String(data: outData, encoding: .utf8) {
            stdOut.append(str)
        }

        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        if let str = String(data: errData, encoding: .utf8) {
            stdErr.append(str)
        }
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
            if foundCmd.count > 0 {
                whichLookup[cmd] = foundCmd
                return foundCmd
            }
        }
        whichLookup[cmd] = cmd
        return cmd
    }

    @discardableResult
    public class func run(_ fullCmd: String, queue: DispatchQueue = DispatchQueue.main, dryrun: Bool = false, outputHandler: SimpleRunnerOutputHandler? = nil, completion: SimpleRunnerCompletionHandler? = nil) -> SimpleRunner {
        let runner = SimpleRunner(fullCmd)

        if dryrun == true {
            print("> \(fullCmd)")
            runner.status = 0
            return runner
        }

        if let completion = completion {
            DispatchQueue.global(qos: .background).async {
                runner.command = which(runner.command)
                runner.outputHandler = outputHandler
                runner.run()
                queue.async {
                    completion(runner)
                }
            }
        } else {
            runner.command = which(runner.command)
            runner.outputHandler = outputHandler
            runner.run()
        }
        return runner
    }
}
