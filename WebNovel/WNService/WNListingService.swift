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
    var sortAscending: Bool {get set}
    var parameterValue: String? {get set}
    var sortingCriterion: WNSortingCriterion? {get set}
    var availableParameters: [String] {get}
    var availableSortingCriteria: [WNSortingCriterion] {get}
    func fetchListing(page: Int) -> Promise<[WebNovel]>
}

enum WNSortingCriterion: String, CaseIterable {
    case numberOfReaders = "Number of Readers" // sort=tread
    case numberOfReleases = "Number of Releases" // sort=nrelease
    case rank = "Rank" // sort=trank
    case rating = "Rating" // sort=trate
    case releaseFrequency = "Release Frequency" // sort=tfreq
    case title = "Title" // sort=abc
}

enum WNListingServiceType: String {
    case latest = "Latest"
    case all = "All"
    case ranking = "Ranking"
    case genre = "Genre"
    case language = "Language"
}
