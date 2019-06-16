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
    var data: NSObject? {get set}
    var url: String? {get set}
}

extension Chapter: WNManagedObject {
    
}

extension WebNovel: WNManagedObject {
    
}

extension ChaptersListing: WNManagedObject {
    
}
