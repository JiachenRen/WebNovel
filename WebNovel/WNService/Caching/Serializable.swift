//
//  Serializable.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

/// JSON serializable
protocol Serializable: Codable {
    var url: String? {get}
    static var entityName: String {get}
}