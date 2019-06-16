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

class NovelUpdatesProvider: WNServiceProvider {
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
    
    func listingRequestUrl(for listingService: ListingService) -> Promise<URL> {
        return Promise { seal in
            guard let path = listingServicePaths[listingService] else {
                seal.reject(WNError.unsupportedListingService)
                return
            }
            let url = baseUrl.appendingPathComponent(path, isDirectory: true)
            seal.fulfill(url)
        }
    }
    
    /// Fetches web novel listing for the specified listing service type
    /// Notifies delegate upon completion of data task
    func fetchListing(for: ListingService, page: Int) -> Promise<[WNItem]>{
        let parameters: Parameters = [
            "pg": page
        ]
        return htmlListingRequestResponse(for: .ranking, parameters: parameters)
            .then { htmlStr in
                try self.parseListingItems(htmlStr)
            }
    }
    
    /// Constructs a promise wrapping the html response string for the specified listing service fetch request
    /// - Parameter listingService: Listing service to use. Either `ranking`, `latest`, or `all`.
    /// - Returns: A promise wrapping the html response string.
    private func htmlListingRequestResponse(for listingService: ListingService, parameters: Parameters = [:]) -> Promise<String> {
        return listingRequestUrl(for: listingService).then { url in
            htmlRequestResponse(url, parameters: parameters)
        }
    }
    
    /// Extracts WN entries from raw html response string.
    private func parseListingItems(_ htmlStr: String) throws -> Promise<[WNItem]> {
        return Promise {seal in
            let doc = try SwiftSoup.parse(htmlStr)
            // #myTable is a table containing the listing of novels
            guard let tbl = try doc.getElementById("myTable") else {
                seal.reject(WNError.parsingError("failed to find content table"))
                return
            }
            // Each entry contains metadata for the web novel
            let entries = try tbl.getElementsByClass("bdrank")
            var webNovels = [WNItem]()
            for entry in entries {
                let wn = try parseWNItem(entry)
                webNovels.append(wn)
            }
            seal.fulfill(webNovels)
        }
    }
    
    /// Parses an entry of web novel from novelupdates.com
    /// Each entry has 4 children
    /// Index 0: ranking class = ranknum
    /// Index 1: rating class = lstrate
    /// Index 2: 1 child
    /// Index 3:
    ///      <a> -> reference to novel
    ///      class = rankgenre (contains child nodes, each has genre name)
    ///      class = noveldesc (short desc, last child node contains long desc. in <p>)
    ///      class = sfstext (html contains number of releases
    private func parseWNItem(_ element: Element) throws -> WNItem {
        let wn = WNItem()
        // In some cases rank does not exist, in which case the index should shift by 1
        var index = 0
        if let rank = try element.child(index).getElementsByClass("ranknum").first() {
            wn.rank = Int(try rank.text()) ?? -1
            index += 1
        }
        if let rating = try element.child(index).getElementsByClass("lstrate").first() {
            let ratingTxt = try rating.text()
                .replacingOccurrences(of: "[()]", with: "", options: .regularExpression)
            wn.rating = Double(ratingTxt) ?? 0.0
        }
        wn.organization = try element.child(index + 1).child(0).text()
        if let main = element.children().last() {
            if let link = try main.getElementsByTag("a").first() {
                wn.url = link.getAttributes()?.filter {
                    $0.getKey() == "href"
                    }.first?.getValue() ?? ""
                // Follow the official link to find the url of the cover image
                
                wn.title = try link.text()
            }
            if let genresContainer = try main.getElementsByClass("rankgenre").first() {
                wn.genres = try genresContainer.children().map {
                    try $0.text()
                }
            }
            if let desc = try main.getElementsByClass("noveldesc").first() {
                // Sanitize html
                try desc.children().forEach {
                    if try $0.classNames().contains("morelink") {
                        try $0.remove()
                    }
                }
                if let container = desc.children().last() {
                    try container.children().forEach {
                        if $0.tagName() == "span" {
                            try $0.remove()
                        }
                    }
                    // Extract full description
                    let pTagRegex = #"<\s*p[^>]*>(.*?)<\s*/\s*p>"#
                    wn.fullDescription = try container.html()
                        .replacingOccurrences(of: pTagRegex, with: "\n", options: .regularExpression)
                }
                
                try desc.children().forEach {
                    try $0.remove()
                }
                wn.shortDescription = try desc.text()
                wn.fullDescription = (wn.shortDescription ?? "") + "\n" + (wn.fullDescription ?? "")
            }
            if let releases = try main.getElementsByClass("sfstext").first() {
                let releasesTxt = try releases.text()
                    .replacingOccurrences(of: nonDigitRegex, with: "", options: .regularExpression)
                wn.releases = Int(releasesTxt) ?? 0
            }
        }
        return wn
    }
    
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
