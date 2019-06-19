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
    func availableListingServices() -> [WNListingService]
    func search(byName query: String) -> Promise<[WebNovel]>
    func fetchChapters(for wn: WebNovel, cachePolicy: WNCache.Policy) -> Promise<[WNChapter]>
    func loadChapters(_ chapters: [WNChapter], cachePolicy: WNCache.Policy) -> Guarantee<(loaded: [WNChapter], failed: [WNChapter])>
    func loadChapter(_ chapter: WNChapter, cachePolicy: WNCache.Policy) -> Promise<WNChapter>
    func loadDetails(_ wn: WebNovel, cachePolicy: WNCache.Policy) -> Promise<WebNovel>
}
