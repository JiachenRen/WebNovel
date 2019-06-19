//
//  WNListingService.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit

protocol WNListingService {
    var serviceType: WNListingServiceType {get}
    var availableParameters: [String] {get}
    var availableSortingCriteria: [WNSortingCriterion] {get}
    func fetchListing(page: Int, parameter: String?, sortBy criterion: WNSortingCriterion?, asc: Bool) -> Promise<[WebNovel]>
}

enum WNSortingCriterion: String, CaseIterable {
    case numberOfReleases = "N. Releases" // sort=nrelease
    case rank = "Rank" // sort=trank
    case rating = "Rating" // sort=trate
    case releaseFrequency = "Release Freq." // sort=tfreq
    case title = "Title" // sort=abc
    case numberOfReaders = "N. Readers" // sort=tread
}

enum WNListingServiceType: String {
    case latest = "Latest"
    case all = "All"
    case ranking = "Ranking"
    case genre = "Genre"
    case language = "Language"
}
