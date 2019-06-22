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
    case chapters = "Chapters" // sort=5
    case frequency = "Frequency" // sort=1
    case rank = "Rank" // sort=2
    case rating = "Rating" // sort=3
    case readers = "Readers" // sort=4
    case reviews = "Reviews" // sort=6
    case title = "Title" // sort=7
    case lastUpdated = "Last Updated" // sort=8
}

enum WNListingServiceType: String {
    case latest = "Latest"
    case all = "All"
    case ranking = "Ranking"
    case genre = "Genre"
    case language = "Language"
}
