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

    var deletingLastPathComponent: String {
        return NSString(string: self).deletingLastPathComponent
    }

    var lastPathComponent: String {
        return NSString(string: self).lastPathComponent
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

    func prefix(_ maxLength: Int) -> String {
        return String(self.prefix(maxLength))
    }

    func prefix(through position: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: position)
        return String(self.prefix(through: index))
    }

    func prefix(upTo end: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: end)
        return String(self.prefix(upTo: index))
    }

    func suffix(_ maxLength: Int) -> String {
        return String(self.suffix(maxLength))
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
}
