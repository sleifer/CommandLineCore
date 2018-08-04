//
//  CommandLineRunLoop.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/31/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

open class CommandLineRunLoop {
    public static let shared = CommandLineRunLoop()

    var backgroundCount: Int = 0

    public func waitForBackgroundTasks() {
        while backgroundCount > 0 && spinRunLoop() == true {
            // do nothing
        }
    }

    @discardableResult
    public func spinRunLoop() -> Bool {
        return RunLoop.current.run(mode: .defaultRunLoopMode, before: Date(timeIntervalSinceNow: 2))
    }

    public func startBackgroundTask() {
        backgroundCount += 1
    }

    public func endBackgroundTask() {
        backgroundCount -= 1
    }

}
