//
//  UIProgressView+barHeight.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/10/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import UIKit

extension UIProgressView {
    
    @IBInspectable var barHeight : CGFloat {
        get {
            return transform.d * 2.0
        }
        set {
            // 2.0 Refers to the default height of 2
            let heightScale = newValue / 2.0
            let c = center
            transform = CGAffineTransform(scaleX: 1.0, y: heightScale)
            center = c
        }
    }
}
