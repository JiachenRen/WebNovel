//
//  Article.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/25/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

/// Article wraps relevant information extracted by `Readability.js`
struct Article: Codable, CustomStringConvertible {
    
    /// Title of the article
    var title: String?
    
    /// Text content of the article
    var textContent: String?
    
    /// Sanitized html content of the article
    var htmlContent: String?
    
    var description: String {
        return """
        Title: \(title.losslessStr)
        Text Content: \(textContent.losslessStr)
        Html Content: \(htmlContent.losslessStr)
        """
    }
}

