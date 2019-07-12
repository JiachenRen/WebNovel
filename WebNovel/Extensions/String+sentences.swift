//
//  String+sentences.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/12/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

extension String {
    
    /// Split the string into centences, separated by sentence terminators
    var sentences: [String] {
        var r = [Range<String.Index>]()
        let s = self
        let t = s.linguisticTags(
            in: s.startIndex..<s.endIndex,
            scheme: NSLinguisticTagScheme.lexicalClass.rawValue,
            tokenRanges: &r)
        var result = [String]()
        let ixs = t.enumerated().filter {
            $0.1 == "SentenceTerminator"
            }.map {r[$0.0].lowerBound}
        var prev = s.startIndex
        for ix in ixs {
            let r = prev...ix
            result.append(
                s[r].trimmingCharacters(
                    in: NSCharacterSet.whitespaces))
            prev = s.index(after: ix)
        }
        return result
    }
}
