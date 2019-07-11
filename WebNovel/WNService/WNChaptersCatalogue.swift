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
    
    var chapters: [WNChapter]
    
    /// Urls for the downloaded chapters
    var downloadedChapterUrls: [String] = []
    
    /// Url for the WN that this catalogue belongs
    var url: String
    
    /// Last time the catalogue is updated
    var lastModified: TimeInterval
    
    init(_ url: String, _ chapters: [WNChapter]) {
        self.url = url
        self.chapters = chapters
        lastModified = .now
    }
    
    /// Calculates storage space used in KB
    /// - Returns: The total storage space used by the downloaded chapters
    func storageSpaceUsed() -> String {
        let totalBytes = downloadedChapterUrls.compactMap {
            try? WNCache.fetch(by: $0, object: WNChapter.self)?.serializedByteCount()
            }
            .reduce(0) {
                $0 + $1
        }
        
        return Data.size(format: [.useKB, .useMB], bytesCount: totalBytes)
    }
    
    /// Only downloaded chapter urls are kept to save space
    /// This retrieves the downloaded chapters from core data using their urls.
    /// - Returns: Downloaded chapters sorted by ascending ID number
    /// - Warning: This is very expensive
    func retrieveDownloads() -> [WNChapter] {
        return downloadedChapterUrls.compactMap {
            try? WNCache.fetch(by: $0, object: WNChapter.self)
        }.sorted {
            $0.id < $1.id
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
