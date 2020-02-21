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
import SwiftSoup

class WNParser {
    
    /// Readability parser
    private static var readability: Readability = Readability()
    
    /// Regex for eliminating non-digit characters
    private static let nonDigitRegex = #"[^0-9]+"#
    
    /// Valid schemes for WN chapter
    private static let validSchemes = Set(["http", "https"])
    
    /// Known web novel translation groups, used for url filtering
    private static let tlGroups: [WNTranslationGroup] = {
        guard let path = Bundle.main.path(forResource: "tl_groups", ofType: "json") else {
            print("File tl_groups.json not found in bundle")
            return []
        }
        print("Loading TL groups JSON file...")
        guard let json = try? String(contentsOfFile: path) else {
            print("Cannot load json from path \(path)")
            return []
        }
        let decoder = JSONDecoder()
        do {
            print("Parsing...")
            return try decoder.decode(
                [WNTranslationGroup].self,
                from: json.data(using: .utf8)!
            )
        } catch let e {
            print(e)
            return []
        }
    }()
    
    /// Known web novel hosts
    private static let knownHosts: Set<String> = {
        Set(tlGroups.compactMap {
            URL(string: $0.url)?.host
        })
    }()
    
    
    /// Keywords in a link that signifies a potential redirect to actual chapter content.
    private static let possibleKeywords = [
        "go to chapter",
        "read chapter here",
        "skip to content"
    ]
    
    private static let excludedKeywords = [
        "comment=",
        "#comment",
        "#respond",
        "twitter",
        "facebook"
    ]
    
    private static let queue = DispatchQueue(
        label: "com.jiachenren.WebNovel.parsing",
        qos: .utility,
        attributes: .concurrent,
        autoreleaseFrequency: .workItem,
        target: nil
    )
    
    /// Parses WN chapter from given raw html
    /// - Parameter html: Raw html string for the WN chapter
    /// - Parameter url: The  host url is used for figuring out the extraction method for the chapter.
    /// - Parameter chapter: Parsed info is merged into existing chapter object
    static func parse(_ html: String, _ url: URL, mergeInto chapter: WNChapter) -> Guarantee<WNChapter> {
        return Guarantee { fulfill in
            queue.async {
                if let links = try? extractPossibleChapterLinks(chapter, html) {
                    print("Found \(links.count) alternative chapter links for chapter \(chapter).")
                    chapter.altChapters = links.map {
                        try? createAltChapter(base: chapter, altLink: $0.altLink, hint: $0.hint)
                    }.compactMap { $0 }
                    if chapter.altChapters.count > 0 {
                        // Default to the source that most likely contains the chapter.
                        print("Filtering...")
                        var id = 0
                        var maxContentLength = 0
                        for (idx, ch) in chapter.contentSources.enumerated() {
                            let significantChars = ch.article?.textContent?
                                .replacingOccurrences(of: #"[ \n]+"#, with: "", options: .regularExpression)
                            if let content = significantChars {
                                if content.count > maxContentLength {
                                    maxContentLength = content.count
                                    id = idx
                                }
                            }
                        }
                        print("Selected source with id \(id) as content provider.")
                        chapter.contentSourceId = id
                    }
                }
                
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
    
    /// Creates an alternative chapter based on provided `chapter` and `altLink`.
    /// - Note: Blocking. Used internally by the parser.
    /// - Parameter hint: The hint for the alternaive link. E.g. "read chapter here," "go to chapter," etc.
    private static func createAltChapter(base chapter: WNChapter, altLink: URL, hint: String) throws -> WNChapter {
        let altChapter = WNChapter(
            chapter.webNovelUrl,
            url: altLink.absoluteString,
            name: hint,
            id: chapter.id
        )
        print("Retrieving alternative chapter from url \(altLink)")
        try htmlRequestResponse(altLink).done { html in
            print("Done. Parsing alt chapter...")
            altChapter.rawHtml = html
            altChapter.article = readability.parse(html)
            print("Done.")
        }.wait()
        return altChapter
    }
    
    /// Extracts possible chapter links from raw HTML.
    ///
    /// - Parameters:
    ///     - chapter: The chapter to find alternative sources for
    ///     - rawHtmlStr: Raw HTML string of the chapter
    /// - Returns: Possible chapter links and their extraction hint
    private static func extractPossibleChapterLinks(_ chapter: WNChapter, _ rawHtmlStr: String) throws -> [(hint: String, altLink: URL)] {
        let doc = try SwiftSoup.parse(rawHtmlStr)
        let chapterNo = chapter.name.replacingOccurrences(of: nonDigitRegex, with: "", options: .regularExpression)
        var possible = [chapterNo]
        possible.append(contentsOf: possibleKeywords)
        // This is used to make sure that we are looking at unique urls
        var urlSet = Set<String>([chapter.url])
        var filtered = try doc.getElementsByTag("a")
            .filter { link in
                let linkTxt = link.ownText().lowercased()
                // Check if the link contains the chapter #
                let href = try link.attr("href")
                // Ensure that the url of the link
                // 1) uses a valid scheme
                // 2) is not a duplicate url
                guard let url = URL(string: href)
                    , validSchemes.contains(url.scheme ?? "")
                    , !urlSet.contains(href) else {
                    return false
                }
                urlSet.insert(href)
                // Check if any excluded keywords are contained
                for cand in excludedKeywords {
                    if href.contains(cand) || linkTxt.contains(cand) {
                        return false
                    }
                }
                // If the link contains the current chapter no., then it is likely the real link
                if href.contains(chapterNo) { return true }
                for cand in possible {
                    // Check if the text shown for the link contains any of the keywords
                    if linkTxt.contains(cand) {
                        return true
                    }
                }
                return false
        }.map { link in
            (link.ownText(), URL(string: try! link.attr("href"))!)
        }
        
        // Throw out some more if too many candidates
        if filtered.count > 5 {
            filtered = filtered.filter {
                $0.1.host != nil && knownHosts.contains($0.1.host!)
            }
        }
        
        return filtered
    }
}
