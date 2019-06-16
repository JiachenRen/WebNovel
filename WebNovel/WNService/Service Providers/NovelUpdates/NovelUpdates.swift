//
//  NovelUpdatesProvider.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/15/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftSoup

class NovelUpdates: WNServiceProvider {
    let nonDigitRegex = "[^0-9]+"
    var baseUrl = URL(string: "https://www.novelupdates.com")!
    var serviceEndpoint = URL(string: "https://www.novelupdates.com/wp-admin/admin-ajax.php")!
    var availableListingServices: [ListingService] = [
        .ranking,
        .latest,
        .all
    ]
    var listingServicePaths: [ListingService: String] = [
        .ranking: "series-ranking",
        .all: "novelslisting",
        .latest: "latest-series",
    ]
    
    /// Fetch links of all chapters for the given WN.
    func fetchChapters(for wn: WNItem) -> Promise<[WNChapter]> {
        func parseChaptersListing(_ doc: Document) throws -> [WNChapter] {
            guard let list = try doc.getElementsByTag("ol").first() else {
                throw WNError.parsingError("Missing chapters list")
            }
            return try list.children().map { chapter in
                let a = try chapter.getElementsByAttribute("data-id").first()!
                return try WNChapter(url: "https:\(a.attr("href"))", chapter: a.text())
            }
        }
        return wn.html().map { html in
            try SwiftSoup.parse(html)
            }.map { doc -> String in
                guard let postId = try doc.getElementById("mypostid")?.attr("value") else {
                    throw WNError.missingParameter("mypostid")
                }
                return postId
            }.then { postId -> Promise<String> in
                let parameters: Parameters = [
                    "action": "nd_getchapters",
                    "mypostid": postId,
                ]
                return htmlRequestResponse(self.serviceEndpoint, method: .post, parameters: parameters, encoding: .ascii)
            }.map { html in
                try parseChaptersListing(SwiftSoup.parse(html))
        }
    }
    
    /// Loads chapter content including title, story, etc.
    func loadChapter(_ chapter: WNChapter) -> Promise<WNChapter> {
        return Promise<(String, URL, WNChapter)> { seal in
            Alamofire.request(chapter.url).response {
                dataResponse in
                guard let data = dataResponse.data else {
                    seal.reject(dataResponse.error ?? WNError.unknownResponseError)
                    return
                }
                guard let html = String(data: data, encoding: .utf8) else {
                    seal.reject(WNError.incorrectEncoding)
                    return
                }
                guard let url = dataResponse.response?.url else {
                    seal.reject(WNError.urlNotFound)
                    return
                }
                seal.fulfill((html, url, chapter))
            }
            }.then {
                WNParser.parseChapter($0.0, $0.1, mergeInto: $0.2)
        }
    }
}
