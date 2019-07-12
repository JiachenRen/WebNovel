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
    var listingService: WNListingService? {get set}
    static var identifier: String {get}
    func availableListingServices() -> [WNListingService]
    func search(byName query: String) -> Promise<[WebNovel]>
    func fetchChaptersCatagoue(for wn: WebNovel, cachePolicy: WNCache.Policy) -> Promise<WNChaptersCatalogue>
    func loadChapter(_ chapter: WNChapter, cachePolicy: WNCache.Policy) -> Promise<WNChapter>
    func loadDetails(_ wn: WebNovel, cachePolicy: WNCache.Policy) -> Promise<WebNovel>
}
