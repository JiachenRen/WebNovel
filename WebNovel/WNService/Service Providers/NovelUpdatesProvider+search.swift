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

extension NovelUpdatesProvider {
    
    /// Searches matching WN by the given query.
    /// Notifies delegate upon completion of data task.
    func search(byName query: String) {
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
    
    /// Promise API for getting html response from a search request.
    /// - Parameter query: Query string to be used for the search request.
    /// - Returns: A promise wrapping an html response string.
    private func htmlSearchRequestResponse(query: String) -> Promise<String> {
        let parameters: Parameters = [
            "action": "nd_ajaxsearchmain",
            "strType": "desktop",
            "strOne": query
        ]
        return htmlRequestResponse(searchEndpoint, method: .post, parameters: parameters)
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
}
