//
//  WNTranslationGroup.swift
//  WebNovel
//
//  Created by Jiachen Ren on 2/18/20.
//  Copyright © 2020 Jiachen Ren. All rights reserved.
//

import Foundation

struct WNTranslationGroup: Hashable, Decodable {
    /// Name of the translation group
    var name: String
    
    /// Url of the translation group
    var url: String
}
