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
}

struct StandardMenuEntry {
    var label: String
    var options: StandardMenuOptions
    var handler: StandardMenuHandler?
}

public class StandardMenu {
    var entries: [StandardMenuEntry] = []
    var title: String?

    public static func readline(with prompt: String) -> String? {
        print("\(prompt): ", terminator: "")
        return readLine(strippingNewline: true)
    }

    public init(_ title: String? = nil) {
        self.title = title
    }

    public func add(_ label: String, options: StandardMenuOptions = [], handler: StandardMenuHandler? = nil) {
        let entry = StandardMenuEntry(label: label, options: options, handler: handler)
        entries.append(entry)
    }

    @discardableResult
    public func present() -> Int {
        while true {
            if let title = title {
                print("\(title):")
            }
            for (index, value) in entries.enumerated() {
                let numStr = String(format: "%2d", index + 1)
                print("\(numStr). \(value.label)")
            }
            let ans = StandardMenu.readline(with: "Select")
            if let ans = ans, let val = Int(ans), val > 0, val <= entries.count {
                if let handler = entries[val - 1].handler {
                    handler()
                }
                if entries[val-1].options.contains(.menuRepeats) == false {
                    return val
                }
            }
            print()
        }
    }
}
