//
//  NovelUpdates+listing.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import SwiftSoup
import PromiseKit
import Alamofire

extension NovelUpdates {
    
    /// List of available listing service types
    var listingServices: [WNListingService] {
        return listingServiceProviders.map {
            $0.service
        }
    }
    
    private var listingServiceProviders: [ListingServiceProvider] {
        return [
            .init(service: .popularMonthlyRanking, path: "series-ranking", parameters: ["rank": "popmonth"]),
            .init(service: .all, path: "novelslisting"),
            .init(service: .latest, path: "latest-series")
        ]
    }
    
    class ListingServiceProvider {
        var service: WNListingService
        var path: String
        var parameters: Parameters
        
        init(service: WNListingService, path: String, parameters: Parameters = [:]) {
            self.service = service
            self.path = path
            self.parameters = parameters
        }
        
        func htmlResponse(for page: Int) -> Promise<String> {
            let url = NovelUpdates.baseUrl.appendingPathComponent(path, isDirectory: true)
            var parameters = self.parameters
            parameters["pg"] = page
            return htmlRequestResponse(url, parameters: parameters)
        }
        
    }
    
    /// Fetches web novel listing for the specified listing service type
    /// Notifies delegate upon completion of data task
    func fetchListing(for listingService: WNListingService, page: Int) -> Promise<[WebNovel]> {
        guard let provider = listingServiceProviders.filter({$0.service == listingService}).first else {
            return Promise { seal in
                seal.reject(WNError.unsupportedListingService)
            }
        }
        return firstly {
            provider.htmlResponse(for: page)
        }.then { htmlStr in
            try self.parseListing(htmlStr)
        }
    }
    
    /// Extracts WN entries from raw html response string.
    private func parseListing(_ htmlStr: String) throws -> Promise<[WebNovel]> {
        return Promise {seal in
            let doc = try SwiftSoup.parse(htmlStr)
            // #myTable is a table containing the listing of novels
            guard let tbl = try doc.getElementById("myTable") else {
                seal.reject(WNError.parsingError("failed to find content table"))
                return
            }
            // Each entry contains metadata for the web novel
            let entries = try tbl.getElementsByClass("bdrank")
            var webNovels = [WebNovel]()
            for entry in entries {
                let wn = try parseWebNovel(entry)
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
    private func parseWebNovel(_ element: Element) throws -> WebNovel {
        let wn = WebNovel()
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
}
