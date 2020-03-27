//
//  StandardMenu.swift
//  dctl
//
//  Created by Simeon Leifer on 3/8/19.
//  Copyright © 2019 droolingcat.com. All rights reserved.
//

import Foundation

public typealias StandardMenuHandler = () -> Void

public struct StandardMenuOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let menuRepeats = StandardMenuOptions(rawValue: 1 << 0)
    public static let multiSelectable = StandardMenuOptions(rawValue: 1 << 1)
    public static let isBackItem = StandardMenuOptions(rawValue: 1 << 2)
    public static let isQuitItem = StandardMenuOptions(rawValue: 1 << 3)
}

class StandardMenuEntry {
    var menu: String = ""
    var label: String
    var options: StandardMenuOptions
    var handler: StandardMenuHandler?

    init(label: String, options: StandardMenuOptions, handler: StandardMenuHandler? = nil) {
        self.label = label
        self.options = options
        self.handler = handler
    }
}

public class StandardMenu {
    var entries: [StandardMenuEntry] = []
    var title: String?

    static var waitForInputDone: Bool = false

    @discardableResult
    public static func readline(with prompt: String? = nil) -> String? {
        if let prompt = prompt {
            print("\(prompt):")
        }

        var text: String?
        waitForInputDone = false
        FileHandle.standardInput.readabilityHandler = { (handle) in
            text = String(decoding: handle.availableData, as: UTF8.self)
            waitForInputDone = true
        }
        while waitForInputDone == false && CommandLineRunLoop.shared.spinRunLoop(0.2) == true {
            usleep(50000)
        }

        return text?.trimmed()
    }

    public init(_ title: String? = nil) {
        self.title = title
    }

    public func add(_ label: String, options: StandardMenuOptions = [], handler: StandardMenuHandler? = nil) {
        let entry = StandardMenuEntry(label: label, options: options, handler: handler)
        entries.append(entry)
    }

    public func present() {
        var lookup: [String: StandardMenuEntry] = [:]
        var menu: Int = 1
        for item in entries {
            if item.options.contains(.isBackItem) {
                item.menu = " b"
            } else if item.options.contains(.isQuitItem) {
                item.menu = " q"
            } else {
                item.menu = String(format: "%2d", menu)
                menu += 1
            }
            lookup[item.menu.trimmed()] = item
        }

        while true {
            if let title = title {
                print("\(title):")
            }
            for item in entries {
                print("\(item.menu). \(item.label)")
            }
            let ans = StandardMenu.readline(with: "Select")
            if let ans = ans?.trimmed(), let entry = lookup[ans] {
                if let handler = entry.handler {
                    handler()
                }
                if entry.options.contains(.menuRepeats) == false {
                    return
                }
            }
            print()
        }
    }
}
