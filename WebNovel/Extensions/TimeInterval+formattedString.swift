//
//  TimeInterval+formattedString.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/10/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

extension TimeInterval {
    var formattedString: String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1
        
        return formatter.string(from: self)
    }
}
