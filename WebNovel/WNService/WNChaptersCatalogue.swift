//
//  WNChaptersCatalogue.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

class WNChaptersCatalogue: Serializable {
    var chapters: [WNChapter]
    
    /// Url for the WN that this catalogue belongs
    var url: String?
    
    static var entityName: String = "ChaptersCatalogue"
    
    init(_ url: String, _ chapters: [WNChapter]) {
        self.url = url
        self.chapters = chapters
    }
}

extension WNChaptersCatalogue: CustomStringConvertible {
    var description: String {
        return """
        Web Novel URL: \(url ?? "N/A")
        Chapters:
        \(chapters.map {"\($0)"}.joined(separator: "\n\n"))
        """
    }
}
