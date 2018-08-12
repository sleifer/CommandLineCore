//
//  StringWriting.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/17/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

public extension String {
    func append(toFileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(toFileURL: toFileURL)
    }

    func write(toFileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.write(toFileURL: toFileURL)
    }
}

public extension Data {
    func append(toFileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: toFileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: toFileURL, options: .atomic)
        }
    }

    func write(toFileURL: URL) throws {
        try write(to: toFileURL, options: .atomic)
    }
}
