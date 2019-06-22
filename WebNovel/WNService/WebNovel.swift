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
    var shortDescription: String?
    var fullDescription: String?
    var organization: String?
    var title: String?
    var authors: [String]?
    var url: String?
    var genres: [String]?
    var tags: [String]?
    var language: String?
    var type: String?
    var weeklyRank: Int?
    var monthlyRank: Int?
    var allTimeRank: Int?
    var rating: Double?
    var votes: Int?
    var aliases: [String]?
    var releases: Int?
    var status: String?
    var coverImageUrl: String?
    
    static var entityName: String = "Novel"
    
    private func getUrl() -> Promise<String> {
        return Promise { seal in
            guard let url = self.url else {
                seal.reject(WNError.urlNotFound)
                return
            }
            seal.fulfill(url)
        }
    }
    
    /// Get the html response string that the URL points to.
    func html() -> Promise<String> {
        return getUrl().then {
            htmlRequestResponse($0)
        }
    }
}

fileprivate func str(_ arr: [String]?) -> String{
    return arr?.joined(separator: ", ") ?? "N/A"
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
        Link: \(str(url))
        Cover Image URL: \(str(coverImageUrl))
        Weekly Rank: \(str(weeklyRank))
        Monthly Rank: \(str(monthlyRank))
        All Time Rank: \(str(allTimeRank))
        Rating: \(str(rating))
        Votes: \(str(votes))
        Releases: \(str(releases))
        Language: \(language ?? "N/A")
        Type: \(str(type))
        Short Description: \(str(shortDescription))
        Full Description: \(str(fullDescription))
        """
    }
}
