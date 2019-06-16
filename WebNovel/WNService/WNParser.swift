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

class WNParser {
    
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
    static func parseChapter(_ html: String, _ url: URL, mergeInto chapter: WNChapter) -> Promise<WNChapter> {
        return Promise { seal in
            guard let host = url.host else {
                seal.reject(WNError.hostNotFound)
                return
            }
            guard let extractor = extractors[host] else {
                seal.reject(WNError.unsupportedHost(host))
                return
            }
            let doc = try SwiftSoup.parse(html)
            try extractor.extract(from: doc, into: chapter)
            seal.fulfill(chapter)
        }
    }
    
    /// A dictionary of hosts and their corresponding extractors
    static var extractors: [String: Extractor] = [
        "rtd.moe": .init([
            \.title: [
                .id("content"),
                .tag("h2", idx: 0),
                .parse {try? decode($0.text())}
            ],
            \.content: [
                .id("content"),
                .parse {
                    try? $0.getElementsByTag("p")
                        .reduce("") {
                            try $0 + "\n" + decode($1.text())
                    }
                }
            ]
        ])
    ]
    
    /// The Extractor contains the instructions and logic for extracting WN information from raw html string.
    class Extractor {
        
        typealias Instructions = [WritableKeyPath<WNChapter, String?>: [ExtractionStep]]
        
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
                return try element.getElementsByClass(c).get(i)
            case .tag(let tag, idx: let i):
                return try element.getElementsByTag(tag).get(i)
            case .selector(let query, idx: let i):
                return try element.select(query).get(i)
            case .parse:
                throw WNError.invalidParsingInstruction
            }
        }
        
        /// Extracts WNChapter properties from html String by following instructions
        func extract(from doc: Document, into chapter: WNChapter) throws {
            var chapter = chapter
            try instructions.forEach { keyPath, steps in
                var element: Element = doc
                var steps = steps
                let parser = steps.removeLast()
                for step in steps {
                    guard let e = try apply(step, to: element) else {
                        throw WNError.invalidParsingInstruction
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
