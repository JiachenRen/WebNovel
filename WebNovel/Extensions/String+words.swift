//
//  String+words.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/13/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

extension String {
    var words: [String] {
        return self.components(separatedBy: .whitespacesAndNewlines)
            .filter {!$0.isEmpty}
    }
}
