//
//  GenreLabel.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/21/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class GenreLabel: UILabel {

    var insets: UIEdgeInsets
    
    init(frame: CGRect, insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.insets = .init(top: 0, left: 8, bottom: 0, right: 8)
        super.init(coder: aDecoder)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.width += insets.left + insets.right
        size.height += insets.top + insets.bottom
        return size
    }
}
