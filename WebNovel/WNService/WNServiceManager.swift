//
//  WNServiceManager.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/18/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

class WNServiceManager {
    static var shared: WNServiceManager = {
        return WNServiceManager()
    }()
    
    var serviceProvider: WNServiceProvider = NovelUpdates()
    var listingServiceSortingCriterion: WNSortingCriterion?
    var listingServiceSortAscending: Bool = false
    var listingServiceParameter: String?
}
