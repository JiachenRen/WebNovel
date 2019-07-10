//
//  Data+size.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/29/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

extension Data {
    static func size(format: ByteCountFormatter.Units, bytesCount c: Int) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = format
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(c))
    }
}
