//
//  WNParser.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/15/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftSoup
import JavaScriptCore

class WNParser {
    
    /// Readability parser
    private static var reader: Readability = Readability()
    
    /// A dictionary of hosts and their corresponding extractors
    private static var extractors: [String: Extractor] = [
        "rtd.moe": .init([
            \.title: [
                .id("content"),
                .tag("h2", idx: 0),
                .parse {try? decode($0.text())}
            ],
            \.textContent: [
                .id("content"),
                .parse {
                    try? $0.getElementsByTag("p")
                        .reduce("") {
                            try $0 + "\n" + decode($1.text())
                    }
                }
            ]
            ]),
        "blastron01.tumblr.com": .init([
            \.title: [
                .id("blog"),
                .tag("div", idx: 0),
                .tag("h1", idx: 1),
                .parse {try? decode($0.text())}
            ],
            \.textContent: [
                .id("blog"),
                .tag("div", idx: 0),
                .parse {
                    try? $0.getElementsByTag("p")
                        .reduce("") {
                            try $0 + "\n" + decode($1.text())
                    }
                }
            ]
            ]),
        "turb0translation.blogspot.com": .init([
            \.title: [
                .class("post-body entry-content", idx: 0),
                .tag("b", idx: 0),
                .tag("span", idx: 0),
                .parse {try? decode($0.text())}
            ],
            \.textContent: [
                .class("post-body entry-content", idx: 0),
                .parse {
                    try? decode($0.html().replacingOccurrences(of: "<br>", with: "\n"))
                }
            ]
            ])
    ]
    
    /// Decodes html string.
    /// e.g. &#8216;Du bist ein shwein&#8217; becomes 'Du bist ein shwein'
    static func decode(_ html: String) throws -> String {
        guard let data = html.data(using: .utf8) else {
            throw WNError.decodingFailed
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            throw WNError.decodingFailed
        }
        
        return attributedString.string
    }
    
    /// Parses WN chapter from given raw html
    /// - Parameter html: Raw html string for the WN chapter
    /// - Parameter url: The  host url is used for figuring out the extraction method for the chapter.
    /// - Parameter chapter: Parsed info is merged into existing chapter object
    static func parseChapter(_ html: String, _ url: URL, mergeInto chapter: WNChapter) {
        
        // Save chapter raw html string
        chapter.rawHtml = html
        
        // Extract chapter information from raw html using custom, host-specific parser
        if let host = url.host, let extractor = extractors[host]  {
            if let doc = try? SwiftSoup.parse(html) {
                try? extractor.extract(from: doc, into: chapter)
            }
        }
        
        // Since there are countless websites for WN out there, it is not possible
        // to have a host specific parser for every one of them.
        // Therefore, Readability is used as a generic parser. (It is used by Fire Fox for its reader's view)
        chapter.article = reader.parse(html)
    }
    
    /// The Extractor contains the instructions and logic for extracting WN information from raw html string.
    class Extractor {
        
        typealias Instructions = [ReferenceWritableKeyPath<WNChapter, String?>: [ExtractionStep]]
        
        enum ExtractionStep {
            case id(_ id: String)
            case `class`(_ class: String, idx: Int)
            case tag(_ tag: String, idx: Int)
            case selector(_ query: String, idx: Int)
            case parse(_ parser: (Element) -> String?)
        }
        
        /// - Note: The last extraction step for every property must be `.parse`
        var instructions: Instructions
        
        init(_ extractionInstructions: Instructions) {
            self.instructions = extractionInstructions
        }
        
        /// Apply a step of instruction to the current node
        func apply(_ step: ExtractionStep, to element: Element) throws -> Element? {
            switch step {
            case .id(let id):
                return try element.getElementById(id)
            case .class(let c, idx: let i):
                let elements = try element.getElementsByClass(c)
                if i < elements.count {
                    return elements[i]
                }
                return nil
            case .tag(let tag, idx: let i):
                let elements = try element.getElementsByTag(tag)
                if i < elements.count {
                    return elements[i]
                }
                return nil
            case .selector(let query, idx: let i):
                return try element.select(query).get(i)
            case .parse:
                throw WNError.invalidParsingInstruction
            }
        }
        
        /// Extracts WNChapter properties from html String by following instructions
        func extract(from doc: Document, into chapter: WNChapter) throws {
            try instructions.forEach { keyPath, steps in
                var element: Element = doc
                var steps = steps
                let parser = steps.removeLast()
                for step in steps {
                    guard let e = try apply(step, to: element) else {
                        // Failed to fetch property, move on.
                        return
                    }
                    element = e
                }
                switch parser {
                case .parse(let p):
                    guard let parsed = p(element) else {
                        throw WNError.parsingError("Failed to parse element \(element)")
                    }
                    chapter[keyPath: keyPath] = parsed
                default:
                    throw WNError.parsingError("Parsing must be the last step of the instruction set")
                }
            }
        }
    }
}
