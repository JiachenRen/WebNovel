//
//  WNChapter.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/15/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

class WNChapter: CustomStringConvertible {
    var chapter: String
    var url: String
    var date: String?
    var title: String?
    var content: String?
    
    init(url: String, chapter: String) {
        self.url = url
        self.chapter = chapter
    }
    
    var description: String {
        return """
        Chapter: \(chapter)
        Link: \(url)
        Title: \(title ?? "N/A")
        Date: \(date ?? "N/A")
        Content: \(content ?? "N/A")
        """
    }
}
