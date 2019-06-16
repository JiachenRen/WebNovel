//
//  NovelUpdates+loadDetails.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/15/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftSoup

extension NovelUpdates {
    
    /// Get the details of the web novel from its summary page.
    func loadDetails(_ wn: WebNovel, cachePolicy: WNCache.Policy) -> Promise<WebNovel> {
        if cachePolicy == .usesCache, let url = wn.url {
            if let wn = try! WNCache.fetchWebNovel(by: url) {
                return Promise { seal in
                    seal.fulfill(wn)
                }
            }
        }
        return wn.html().map { html in
            let doc = try SwiftSoup.parse(html)
            try self.parseDetails(doc, wn)
            return wn
        }.get { wn in
            try WNCache.save(wn)
        }
    }
    
    /// Parse detailed information from response html document
    private func parseDetails(_ doc: Document, _ wn: WebNovel) throws {
        wn.title = try doc.getElementsByClass("seriestitlenu").first()?.text()
        wn.fullDescription = try doc.getElementById("editdescription")?.children().reduce("") {
            try $0 + "\n" + $1.html()
        }
        wn.aliases = try doc.getElementById("editassociated")?.html().components(separatedBy: "<br>")
        wn.type = try doc.getElementById("showtype")?.getElementsByTag("a").first()?.text()
        wn.genres = try doc.getElementById("seriesgenre")?.children().map {
            try $0.text()
        }
        wn.tags = try doc.getElementById("showtags")?.children().map {
            try $0.text()
        }
        wn.language = try doc.getElementById("showlang")?.child(0).text()
        wn.author = try doc.getElementById("authtag")?.text()
        if let txt = try doc.getElementsByClass("uvotes").first()?.text() {
            let components = txt.components(separatedBy: ",")
            let ratingStr = components[0].components(separatedBy: "/")[0]
                .replacingOccurrences(of: "(", with: "")
                .trimmingCharacters(in: .whitespaces)
            wn.rating = Double(ratingStr)
            let votesStr = components[1].replacingOccurrences(of: nonDigitRegex, with: "", options: .regularExpression)
            wn.votes = Int(votesStr)
        }
        wn.coverImageUrl = try doc.getElementsByClass("seriesimg")
            .first()?.getElementsByTag("img")
            .first()?.attr("src")
    }
}
