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
    
    private let queue = DispatchQueue(label: "com.jiachenren.WebNovel.download", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
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
            }.then { (groups, postId) -> Promise<(groups: [WNChaptersCatalogue.Group], postId: String)> in
                let promises: [Promise<WNChaptersCatalogue.Group>] = groups.map { grp in
                    let parameters: Parameters = [
                        "action": "nd_getchapters",
                        "mygrpfilter": grp.id,
                        "mypostid": postId,
                    ]
                    return htmlRequestResponse(self.serviceEndpoint, method: .post, parameters: parameters, encoding: .ascii)
                        .map { rawHtml in
                            let urls: [String] = try self.parseChapters(url, SwiftSoup.parse(rawHtml)).map {
                                $0.group = grp.name
                                WNCache.save($0)
                                return $0.url
                            }
                            return WNChaptersCatalogue.Group(name: grp.name, isEnabled: true, chapterUrls: urls)
                    }
                }
                return when(fulfilled: promises).map {
                    return (groups: $0, postId: postId)
                }
            }.then { (groups, postId) -> Promise<WNChaptersCatalogue> in
                let parameters: Parameters = [
                    "action": "nd_getchapters",
                    "mypostid": postId,
                ]
                
                return htmlRequestResponse(self.serviceEndpoint, method: .post, parameters: parameters, encoding: .ascii)
                    .map { rawHtml in
                        let chapterOrder = try self.parseChapters(url, SwiftSoup.parse(rawHtml))
                            .enumerated()
                            .reduce(into: [:]) {
                                $0[$1.element.url] = $1.offset
                        }
                        return WNChaptersCatalogue(url, groups, chapterOrder)
                }
            }.get { catalogue in
                WNCache.save(catalogue)
                print("Saved chapters for \(url) to core data")
        }
    }
    
    /// Loads chapter content including title, story, etc.
    func downloadChapter(_ chapter: WNChapter) -> Promise<WNChapter> {
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
                
                WNParser.parse(html, url, mergeInto: chapter)
                    .done(on: self.queue, flags: .barrier) { chapter in
                        chapter.isDownloaded = true
                        chapter.byteCount = chapter.serializedByteCount()
                        WNCache.save(chapter)
                        
                        // Update chapters catalogue information
                        let catalogue = chapter.retrieveCatalogue()
                        catalogue.lastModified = .now
                        catalogue.numDownloads += 1
                        catalogue.downloadedChaptersDict[chapter.url] = true
                        WNCache.save(catalogue)
                        
                        print("Saved chapter with url \(url) to core data")
                        seal.fulfill(chapter)
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
