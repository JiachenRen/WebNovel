//
//  WebNovel.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/14/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit
import UIKit
import Alamofire

/// Represents a web novel object.
/// The variables are self explanatory
class WebNovel: Serializable {
    typealias ManagedObject = Novel
    
    var shortDescription: String?
    var fullDescription: String?
    var organization: String?
    var title: String?
    var authors: [String]?
    var url: String
    var serviceProviderIdentifier: String
    var genres: [String]?
    var tags: [String]?
    var language: String?
    var type: String?
    var weeklyRank: Int?
    var monthlyRank: Int?
    var allTimeRank: Int?
    var rating: Double?
    var votes: Int?
    var readers: Int?
    var year: Int?
    var updateFrequency: String?
    var aliases: [String]?
    var status: String?
    var coverImageUrl: String?
    var relatedSeries: [WebNovel]?
    var recommendations: [WebNovel]?
    
    init(_ url: String, _ identifer: String) {
        self.serviceProviderIdentifier = identifer
        self.url = url
    }
    
    /// Get the html response string that the URL points to.
    func html() -> Promise<String> {
        return htmlRequestResponse(url)
    }
    
    func loadCoverImage() -> WNCoverImage? {
        guard let url = coverImageUrl else {
            return nil
        }
        return WNCache.fetch(by: url, object: WNCoverImage.self)
    }
}

fileprivate func str(_ arr: [CustomStringConvertible]?) -> String {
    return arr?.map {$0.description}.joined(separator: ", ") ?? "N/A"
}

fileprivate func str<T: LosslessStringConvertible>(_ n: T?) -> String {
    return n == nil ? "N/A" : String(n!)
}

fileprivate func str(_ s: String?) -> String {
    return s ?? "N/A"
}

extension WebNovel: CustomStringConvertible {
    var description: String {
        return """
        Title: \(str(title))
        Author: \(str(authors))
        Aliases: \(str(aliases))
        Status: \(str(status))
        Genres: \(str(genres))
        Tags: \(str(tags))
        Organization: \(str(organization))
        Link: \(url)
        Cover Image URL: \(str(coverImageUrl))
        Weekly Rank: \(str(weeklyRank))
        Monthly Rank: \(str(monthlyRank))
        All Time Rank: \(str(allTimeRank))
        Rating: \(str(rating))
        Votes: \(str(votes))
        Readers: \(str(readers))
        Language: \(language ?? "N/A")
        Type: \(str(type))
        Related Series: \(str(relatedSeries))
        Recommendations: \(str(recommendations))
        Short Description: \(str(shortDescription))
        Full Description: \(str(fullDescription))
        """
    }
}
