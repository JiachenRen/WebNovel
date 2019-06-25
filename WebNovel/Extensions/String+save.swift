//
//  String+save.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/24/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

extension String {
    
    /// Saves this string in document directory with specified fileName and extension
    func save(as fileName: String) throws -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = dir.appendingPathComponent(fileName)
        try write(to: fileURL, atomically: false, encoding: .utf8)
        return fileURL
    }
}
