//
//  WNServiceProvider.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/14/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftSoup

class WNServiceProvider {
    var baseUrl = URL(string: "https://www.novelupdates.com")!
    var searchEndpoint = URL(string: "https://www.novelupdates.com/wp-admin/admin-ajax.php")!
    weak var delegate: WNServiceProviderDelegate?
    
    enum ListingService: String {
        case ranking = "series-ranking"
        case all = "novelslisting"
        case latest = "latest-series"
    }
    
    private func requestUrl(for listingService: ListingService) -> URL {
        return baseUrl.appendingPathComponent(listingService.rawValue, isDirectory: true)
    }
    
    /// Constructs a promise wrapping the html response string for the specified listing service fetch request
    /// - Parameter listingService: Listing service to use. Either `ranking`, `latest`, or `all`.
    /// - Returns: A promise wrapping the html response string.
    private func htmlListingRequestResponse(for listingService: ListingService, parameters: Parameters = [:]) -> Promise<String> {
        return Promise {seal in
            Alamofire.request(requestUrl(for: listingService), parameters: parameters)
                .validate()
                .response { response in
                guard let data = response.data, let htmlStr = String(data: data, encoding: .utf8) else {
                    let err = WNError.unknownResponseError
                    seal.reject(response.error ?? err)
                    return
                }
                seal.fulfill(htmlStr)
            }
        }
    }
    
    /// Extracts WN entries from raw html response string.
    private func extractEntries(_ htmlStr: String) throws -> Promise<[WNItem]> {
        return Promise {seal in
            let doc = try SwiftSoup.parse(htmlStr)
            // #myTable is a table containing the listing of novels
            guard let tbl = try doc.getElementById("myTable") else {
                seal.reject(WNError.parsingError("failed to find content table"))
                return
            }
            // Each entry is a light novel synopsis
            let entries = try tbl.getElementsByClass("bdrank")
            var webNovels = [WNItem]()
            for entry in entries {
                let wn = try parseEntry(entry)
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
    private func parseEntry(_ entry: Element) throws -> WNItem {
        let wn = WNItem()
        // In some cases rank does not exist, in which case the index should shift by 1
        var index = 0
        if let rank = try entry.child(index).getElementsByClass("ranknum").first() {
            wn.rank = Int(try rank.text()) ?? -1
            index += 1
        }
        if let rating = try entry.child(index).getElementsByClass("lstrate").first() {
            let ratingTxt = try rating.text()
                .replacingOccurrences(of: "[()]", with: "", options: .regularExpression)
            wn.rating = Double(ratingTxt) ?? 0.0
        }
        wn.organization = try entry.child(index + 1).child(0).text()
        if let main = entry.children().last() {
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
                wn.fullDescription = wn.shortDescription! + "\n" + wn.fullDescription!
            }
            if let releases = try main.getElementsByClass("sfstext").first() {
                let releasesTxt = try releases.text()
                    .replacingOccurrences(of: "[^0-9]+", with: "", options: .regularExpression)
                wn.releases = Int(releasesTxt) ?? 0
            }
        }
        return wn
    }
    
    /// Fetches web novel entries for the specified listing service type
    /// Notifies delegate upon completion of data task
    func fetchEntries(for: ListingService, page: Int) {
        let parameters: Parameters = [
            "pg": page
        ]
        firstly {
            htmlListingRequestResponse(for: .ranking, parameters: parameters)
            }.then { htmlStr in
                try self.extractEntries(htmlStr)
            }.done { entries in
                self.delegate?.wnEntriesFetched(entries)
            }.catch { err in
                debugPrint(err)
        }
    }
    
    /// Searches matching WN by the given query.
    /// Notifies delegate upon completion of data task.
    func search(_ query: String) {
        firstly {
            htmlSearchRequestResponse(query: query)
        }.map {html in
            try self.parseSearchResults(html)
        }.done {
            self.delegate?.searchCompleted($0)
        }.catch {err in
            print(err)
        }
    }
    
    /// Parses the html response string from the search request.
    /// - Parameter htmlResponse:
    /// HTML string with the following form:
    /// ul > li, where each li contains a <a> and a <span>
    /// <a> contains the link to the WN, whereas <span> contains the name of the WN.
    /// - Returns: An array of WNItem objects, with only `title` and `url`.
    private func parseSearchResults(_ htmlResponse: String) throws -> [WNItem] {
        let doc = try SwiftSoup.parse(htmlResponse)
        guard let ul = try doc.getElementsByTag("ul").first() else {
            throw WNError.parsingError("unable to find <ul> element in search response html")
        }
        let entries = try ul.getElementsByTag("li").map {
            entry -> WNItem in
            let wn = WNItem()
            if let url = try entry.getElementsByTag("a").first()?.attr("href") {
                wn.url = url
            }
            if let title = try entry.getElementsByTag("span").first()?.text() {
                wn.title = title
            }
            return wn
        }
        return entries
    }
    
    /// Promise API for getting html response from a search request.
    /// - Parameter query: Query string to be used for the search request.
    /// - Returns: A promise wrapping an html response string.
    private func htmlSearchRequestResponse(query: String) -> Promise<String> {
        return Promise { seal in
            let parameters: Parameters = [
                "action": "nd_ajaxsearchmain",
                "strType": "desktop",
                "strOne": query
            ]
            Alamofire.request(searchEndpoint, method: .post, parameters: parameters)
                .validate()
                .response { response in
                    guard let data = response.data, let htmlStr = String(data: data, encoding: .utf8) else {
                        let err = WNError.unknownResponseError
                        seal.reject(response.error ?? err)
                        return
                    }
                    seal.fulfill(htmlStr)
            }
        }
    }
}
