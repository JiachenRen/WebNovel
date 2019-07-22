//
//  WNCatalogue.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit

fileprivate let queue = DispatchQueue(label: "com.jiachenren.WebNovel.catalogueOperation", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)

class WNCatalogue: Serializable {
    typealias ManagedObject = Catalogue
    
    /// WN translation groups
    struct Group: Codable {
        var name: String
        var isEnabled: Bool
        var chapterUrls: [String]
    }
    
    /// All available translation groups
    var groups: [String: Group] {
        didSet {updateEnabledChapterUrls()}
    }
    
    /// Chapters ordered by release date
    let orderedChapters: [String: Int]
    
    /// Chapter URLs for enabled groups
    var enabledChapterUrls: [String] = []
    
    /// Dictionary for downloaded chapters
    var downloadedChaptersDict: [String: Bool] = [:]
    
    /// URLs for downloaded chapters
    var downloadedChapterUrls: [String] {
        return enabledChapterUrls.filter {downloadedChaptersDict[$0] == true}
    }
    
    /// Url for the WN that this catalogue belongs
    let url: String
    
    /// Last time the catalogue is updated
    var lastModified: TimeInterval
    
    /// Chapter that has most recently been read
    var lastReadChapter: String? {
        didSet {
            lastRead = lastReadChapter == nil ? nil : .now
        }
    }
    
    var lastRead: TimeInterval?
    
    /// Whether any of the chapters in the catalogue is downloaded
    var numDownloads: Int = 0
    
    /// First chapter of the WN, chronologically
    var firstChapter: String? {
        return enabledChapterUrls.first
    }
    
    init(_ url: String, _ groups: [Group], _ chapterOrder: [String: Int]) {
        self.url = url
        self.orderedChapters = chapterOrder
        self.groups = groups.reduce(into: [:]) {
            $0[$1.name] = $1
        }
        lastModified = .now
        updateEnabledChapterUrls()
    }
    
    private func updateEnabledChapterUrls() {
        enabledChapterUrls = groups.values.filter {$0.isEnabled}
            .flatMap {$0.chapterUrls}
            .sorted {
                orderedChapters[$0]! < orderedChapters[$1]!
        }
    }
    
    func async<T>(_ body: @escaping (WNCatalogue) -> T) -> Guarantee<T> {
        return Guarantee { fulfill in
            queue.async {
                fulfill(body(self))
            }
        }
    }
    
    /// Calculates storage space used in KB
    /// - Returns: The total storage space used by the downloaded chapters
    static func calculateStorageSpaceUsed(_ chapters: [WNChapter]) -> String {
        let totalBytes = chapters.filter {
                $0.isDownloaded
            }.compactMap {
                $0.byteCount
            }.reduce(0) {
                $0 + $1
        }
        
        return Data.size(format: [.useKB, .useMB], bytesCount: totalBytes)
    }
    
    enum Criterion {
        case downloaded
        case enabled
        case all
    }
    
    /// Load all enabled chapters
    /// - Returns: Downloaded chapters sorted by ascending ID number
    /// - Warning: This is very expensive
    func loadChapters(_ criterion: Criterion = .enabled) -> Guarantee<[WNChapter]> {
        return async { cat in
            var urls: [String]
            switch criterion {
            case .downloaded:
                urls = cat.downloadedChapterUrls
            case .enabled:
                urls = cat.enabledChapterUrls
            case .all:
                urls = cat.orderedChapters.sorted {$0.value < $1.value}.map {$0.key}
            }
            return urls.compactMap {
                WNCache.fetch(by: $0, object: WNChapter.self)
            }
        }
    }
    
    /// - Returns: The chapter after the given chapter
    func chapter(after chapterUrl: String) -> String? {
        let urls = enabledChapterUrls
        let idx = index(for: chapterUrl) + 1
        if idx < urls.count && idx >= 0 {
            return urls[idx]
        }
        return nil
    }
    
    /// - Returns: The chapter url brefore the given chapter url
    func chapter(before chapterUrl: String) -> String? {
        let urls = enabledChapterUrls
        let idx = index(for: chapterUrl) - 1
        if idx < urls.count && idx >= 0 {
            return urls[idx]
        }
        return nil
    }
    
    /// - Returns: Index for the chapter in enabled groups.
    func index(for chapterUrl: String) -> Int {
        for (idx, url) in enabledChapterUrls.enumerated() {
            if url == chapterUrl {
                return idx
            }
        }
        fatalError()
    }
    
}
