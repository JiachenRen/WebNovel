//
//  WNChaptersCatalogue.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

fileprivate var order: (WNChapter, WNChapter) -> Bool = {$0.id < $1.id}

class WNChaptersCatalogue: Serializable {
    typealias ManagedObject = ChaptersCatalogue
    
    /// - Warning: chapters are unsorted
    var chapters: [WNChapter]
    
    /// Url for the WN that this catalogue belongs
    var url: String
    
    /// Last time the catalogue is updated
    var lastModified: TimeInterval
    
    /// Whether any of the chapters in the catalogue is downloaded
    var hasDownloads: Bool {
        for chapter in chapters {
            if chapter.isDownloaded {
                return true
            }
        }
        return false
    }
    
    /// Only returns chapters that are downloaded
    var downloadedChapters: [WNChapter] {
        return chapters.filter {$0.isDownloaded}
    }
    
    init(_ url: String, _ chapters: [WNChapter]) {
        self.url = url
        self.chapters = chapters
        lastModified = .now
    }
    
    /// Calculates storage space used in KB
    /// - Returns: The total storage space used by the downloaded chapters
    func storageSpaceUsed() -> String {
        let totalBytes = chapters.filter {
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
        self.chapters = chapters.compactMap {
            try? WNCache.fetch(by: $0.url, object: WNChapter.self)
        }
    }
}

extension WNChaptersCatalogue: CustomStringConvertible {
    var description: String {
        return """
        Web Novel URL: \(url)
        Chapters:
        \(chapters.map {"\($0)"}.joined(separator: "\n\n"))
        """
    }
}
