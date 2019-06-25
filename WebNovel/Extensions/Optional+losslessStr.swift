//
//  Optional+losslessStr.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/25/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

extension Optional where Wrapped: LosslessStringConvertible {
    var losslessStr: String {
        return self == nil ? "N/A" : String(self!)
    }
}
