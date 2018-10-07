//
//  String-Extension.swift
//  project-tool
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

public extension String {
    var fullPath: String {
        let normal = self.expandingTildeInPath.standardizingPath
        if normal.hasPrefix("/") {
            return normal
        }
        return FileManager.default.currentDirectoryPath.appendingPathComponent(normal)
    }

    var expandingTildeInPath: String {
        return NSString(string: self).expandingTildeInPath
    }

    var abbreviatingWithTildeInPath: String {
        return NSString(string: self).abbreviatingWithTildeInPath
    }

    var deletingLastPathComponent: String {
        return NSString(string: self).deletingLastPathComponent
    }

    var deletingPathExtension: String {
        return NSString(string: self).deletingPathExtension
    }

    func appendingPathExtension(_ str: String) -> String? {
        return NSString(string: self).appendingPathExtension(str)
    }

    func hasFileSuffix(_ str: String) -> Bool {
        return self.deletingPathExtension.hasSuffix(str)
    }

    func changeFileSuffix(from: String, to: String) -> String {
        let ext = self.pathExtension
        let base = self.deletingPathExtension
        if base.hasSuffix(from) {
            if let newStr = base.prefix(upTo: base.count - from.count).appending(to).appendingPathExtension(ext) {
                return newStr
            }
        }
        return self
    }

    func changeFileExtension(to: String) -> String {
        if let newStr = self.deletingPathExtension.appendingPathExtension(to) {
            return newStr
        }
        return self
    }

    func changeFileExtension(from: String, to: String) -> String {
        if self.pathExtension == from {
            if let newStr = self.deletingPathExtension.appendingPathExtension(to) {
                return newStr
            }
        }
        return self
    }

    var lastPathComponent: String {
        return NSString(string: self).lastPathComponent
    }

    var pathExtension: String {
        return NSString(string: self).pathExtension
    }

    var standardizingPath: String {
        return NSString(string: self).standardizingPath
    }

    var isAbsolutePath: Bool {
        return NSString(string: self).isAbsolutePath
    }

    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func appendingPathComponent(_ str: String) -> String {
        return NSString(string: self).appendingPathComponent(str)
    }

    subscript (idx: Int) -> Character {
        return self[index(startIndex, offsetBy: idx)]
    }

    subscript (idx: Int) -> String {
        return String(self[idx] as Character)
    }

    subscript(range: Range<Int>) -> String {
        let lower = self.index(self.startIndex, offsetBy: range.lowerBound)
        let upper = self.index(self.startIndex, offsetBy: range.upperBound)
        let substr = self[lower..<upper]
        return String(substr)
    }

    subscript(range: ClosedRange<Int>) -> String {
        let lower = self.index(self.startIndex, offsetBy: range.lowerBound)
        let upper = self.index(self.startIndex, offsetBy: range.upperBound)
        let substr = self[lower...upper]
        return String(substr)
    }

    func prefix(through position: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: position)
        return String(self.prefix(through: index))
    }

    func prefix(upTo end: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: end)
        return String(self.prefix(upTo: index))
    }

    func suffix(from start: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: start)
        return String(self.suffix(from: index))
    }

    func regex(_ pattern: String) -> [[String]] {
        var matches: [[String]] = []
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
            for result in results {
                var submatches: [String] = []
                for idx in 0..<result.numberOfRanges {
                    let range = result.range(at: idx)
                    if range.location != NSNotFound {
                        let substr = self[range.location..<(range.length + range.location)]
                        submatches.append(substr)
                    }
                }
                matches.append(submatches)
            }
        } catch {
            print("invalid regex: \(error.localizedDescription)")
        }
        return matches
    }

    func components(separatedBy separator: String) -> [String] {
        return NSString(string: self).components(separatedBy: separator)
    }

    func lines(skippingBlanks: Bool = true) -> [String] {
        var lines = self.components(separatedBy: CharacterSet.newlines)
        if skippingBlanks == true {
            lines = lines.filter { (str: String) -> Bool in
                if str.count > 0 {
                    return true
                }
                return false
            }
        }
        return lines
    }
}
