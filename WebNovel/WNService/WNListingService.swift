//
//  WNListingService.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit

enum WNListingService: String {
    case latest
    case all
    case popularMonthlyRanking
    case popularWeeklyRanking
    case popularAllTimeRanking
    case activityMonthlyRanking
    case activityWeeklyRanking
    case activityAllTimeRanking
}
