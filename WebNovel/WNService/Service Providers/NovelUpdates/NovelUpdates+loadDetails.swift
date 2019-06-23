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
            if let wn = try! WNCache.fetchWebNovel(url) {
                return Promise { seal in
                    print("Loaded details for WN at URL \(url) from cache")
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
            print("Saved details for wn at \(wn.url!) to core data")
        }
    }
    
    /// Parse detailed information from response html document
    private func parseDetails(_ doc: Document, _ wn: WebNovel) throws {
        wn.title = try doc.getElementsByClass("seriestitlenu").first()?.text()
        wn.fullDescription = try doc.getElementById("editdescription")?.children()
            .reduce("") {
            try ($0 == "" ? "" : $0 + "\n") + $1.text()
        }
        wn.aliases = try doc.getElementById("editassociated")?.html().components(separatedBy: "<br>").map {
            $0.replacingOccurrences(of: "\n", with: "")
        }
        wn.type = try doc.getElementById("showtype")?.getElementsByTag("a").first()?.text()
        wn.genres = try doc.getElementById("seriesgenre")?.children().map {
            try $0.text()
        }
        wn.tags = try doc.getElementById("showtags")?.children().map {
            try $0.text()
        }
        wn.language = try doc.getElementById("showlang")?.child(0).text()
        wn.authors = try doc.getElementById("showauthors")?.children().map {
            try $0.text()
        }.filter {
            $0 != ""
        }
        if let txt = try doc.getElementsByClass("uvotes").first()?.text() {
            let components = txt.components(separatedBy: ",")
            let ratingStr = components[0].components(separatedBy: "/")[0]
                .replacingOccurrences(of: "(", with: "")
                .trimmingCharacters(in: .whitespaces)
            wn.rating = Double(ratingStr)
            let votesStr = components[1].replacingOccurrences(of: "[^0-9]+", with: "", options: .regularExpression)
            wn.votes = Int(votesStr)
        }
        if let readers = try doc.getElementsByClass("rlist").first()?.text() {
            wn.readers = Int(readers)
        }
        if let year = try doc.getElementById("edityear")?.text() {
            wn.year = Int(year)
        }
        var status = 0
        var recommendations: [WebNovel] = []
        var related: [WebNovel] = []
        try doc.getElementsByClass("wpb_wrapper").last()?
            .children().forEach { child in
            let txt = try child.text()
            switch txt {
            case "Related Series":
                status = 1
            case "Recommendations":
                status = 2
            default: break
            }
            if child.id().starts(with: "sid") {
                let wn1 = WebNovel()
                wn1.title = txt
                wn1.url = try child.attr("href")
                if status == 1 {
                    related.append(wn1)
                } else if status == 2 {
                    recommendations.append(wn1)
                }
            }
            wn.recommendations = recommendations.count > 0 ? recommendations : nil
            wn.relatedSeries = related.count > 0 ? related : nil
        }
        wn.status = try doc.getElementById("editstatus")?.text()
        wn.coverImageUrl = try doc.getElementsByClass("seriesimg")
            .first()?.getElementsByTag("img")
            .first()?.attr("src")
            .addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        let paths: [ReferenceWritableKeyPath<WebNovel, Int?>] = [
            \.weeklyRank, \.monthlyRank, \.allTimeRank
        ]
        for (idx, rank) in try doc.getElementsByClass("userrate rank").enumerated() {
            if idx < paths.count {
                wn[keyPath: paths[idx]] = try Int(rank.text().dropFirst())
            }
        }
    }
}
