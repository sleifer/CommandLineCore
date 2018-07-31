//
//  CommandLineRunLoop.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/31/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

class CommandLineRunLoop {
    static let shared = CommandLineRunLoop()

    var backgroundCount: Int = 0

    func waitForBackgroundTasks() {
        while (backgroundCount > 0 && spinRunLoop() == true) {
            // do nothing
        }
    }

    @discardableResult
    func spinRunLoop() -> Bool {
        return RunLoop.current.run(mode: .defaultRunLoopMode, before: Date(timeIntervalSinceNow: 2))
    }

    func startBackgroundTask() {
        backgroundCount += 1
    }

    func endBackgroundTask() {
        backgroundCount -= 1
    }

}
