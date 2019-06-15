//
//  WNItem.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/14/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit
import CoreGraphics
import Alamofire

/// Represents a web novel object.
/// The variables are self explanatory
class WNItem {
    var shortDescription: String?
    var fullDescription: String?
    var organization: String?
    var title: String?
    var url: String?
    var genres: [String] = []
    var rank: Int?
    var rating: Double?
    var releases: Int?
    
    private func getUrl() -> Promise<String> {
        return Promise { seal in
            guard let url = self.url else {
                seal.reject(WNError.urlNotFound)
                return
            }
            seal.fulfill(url)
        }
    }
}

extension WNItem: CustomStringConvertible {
    var description: String {
        return """
        Title: \(title ?? "N/A")
        Genres: \(genres.joined(separator: ", "))
        Organization: \(organization ?? "N/A")
        Link: \(url ?? "N/A")
        Rank: \(rank == nil ? "N/A" : String(rank!))
        Rating: \(rating == nil ? "N/A" : String(rating!))
        Releases: \(releases == nil ? "N/A" : String(releases!))
        Short Description: \(shortDescription ?? "N/A")
        Full Description: \(fullDescription ?? "N/A")
        """
    }
}
