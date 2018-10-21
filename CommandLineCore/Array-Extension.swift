//
//  Array-Extension.swift
//  CommandLineCore
//
//  Created by Simeon Leifer on 10/21/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

public extension Array {
    func equalLengthPad(onLeft: Bool = false, with padChar: String = " ", padding: (Element) -> String, compose: ((String, Element) -> String)? = nil) -> [String] {
        var result: [String] = []
        let maxLength = self.map { (item) -> String in
            return padding(item)
            }.maxCount()
        let pad = String(repeating: padChar, count: maxLength)
        for item in self {
            let stringToPad = padding(item)
            let count = maxLength - stringToPad.count
            let index = pad.index(pad.startIndex, offsetBy: count)
            let onePad = String(pad.prefix(upTo: index))
            var newItem: String
            if onLeft == true {
                newItem = onePad + stringToPad
            } else {
                newItem = stringToPad + onePad
            }
            if let composer = compose {
                newItem = composer(newItem, item)
            }
            result.append(newItem)
        }
        return result
    }
}
