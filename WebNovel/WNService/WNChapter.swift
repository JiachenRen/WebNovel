//
//  WNChapter.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/15/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit

fileprivate let updateQueue = DispatchQueue(
    label: "com.jiachenren.WebNovel.asyncUpdate",
    qos: .utility,
    attributes: .concurrent,
    autoreleaseFrequency: .workItem,
    target: nil
)

class WNChapter: Serializable, CustomStringConvertible {
    
    typealias ManagedObject = Chapter
    
    /// Reference to the web novel that this chapter belongs to
    let webNovelUrl: String
    
    /// URL from which the chapter is retrieved
    let url: String
    
    /// Id of the chapter
    let id: Int
    
    /// Short name of the chapter, e.g. c32, s3
    var name: String
    
    /// Translation group for the chapter
    var group: String = "Unknown"
    
    /// Wether the chapter is downloaded
    var isDownloaded = false
    
    /// Wether the chapter has been read at least once.
    private(set) var isRead = false
    
    /// When the chapter is last read
    private(set) var lastRead: TimeInterval?
    
    /// Raw html content of the chapter
    var rawHtml: String?
    
    /// This is used to calculate storage space used
    var byteCount: Int?

    /// Provides sanitized chapter content
    var article: Article?
    
    /// Possible articles for that chapter that are obtained by following possible links in the response HTML.
    var alternativeArticles: [Article] = []
    
    init(_ webNovelUrl: String, url: String, name: String, id: Int) {
        self.webNovelUrl = webNovelUrl
        self.url = url
        self.name = name
        self.id = id
    }
    
    /// Extracts chapter number and title from raw title string
    private func parseChapterTitle() -> (chapter: Int, title: String)? {
        guard let rawTitleStr = article?.title else {
            return nil
        }
        var chapter: Int?, title: String?
        let pattern = #"[cC]hapter\s*([0-9]+)[\:\-\s]+(.*)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: rawTitleStr.utf16.count)
        if let match = regex.firstMatch(in: rawTitleStr, options: [], range: range) {
            if let chapterRange = Range(match.range(at: 1), in: rawTitleStr) {
                chapter = Int(rawTitleStr[chapterRange])
            }
            if let titleRange = Range(match.range(at: 2), in: rawTitleStr) {
                title = String(rawTitleStr[titleRange])
            }
        }
        guard let ch = chapter, let t = title else {
            return nil
        }
        return (ch, t)
    }
    
    /// - Returns: Properly formatted chapter title in the following format:
    /// Chapter <#>: <Name>
    func properTitle() -> String? {
        guard let (ch, t) = parseChapterTitle() else {
            return nil
        }
        return "Chapter \(ch): \(t)"
    }
    
    func toggleReadStatus() -> Guarantee<Void> {
        return isRead ? markAsUnread() : markAsRead()
    }
    
    /// Mark the chapter as read and record the current time
    func markAsRead() -> Guarantee<Void> {
        return Guarantee { fulfill in
            updateQueue.async {
                self.isRead = true
                self.lastRead = .now
                WNCache.save(self)
                self.sync {
                    $0.lastReadChapter = self
                }
                postNotification(.chapterReadStatusUpdated)
                fulfill(())
            }
        }
    }
    
    /// Unmark the chapter as read
    func markAsUnread() -> Guarantee<Void> {
        return Guarantee { fulfill in
            updateQueue.async {
                self.isRead = false
                self.lastRead = nil
                WNCache.save(self)
                self.sync {
                    $0.findLastReadChapter()
                }
                postNotification(.chapterReadStatusUpdated)
                fulfill(())
            }
        }
    }
    
    /// Deletes the downloaded content for this chapter from core data
    func delete() -> Guarantee<Void> {
        return Guarantee { fulfill in
            updateQueue.async {
                self.isDownloaded = false
                self.rawHtml = nil
                self.article = nil
                self.byteCount = nil
                WNCache.delete(self)
                self.sync {_ in}
                fulfill(())
            }
        }
    }
    
    /// Synchronizes chapters catalogue with this chapter, make sure that
    /// modifications made to the chapter can be refelected on both ends
    private func sync(_ body: @escaping (WNChaptersCatalogue) -> Void) {
        let cat = retrieveCatalogue()
        cat.chapters[url] = self
        body(cat)
        WNCache.save(cat)
    }
    
    /// Perfrom updates & synchronization asynchronously
    func asyncUpdate(_ body: @escaping (WNChapter, WNChaptersCatalogue) -> Void) -> Guarantee<Void> {
        let chapter = self
        return Guarantee { fulfill in
            updateQueue.async {
                let cat = chapter.retrieveCatalogue()
                body(chapter, cat)
                cat.chapters[chapter.url] = chapter
                WNCache.save(cat)
                WNCache.save(chapter)
                fulfill(())
            }
        }
    }
    
    /// Retrieves the catalogue that this chapter belongs to
    func retrieveCatalogue() -> WNChaptersCatalogue {
        return WNCache.fetch(by: webNovelUrl, object: WNChaptersCatalogue.self)!
    }
    
    func retrieveWebNovel() -> WebNovel {
        return WNCache.fetch(by: webNovelUrl, object: WebNovel.self)!
    }
    
    func nextChapter() -> WNChapter? {
        return retrieveCatalogue().chapter(after: self)
    }
    
    func prevChapter() -> WNChapter? {
        return retrieveCatalogue().chapter(before: self)
    }
    
    var description: String {
        return """
        Web Novel Link: \(webNovelUrl)
        ID: \(id)
        Chapter: \(name)
        Group: \(group)
        Link: \(url)
        Article: \(article?.description ?? "N/A")
        """
    }
}
