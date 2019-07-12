//
//  WNServiceProvider+search.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/15/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire
import SwiftSoup

extension NovelUpdates {
    
    /// Searches matching WN by the given query.
    /// Notifies delegate upon completion of data task.
    func search(byName query: String) -> Promise<[WebNovel]> {
        return htmlSearchRequestResponse(query: query).map {
            try self.parseSearchResults($0)
        }
    }
    
    /// Promise API for getting html response from a search request.
    /// - Parameter query: Query string to be used for the search request.
    /// - Returns: A promise wrapping an html response string.
    private func htmlSearchRequestResponse(query: String) -> Promise<String> {
        let parameters: Parameters = [
            "action": "nd_ajaxsearchmain",
            "strType": "desktop",
            "strOne": query
        ]
        return htmlRequestResponse(serviceEndpoint, method: .post, parameters: parameters)
    }
    
    /// Parses the html response string from the search request.
    /// - Parameter htmlResponse:
    /// HTML string with the following form:
    /// ul > li, where each li contains a <a> and a <span>
    /// <a> contains the link to the WN, whereas <span> contains the name of the WN.
    /// - Returns: An array of WebNovel objects, with only `title` and `url`.
    private func parseSearchResults(_ htmlResponse: String) throws -> [WebNovel] {
        let doc = try SwiftSoup.parse(htmlResponse)
        guard let ul = try doc.getElementsByTag("ul").first() else {
            throw WNError.parsingError("unable to find <ul> element in search response html")
        }
        let entries = try ul.getElementsByTag("li").map {
            entry -> WebNovel in
            guard let url = try entry.getElementsByTag("a").first()?.attr("href") else {
                throw WNError.urlNotFound
            }
            let wn = WebNovel(url, NovelUpdates.identifier)
            if let title = try entry.getElementsByTag("span").first()?.text() {
                wn.title = title
            }
            return wn
        }
        return entries
    }
}
