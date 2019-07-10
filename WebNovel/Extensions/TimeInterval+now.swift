//
//  TimeInterval+now.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/28/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

extension TimeInterval {
    static var now: TimeInterval {
        return Date().timeIntervalSince1970
    }
}
