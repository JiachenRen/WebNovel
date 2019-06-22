//
//  NUListingService.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/19/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire
import SwiftSoup

/// Novel Updates listing service
class NUListingService {
    
    /// Current sorting criterion to be used for searching
    var sortingCriterion: WNSortingCriterion?
    
    /// If true, listing entries are listed in the ascending order
    var sortAscending: Bool = false
    
    /// Value for the parameter
    var parameterValue: String?
    
    /// Type of listing service.
    /// e.g. .genre, .language
    var serviceType: WNListingServiceType
    
    /// Path component for the listing service.
    /// e.g. path component for "Genre" listing service is "genre"
    var servicePathComponent: String
    
    /// Parameter for the listing service.
    /// e.g. options for Genre are Adventure, Fantasy, etc.
    var parameter: NUParameter?
    
    /// List of available sorting criteria
    var availableCriteria: [WNSortingCriterion]
    
    /// Maps sorting criterion to its corresponding http parameter value
    var criteriaParameterValues: [WNSortingCriterion: String] = [
        .numberOfReleases: "nrelease",
        .rank: "trank",
        .rating: "trate",
        .releaseFrequency: "tfreq",
        .title: "abc",
        .numberOfReaders: "tread",
    ]
    
    init(serviceType: WNListingServiceType, servicePathComponent: String, parameter: NUParameter? = nil, sortingCriteria: [WNSortingCriterion] = []) {
        self.serviceType = serviceType
        self.servicePathComponent = servicePathComponent
        self.parameter = parameter
        self.availableCriteria = sortingCriteria
    }
    
    /// - Parameter page: Page of the listing (usually 25 items per page)
    /// - Parameter parameter: Optinonal parameter for the listing service.
    /// - Parameter criterion: Criterion for sorting the results
    /// - Parameter asc: If true, results are sorted in the ascending order
    /// e.g. "Adventure" is a parameter for listing service "Genre"
    func htmlResponse(for page: Int) throws -> Promise<String> {
        let url = NovelUpdates.baseUrl.appendingPathComponent(servicePathComponent, isDirectory: true)
        var parameters: Parameters = ["pg": page]
        guard let name = parameterValue else {
            return htmlRequestResponse(url, parameters: parameters)
        }
        guard let parameter = self.parameter else {
            throw WNError.invalidListingServiceParameter
        }
        if let crit = sortingCriterion {
            if !availableCriteria.contains(crit) {
                throw WNError.unsupportedSortingCriterion
            }
            parameters["sort"] = criteriaParameterValues[crit]
            parameters["order"] = sortAscending ? "asc" : "desc"
        }
        if parameter.isPathComponent {
            guard let pathComponent = parameter.pathComponent(for: name) else {
                throw WNError.invalidListingServiceParameter
            }
            return htmlRequestResponse(
                url.appendingPathComponent(pathComponent, isDirectory: true),
                parameters: parameters
            )
        } else {
            guard let (key, value) = parameter.urlParameter(for: name) else {
                throw WNError.invalidListingServiceParameter
            }
            parameters[key] = value
            return htmlRequestResponse(url, parameters: parameters)
        }
    }
    
    struct NUParameter {
        var name: String
        
        var isPathComponent: Bool
        
        /// Key: name for the value; Value: value for the parameter
        var values: [String: String]
        
        /// Finds the url parameter value for the common name
        func urlParameter(for valueName: String) -> (key: String, value: String)? {
            if let value = values[valueName] {
                return (name, value)
            }
            return nil
        }
        
        /// Looks up the path component for the name
        func pathComponent(for valueName: String) -> String? {
            if let value = values[valueName] {
                return "/\(value)"
            }
            return nil
        }
    }
}

/// Conform to WNListingService protocol
extension NUListingService: WNListingService {
    var availableParameters: [String] {
        return parameter?.values.keys.map {$0} ?? []
    }
    
    var availableSortingCriteria: [WNSortingCriterion] {
        return availableCriteria
    }
    
    /// Fetches web novel listing for the specified listing service type
    /// Notifies delegate upon completion of data task
    func fetchListing(page: Int) -> Promise<[WebNovel]> {
        return firstly {
            try htmlResponse(for: page)
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
        if let rating = try element.getElementsByClass("lstrate").first() {
            let ratingTxt = try rating.text()
                .replacingOccurrences(of: "[()]", with: "", options: .regularExpression)
            wn.rating = Double(ratingTxt) ?? 0.0
        }
        wn.organization = try element.getElementsByClass("orgalign").first()?.text()
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
                    .replacingOccurrences(of: "[^0-9]+", with: "", options: .regularExpression)
                wn.releases = Int(releasesTxt) ?? 0
            }
        }
        return wn
    }
}
