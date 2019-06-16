//
//  WNServiceProvider.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/14/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire

protocol WNServiceProvider {
    var availableListingServices: [ListingService] {get}
    func search(byName query: String) -> Promise<[WNItem]>
    func fetchListing(for: ListingService, page: Int) -> Promise<[WNItem]>
    func fetchChapters(for wn: WNItem) -> Promise<[WNChapter]>
    func loadChapter(_ chapter: WNChapter) -> Promise<WNChapter>
    func fetchDetails(_ wn: WNItem) -> Promise<WNItem>
}
