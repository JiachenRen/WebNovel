//
//  NovelUpdates+groupListing.swift
//  WebNovel
//
//  Created by Jiachen Ren on 2/18/20.
//  Copyright © 2020 Jiachen Ren. All rights reserved.
//

import Foundation
import Alamofire
import SwiftSoup
import PromiseKit

extension NovelUpdates {
    /// Downloads translation group listing from Novel Updates
    /// - Parameter collector: Called when a new WNTranslationGroup is fetched.
    /// - Returns
    @discardableResult
    func fetchTranslationGroups(_ resolver: @escaping (PromiseKit.Result<WNTranslationGroup>) -> Void) -> Promise<Void> {
        let url = NovelUpdates.baseUrl.appendingPathComponent(Path.translationGroupsListing.rawValue)
        print("Fetching group listing from \(url)")
        return htmlRequestResponse(url).then { html -> Promise<[Document]> in
            let doc = try SwiftSoup.parse(html)
            let numPages = try self.getGroupListingPageRange(doc)
            print("Retrieved & parsed initial page, found \(numPages).")
            let getPages: [Promise<Document>] = (1...numPages).map { pageNo in
                htmlRequestResponse(
                    url,
                    method: .get,
                    parameters: ["pg": pageNo],
                    encoding: .ascii
                ).tap { _ in
                    print("Retrieved page \(pageNo)")
                }.then { html in
                    parseHtml(html)
                }
            }
            
            return when(fulfilled: getPages)
        }.map { docs -> [URL] in
            try docs.map { doc -> [URL] in
                let links = try self.extractGroupLinks(fromDoc: doc)
                print("Extracted \(links.count) links from doc")
                return links
            }.flatMap { $0 }
        }.then { (groupUrls: [URL]) -> Promise<WNTranslationGroup> in
            var head = Promise { seal in
                seal.fulfill(WNTranslationGroup(name: "dummy", url: "none"))
            }
            groupUrls.forEach { grpUrl in
                head = head.then { dump in
                    htmlRequestResponse(grpUrl)
                        .then { html in
                            parseHtml(html)
                    }.then { doc in
                        self.parseGroupInfo(fromDoc: doc)
                    }.tap(resolver)
                }
            }
            return head
        }.asVoid()
    }
    
    private class Pool<T>: IteratorProtocol {
        func next() -> T? {
            if promises.count > 0 {
                return promises.remove(at: 0)
            }
            return nil
        }
        
        typealias Element = T
        
        var promises: [T]
        
        init(_ promises: [T]) {
            self.promises = promises
        }
    }
    
    /// - Parameter doc: `Document` parsed from group info page
    /// - Returns: `WNTranslationGroup`
    private func parseGroupInfo(fromDoc doc: Document) -> Promise<WNTranslationGroup> {
        return Promise { seal in
            guard let grpInfoTable = try doc.getElementsByClass("groupinfo").first() else {
                seal.reject(WNError.groupListingFailed)
                return
            }
            var groupName = "Unknown"
            var url: String = ""
            try grpInfoTable.getElementsByTag("tr").forEach { row in
                let columns = try row.getElementsByTag("td")
                guard columns.count == 2 else {
                    return
                }
                let key = columns[0].ownText()
                let value = columns[1].ownText()
                if key.lowercased() == "group name" {
                    groupName = value
                }
                if let link = try row.getElementsByTag("a").first()
                    , link.ownText().lowercased() == "link" {
                    url = try link.attr("href")
                }
            }
            print("Parsed group info \"\(groupName)\" (\(url))")
            seal.fulfill(WNTranslationGroup(name: groupName, url: url))
        }
    }
    
    /// Extract Novel Update links to the groups present in the document
    /// - Parameter doc: `Document` parsed from group listing page
    private func extractGroupLinks(fromDoc doc: Document) throws -> [URL] {
        let wrappers = try doc.getElementsByClass("wpb_wrapper")
        return try wrappers.map {
            try $0.getElementsByTag("a").map {
                try $0.attr("href")
            }
        }
        .flatMap { $0 }
        .compactMap { URL(string: $0) }
    }
    
    /// - Parameter doc: `Document` parsed from group listing page
    /// - Returns: Max page number for group listings
    private func getGroupListingPageRange(_ doc: Document) throws -> Int {
        guard let pagination = try doc.getElementsByClass("digg_pagination").first() else {
            throw WNError.groupListingFailed
        }
        let pageNumbers = pagination.children().compactMap { Int($0.ownText()) }
        var max = Int.min
        for num in pageNumbers {
            max = num > max ? num : max
        }
        return max
    }
}
