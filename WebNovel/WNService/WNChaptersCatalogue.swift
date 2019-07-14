//
//  WNChaptersCatalogue.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

class WNChaptersCatalogue: Serializable {
    typealias ManagedObject = ChaptersCatalogue
    
    /// WN translation groups
    struct Group: Codable {
        var name: String
        var isEnabled: Bool
    }
    
    /// - Key: Chapter URL string;
    /// - Value: Chapter
    var chapters: [String: WNChapter]
    
    /// All available translation groups
    var groups: [Group] = []
    
    /// Url for the WN that this catalogue belongs
    var url: String
    
    /// Last time the catalogue is updated
    var lastModified: TimeInterval
    
    /// Chapter that has most recently been read
    var lastReadChapter: WNChapter?
    
    /// Whether any of the chapters in the catalogue is downloaded
    var hasDownloads: Bool {
        for chapter in chapters.values {
            if chapter.isDownloaded {
                return true
            }
        }
        return false
    }
    
    /// Only returns chapters that are downloaded
    var downloadedChapters: [WNChapter] {
        return chapters.values.filter {$0.isDownloaded}
    }
    
    /// First chapter of the WN, chronologically
    var firstChapter: WNChapter? {
        return chapters.values.sorted(by: {$0.id < $1.id}).first
    }
    
    init(_ url: String, _ chapters: [WNChapter]) {
        self.url = url
        self.chapters = chapters.reduce(into: [:]) {
            $0[$1.url] = $1
        }
        lastModified = .now
    }
    
    /// Calculates storage space used in KB
    /// - Returns: The total storage space used by the downloaded chapters
    func storageSpaceUsed() -> String {
        let totalBytes = chapters.values.filter {
                $0.isDownloaded
            }.compactMap {
                $0.byteCount
            }.reduce(0) {
                $0 + $1
        }
        
        return Data.size(format: [.useKB, .useMB], bytesCount: totalBytes)
    }
    
    /// Reload all chapters from core data
    /// - Returns: Downloaded chapters sorted by ascending ID number
    /// - Warning: This is very expensive
    func reloadChapters() {
        chapters.keys.forEach {
            self.chapters[$0] = WNCache.fetch(by: $0, object: WNChapter.self)
        }
    }
    
    /// Finds the chapter that's been most recently read
    func findLastReadChapter() {
        lastReadChapter = chapters.values.filter {$0.isRead && $0.lastRead != nil}
            .sorted {$0.lastRead! > $1.lastRead!}
            .first
    }
    
    /// - Returns: The chapter after the given chapter
    func chapter(after ch: WNChapter) -> WNChapter? {
        for cand in chaptersForEnabledGroups().sorted(by: {$0.id < $1.id}) {
            if cand.id > ch.id {
                return cand
            }
        }
        return nil
    }
    
    /// - Returns: The chapter brefore the given chapter
    func chapter(before ch: WNChapter) -> WNChapter? {
        for cand in chaptersForEnabledGroups().sorted(by: {$0.id > $1.id}) {
            if cand.id < ch.id {
                return cand
            }
        }
        return nil
    }
    
    /// - Returns: Chapters for enabled translation groups
    func chaptersForEnabledGroups() -> [WNChapter] {
        let enabledGroups = groups.filter {$0.isEnabled}
        return chapters.values.filter { ch in
            enabledGroups.contains(where: {ch.group ==  $0.name})
        }
    }
    
    /// - Returns: Index for the chapter in enabled groups.
    func index(for chapter: WNChapter) -> Int {
        return chaptersForEnabledGroups()
            .sorted {$0.id < $1.id}
            .binarySearch(for: chapter) {$0.id}!
    }
    
}

extension WNChaptersCatalogue: CustomStringConvertible {
    var description: String {
        return """
        Web Novel URL: \(url)
        Chapters:
        \(chapters.keys.map {"\($0)"}.joined(separator: "\n"))
        """
    }
}
