//
//  WNParser.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/15/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit
import JavaScriptCore

class WNParser {
    
    /// Readability parser
    private static var readability: Readability = Readability()
    private static let queue = DispatchQueue(label: "com.jiachenren.WebNovel.parsing", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    /// Parses WN chapter from given raw html
    /// - Parameter html: Raw html string for the WN chapter
    /// - Parameter url: The  host url is used for figuring out the extraction method for the chapter.
    /// - Parameter chapter: Parsed info is merged into existing chapter object
    static func parse(_ html: String, _ url: URL, mergeInto chapter: WNChapter) -> Guarantee<WNChapter> {
        return Guarantee { fulfill in
            queue.async {
                // Save chapter raw html string
                chapter.rawHtml = html
                
                // Since there are countless websites for WN out there, it is not possible
                // to have a host specific parser for every one of them.
                // Therefore, Readability is used as a generic parser. (It is used by Fire Fox for its reader's view)
                chapter.article = readability.parse(html)
                fulfill(chapter)
            }
        }
    }
    
    /// Extracts possible chapter links from raw HTML
    static func extractPossibleChapterLinks() {
        
    }
}
