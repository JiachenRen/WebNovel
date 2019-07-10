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
    var url: String {get}
}
fileprivate let encoder = JSONEncoder()

extension Serializable {
    
    /// Returns the size of the serialized obj in the form of byte count
    func serializedByteCount() -> Int {
        let data = try! encoder.encode(self)
        return data.count
    }
}
