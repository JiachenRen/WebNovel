//
//  WNChapter.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/15/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

class WNChapter: Serializable, CustomStringConvertible {
    var url: String?
    var chapter: String
    var date: String?
    var title: String?
    var content: String?
    var id: Int
    
    static var entityName: String = "Chapter"
    
    enum Keys: String {
        case chapter, url, id, date, title, content
    }
    
    init(url: String, chapter: String, id: Int) {
        self.url = url
        self.chapter = chapter
        self.id = id
    }
    
    var description: String {
        return """
        ID: \(id)
        Chapter: \(chapter)
        Link: \(url ?? "N/A")
        Title: \(title ?? "N/A")
        Date: \(date ?? "N/A")
        Content: \(content ?? "N/A")
        """
    }
}
