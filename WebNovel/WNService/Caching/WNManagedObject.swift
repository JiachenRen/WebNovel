//
//  WNManagedObject.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import CoreData

protocol WNManagedObject: NSManagedObject {
    static var entityName: String {get}
    var data: NSObject? {get set}
    var url: String? {get set}
}

extension WNManagedObject {
    static var entityName: String {
        return String(describing: Self.self)
    }
}

extension Chapter: WNManagedObject {
    
}

extension Novel: WNManagedObject {
    
}

extension ChaptersCatalogue: WNManagedObject {
    
}

extension CoverImage: WNManagedObject {
    
}
