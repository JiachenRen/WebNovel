//
//  FactTableViewCell.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/22/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class FactTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var valueLabel: UILabel!
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        size.height = valueLabel.sizeThatFits(size).height + 20
        return size
    }
}
