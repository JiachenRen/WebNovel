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
        .chapters: "5",
        .frequency: "1",
        .rank: "2",
        .rating: "3",
        .readers: "4",
        .reviews: "6",
        .title: "7",
        .lastUpdated: "8"
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
            parameters["order"] = sortAscending ? "1" : "2"
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
            // Each entry contains metadata for the web novel
            let entries = try doc.getElementsByClass("search_main_box_nu")
            if entries.count == 0 {
                throw WNError.parsingError("Web novel entries not found")
            }
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
        if let rating = try element.getElementsByClass("search_ratings").first() {
            let org = try rating.getElementsByTag("span").first()
            wn.organization = try org?.text()
            try org?.remove()
            let ratingTxt = try rating.text()
                .replacingOccurrences(of: "[()]", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            wn.rating = Double(ratingTxt) ?? 0.0
        }
        if let main = try element.getElementsByClass("search_body_nu").first() {
            if let link = try main.getElementsByClass("search_title")
                .first()?.getElementsByTag("a").first() {
                wn.url = link.getAttributes()?.filter {
                    $0.getKey() == "href"
                    }.first?.getValue() ?? ""
                wn.title = try link.text()
            }
            if let genresContainer = try main.getElementsByClass("search_genre").first() {
                wn.genres = try genresContainer.children().map {
                    try $0.text()
                }
            }
            let classes = [
                "search_title", "search_stats", "search_genre", "dots", "morelink list"
            ]
            try main.children().forEach { child in
                for c in classes {
                    if child.hasClass(c) {
                        try child.remove()
                    }
                }
            }
            wn.fullDescription = try main.text()
            try main.children().forEach {
                if $0.hasClass("testhide") {
                    try $0.remove()
                }
            }
            wn.shortDescription = try main.text()
        }
        return wn
    }
}
