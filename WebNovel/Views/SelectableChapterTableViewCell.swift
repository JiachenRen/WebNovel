//
//  SelectableChapterTableViewCell.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/26/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class SelectableChapterTableViewCell: UITableViewCell {
    
    @IBOutlet weak var deselectedStateButton: UIButton!
    
    @IBOutlet weak var selectedStateButton: UIButton!
    
    @IBOutlet weak var chapterLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
