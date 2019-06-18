//
//  WNCoverImage.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/18/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import UIKit

class WNCoverImage: Serializable {
    var url: String?
    var imageData: Data
    
    static var entityName: String = "CoverImage"
    
    init?(uiImage: UIImage , _ url: String) {
        guard let data = uiImage.pngData() else {
            return nil
        }
        self.imageData = data
        self.url = url
    }
    
}
