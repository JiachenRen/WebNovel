//
//  Serializable.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import CoreData

/// JSON serializable
protocol Serializable: Codable {
    associatedtype ManagedObject: WNManagedObject
    var url: String? {get}
}
