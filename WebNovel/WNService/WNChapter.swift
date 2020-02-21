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
    
    /// Alternative possible chapter URLs (since in some cases the contents are hidden
    var altChapters: [WNChapter]
    
    /// Content source ID.
    /// 0 = content extracted from main URL
    /// i = using ith alternative chapter
    var contentSourceId: Int
    
    /// Id of the chapter
    let id: Int
    
    /// Short name of the chapter, e.g. c32, s3
    var name: String
    
    /// Translation group for the chapter
    var group: String = "Unknown"
    
    /// Wether the chapter is downloaded
    var isDownloaded = false
    
    /// Wether the chapter has been read at least once.
    private(set) var isRead = false {
        didSet {
            lastRead = isRead ? .now : nil
        }
    }
    
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
    
    /// List of content sources, with the first one being `self`
    var contentSources: [WNChapter] {
        var sources = [self]
        sources.append(contentsOf: altChapters)
        return sources
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
    
    init(_ webNovelUrl: String, url: String, name: String, id: Int) {
        self.webNovelUrl = webNovelUrl
        self.url = url
        self.altChapters = []
        self.contentSourceId = 0
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
    
    func markAs(isRead: Bool, _ cat: WNCatalogue? = nil) {
        self.isRead = isRead
        WNCache.save(self)
        let cat = cat ?? retrieveCatalogue()
        cat.lastReadChapter = isRead ? self.url : nil
        WNCache.save(cat)
    }
    
    /// Deletes the downloaded content for this chapter from core data
    func delete(from cat: WNCatalogue? = nil) {
        isDownloaded = false
        rawHtml = nil
        article = nil
        byteCount = nil
        WNCache.save(self)
        let cat = cat ?? retrieveCatalogue()
        cat.downloadedChaptersDict[url] = nil
        cat.numDownloads -= 1
        cat.lastModified = .now
        WNCache.save(cat)
    }
    
    /// Perfrom updates & synchronization asynchronously
    func asyncUpdate(_ cat: WNCatalogue? = nil, _ body: @escaping (WNChapter, WNCatalogue) -> Void) -> Guarantee<Void> {
        let chapter = self
        return Guarantee { fulfill in
            updateQueue.async {
                let cat = cat ?? chapter.retrieveCatalogue()
                body(chapter, cat)
                WNCache.save(cat)
                WNCache.save(chapter)
                fulfill(())
            }
        }
    }
    
    /// Retrieves the catalogue that this chapter belongs to
    func retrieveCatalogue() -> WNCatalogue {
        return WNCache.fetch(by: webNovelUrl, object: WNCatalogue.self)!
    }
    
    func retrieveWebNovel() -> WebNovel {
        return WNCache.fetch(by: webNovelUrl, object: WebNovel.self)!
    }
    
    func nextChapter() -> WNChapter? {
        guard let url = retrieveCatalogue().chapter(after: self.url) else {
            return nil
        }
        return WNCache.fetch(by: url, object: WNChapter.self)
    }
    
    func prevChapter() -> WNChapter? {
        guard let url = retrieveCatalogue().chapter(before: self.url) else {
            return nil
        }
        return WNCache.fetch(by: url, object: WNChapter.self)
    }
    
    /// The WNChapter that should be presented; i.e. the chapter specified by content source ID.
    /// - Returns: Source chapter
    func contentSourceChapter() -> WNChapter {
        switch contentSourceId {
        case 0:
            return self
        default:
            return altChapters[contentSourceId - 1]
        }
    }
}
