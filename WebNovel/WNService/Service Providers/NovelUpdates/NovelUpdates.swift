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
    static var identifier = "Novel Updates"
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
    
    typealias WNGroup = (name: String, id: String)
    
    private func parseGroups(_ rawHtml: String) throws -> [WNGroup] {
        let doc = try SwiftSoup.parse(rawHtml)
        let entries = try doc.getElementsByTag("li")
        return entries.compactMap { entry in
            if let id = try? entry.getElementsByTag("input").first?.attr("value"),
                let name = try? entry.text() {
                return (name: name, id: id)
            }
            return nil
        }
    }
    
    /// Fetch links of all chapters for the given WN.
    /// - Parameter url: URL for the webNovel or chapters catalogue
    func loadChaptersCatagoue(from url: String, cachePolicy: WNCache.Policy) -> Promise<WNChaptersCatalogue> {
        if cachePolicy == .usesCache {
            if let catalogue = WNCache.fetch(by: url, object: WNChaptersCatalogue.self) {
                return Promise { seal in
                    print("Loaded chapters for \(url) from core data")
                    seal.fulfill(catalogue)
                }
            }
        }
        return htmlRequestResponse(url).map { html in
                try SwiftSoup.parse(html)
            }.map { doc -> String in
                guard let postId = try doc.getElementById("mypostid")?.attr("value") else {
                    throw WNError.missingParameter("mypostid")
                }
                return postId
            }.then { postId -> Promise<(groups: [WNGroup], postId: String)> in
                let parameters: Parameters = [
                    "action": "nd_getgroupnovel",
                    "mygrr": 0,
                    "mypostid": postId
                ]
                return htmlRequestResponse(self.serviceEndpoint, method: .post, parameters: parameters)
                    .map { html in
                        let groups = try self.parseGroups(html)
                        return (groups, postId)
                }
            }.then { (groups, postId) -> Promise<[[WNChapter]]> in
                let promises: [Promise<[WNChapter]>] = groups.map { grp in
                    let parameters: Parameters = [
                        "action": "nd_getchapters",
                        "mygrpfilter": grp.id,
                        "mypostid": postId,
                    ]
                    return htmlRequestResponse(self.serviceEndpoint, method: .post, parameters: parameters, encoding: .ascii)
                        .map { rawHtml in
                            try self.parseChapters(url, SwiftSoup.parse(rawHtml)).map {
                                $0.group = grp.name
                                return $0
                            }
                    }
                }
                return when(fulfilled: promises)
            }.map { groupedChapters in
                let chapters = groupedChapters.flatMap {$0}
                let catalogue = WNChaptersCatalogue(url, chapters)
                catalogue.groups = groupedChapters.compactMap {$0.first?.group}
                    .map {WNChaptersCatalogue.Group(name: $0, isEnabled: true)}
                return catalogue
            }.get { catalogue in
                WNCache.save(catalogue)
                print("Saved chapters for \(url) to core data")
        }
    }
    
    /// Loads chapter content including title, story, etc.
    func loadChapter(_ chapter: WNChapter, cachePolicy: WNCache.Policy) -> Promise<WNChapter> {
        if cachePolicy == .usesCache {
            if let chapter = WNCache.fetch(by: chapter.url, object: WNChapter.self) {
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
                        WNCache.save(chapter)
                        
                        // Update chapters catalogue information
                        if let catalogue = WNCache.fetch(by: chapter.webNovelUrl, object: WNChaptersCatalogue.self) {
                            catalogue.lastModified = .now
                            catalogue.chapters[chapter.url] = chapter
                            WNCache.save(catalogue)
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
