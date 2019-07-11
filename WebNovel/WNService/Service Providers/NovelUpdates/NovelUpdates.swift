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
    static var baseUrl = URL(string: "https://www.novelupdates.com")!
    var serviceEndpoint = URL(string: "https://www.novelupdates.com/wp-admin/admin-ajax.php")!
    var listingService: WNListingService?
    
    init() {
        // Default the listing service to the first available
        listingService = availableListingServices().first
    }
    
    /// Parses raw html response for chapters into an array of WNChapter
    private func parseChapters(_ webNovelUrl: String, _ doc: Document) throws -> [WNChapter] {
        guard let list = try doc.getElementsByTag("ol").first() else {
            throw WNError.parsingError("Missing chapters list")
        }
        return try list.children()
            .reversed()
            .enumerated()
            .map { (idx, chapter) in
                guard let a = try chapter.getElementsByAttribute("data-id").first() else {
                    throw WNError.parsingError("No chapters found")
                }
                return try WNChapter(
                    webNovelUrl,
                    url: "https:\(a.attr("href"))",
                    name: a.text(),
                    id: idx + 1
                )
        }
    }
    
    /// Fetch links of all chapters for the given WN.
    func fetchChaptersCatagoue(for wn: WebNovel, cachePolicy: WNCache.Policy) -> Promise<WNChaptersCatalogue> {
        let url = wn.url
        if cachePolicy == .usesCache {
            if let catalogue = try! WNCache.fetch(by: url, object: WNChaptersCatalogue.self) {
                return Promise { seal in
                    print("Loaded chapters for \(url) from core data")
                    seal.fulfill(catalogue)
                }
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
                let chapters = try self.parseChapters(url, SwiftSoup.parse(html))
                return WNChaptersCatalogue(url, chapters)
            }.get { catalogue in
                try WNCache.save(catalogue)
                print("Saved chapters for \(url) to core data")
        }
    }
    
    /// Loads chapter content including title, story, etc.
    func loadChapter(_ chapter: WNChapter, cachePolicy: WNCache.Policy) -> Promise<WNChapter> {
        if cachePolicy == .usesCache {
            if let chapter = try! WNCache.fetch(by: chapter.url, object: WNChapter.self) {
                print("Loaded chapter with url \(chapter.url) from core data")
                return Promise { seal in
                    seal.fulfill(chapter)
                }
            }
        }
        return Promise { seal in
            Alamofire.request(chapter.url).response { dataResponse in
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
                chapter.isDownloaded = true
                WNParser.parse(html, url, mergeInto: chapter)
                    .get { chapter in
                        chapter.byteCount = chapter.serializedByteCount()
                        seal.fulfill(chapter)
                    }.done { chapter in
                        try! WNCache.save(chapter)
                        
                        // Update chapters catalogue information
                        if let catalogue = try? WNCache.fetch(by: chapter.webNovelUrl, object: WNChaptersCatalogue.self) {
                            catalogue.lastModified = .now
                            catalogue.chapters[chapter.url] = chapter
                            try! WNCache.save(catalogue)
                        }
                        print("Saved chapter with url \(url) to core data")
                }
            }
        }
    }
    
    /// List of available listing services
    func availableListingServices() -> [WNListingService] {
        return [
            NUListingService(
                serviceType: .ranking,
                servicePathComponent: "series-ranking",
                parameter: .init(
                    name: "rank",
                    isPathComponent: false,
                    values:  [
                        "Popular (Monthly)": "popmonth",
                        "Popular (All)": "popular",
                        "Activity (Week)": "week",
                        "Activity (Monthly)": "month",
                        "Activity (All)": "sixmonths"
                    ]
                )
            ),
            NUListingService(
                serviceType: .genre,
                servicePathComponent: "genre",
                parameter: .init(
                    name: "genre",
                    isPathComponent: true,
                    values:  WNGenre.allCases.reduce(into: [:]) {
                        $0[$1.camelCased] = $1.dashSeparated
                    }
                ),
                sortingCriteria: WNSortingCriterion.allCases
            ),
            NUListingService(
                serviceType: .language,
                servicePathComponent: "language",
                parameter: .init(
                    name: "language",
                    isPathComponent: true,
                    values:  [
                        "Chinese": "chinese",
                        "Korean": "korean",
                        "Japanese": "japanese"
                    ]
                ),
                sortingCriteria: WNSortingCriterion.allCases
            ),
            NUListingService(
                serviceType: .all,
                servicePathComponent: "novelslisting",
                sortingCriteria: WNSortingCriterion.allCases
            ),
            NUListingService(serviceType: .latest, servicePathComponent: "latest-series"),
        ]
    }
}
