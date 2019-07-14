//
//  DownloadedNovelSectionHeaderCell.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/2/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class DownloadedNovelSectionHeaderCell: UITableViewCell {
    
    @IBOutlet weak var numChaptersLabel: UILabel!
    
    @IBOutlet weak var filterButton: UIButton!
    
    weak var delegate: DownloadedNovelSectionHeaderCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Remove separator
        separatorInset = .init(top: 0, left: 10000, bottom: 0, right: 0)
    }

    @IBAction func filterButtonTapped(_ sender: Any) {
        delegate?.filterButtonTapped()
    }
    
}

protocol DownloadedNovelSectionHeaderCellDelegate: AnyObject {
    func filterButtonTapped()
}
