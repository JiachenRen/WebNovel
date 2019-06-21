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
    var author: String?
    var url: String?
    var genres: [String]?
    var tags: [String]?
    var language: String?
    var type: String?
    var rank: Int?
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

extension WebNovel: CustomStringConvertible {
    var description: String {
        return """
        Title: \(title ?? "N/A")
        Author: \(author ?? "N/A")
        Aliases: \(aliases?.joined(separator: ", ") ?? "N/A")
        Genres: \(genres?.joined(separator: ", ") ?? "N/A")
        Tags: \(tags?.joined(separator: ", ") ?? "N/A")
        Organization: \(organization ?? "N/A")
        Link: \(url ?? "N/A")
        Cover Image URL: \(coverImageUrl ?? "N/A")
        Rank: \(rank == nil ? "N/A" : String(rank!))
        Rating: \(rating == nil ? "N/A" : String(rating!))
        Votes: \(votes == nil ? "N/A" : String(votes!))
        Releases: \(releases == nil ? "N/A" : String(releases!))
        Language: \(language ?? "N/A")
        Type: \(type ?? "N/A")
        Short Description: \(shortDescription ?? "N/A")
        Full Description: \(fullDescription ?? "N/A")
        """
    }
}
