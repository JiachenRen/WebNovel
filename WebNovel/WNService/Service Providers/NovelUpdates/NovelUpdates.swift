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
    
    /// Parses raw html response for chapters catalogue into an array of WNChapter
    private func parseChaptersCatalogue(_ doc: Document) throws -> [WNChapter] {
        guard let list = try doc.getElementsByTag("ol").first() else {
            throw WNError.parsingError("Missing chapters list")
        }
        return try list.children().enumerated().map { (idx, chapter) in
            let a = try chapter.getElementsByAttribute("data-id").first()!
            return try WNChapter(url: "https:\(a.attr("href"))", chapter: a.text(), id: idx + 1)
        }
    }
    
    /// Fetch links of all chapters for the given WN.
    func fetchChapters(for wn: WebNovel, cachePolicy: WNCache.Policy) -> Promise<[WNChapter]> {
        if cachePolicy == .usesCache, let url = wn.url {
            if let catalogue = try! WNCache.fetchChaptersCatalogue(url) {
                return Promise { seal in
                    print("Loaded chapters for \(url) from core data")
                    seal.fulfill(catalogue.chapters)
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
            try self.parseChaptersCatalogue(SwiftSoup.parse(html))
        }.get { chapters in
            guard let url = wn.url else {
                throw WNError.urlNotFound
            }
            let catalogue = WNChaptersCatalogue(url, chapters)
            try WNCache.save(catalogue)
            print("Saved chapters for \(url) to core data")
        }
    }
    
    /// Loads chapter content including title, story, etc.
    func loadChapter(_ chapter: WNChapter, cachePolicy: WNCache.Policy) -> Promise<WNChapter> {
        if cachePolicy == .usesCache, let url = chapter.url {
            if let chapter = try! WNCache.fetchChapter(url) {
                return Promise { seal in
                    seal.fulfill(chapter)
                }
            }
        }
        return Promise<(String, URL, WNChapter)> { seal in
            guard let url = chapter.url else {
                throw WNError.urlNotFound
            }
            Alamofire.request(url).response {
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
    
    func loadChapters(_ chapters: [WNChapter], cachePolicy: WNCache.Policy) -> Guarantee<(loaded: [WNChapter], failed: [WNChapter])> {
        let promises = chapters.map {
            self.loadChapter($0, cachePolicy: cachePolicy)
        }
        return when(resolved: promises).map { results in
            var fulfilled: [WNChapter] = []
            var rejected: [WNChapter] = []
            for (idx, result) in results.enumerated() {
                switch result {
                case .fulfilled(let ch):
                    fulfilled.append(ch)
                case .rejected(let e):
                    print((e as? WNError)?.localizedDescription ?? e)
                    print(chapters[idx])
                    rejected.append(chapters[idx])
                }
            }
            return (fulfilled, rejected)
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
