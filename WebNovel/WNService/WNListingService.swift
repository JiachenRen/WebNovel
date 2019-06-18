//
//  WNListingService.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit

enum WNListingService: String {
    typealias Option = String
    
    case latest = "Latest"
    case all = "All"
    case ranking = "Ranking"
    case genre = "Genre"
}
