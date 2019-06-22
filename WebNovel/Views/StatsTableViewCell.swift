//
//  StatsTableViewCell.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/22/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class StatsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var rankLabel: UILabel!

    @IBOutlet weak var readersLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        rankLabel.clipsToBounds = true
        rankLabel.layer.cornerRadius = 4
        readersLabel.clipsToBounds = true
        readersLabel.layer.cornerRadius = 4
    }
    
    func setRank(_ rank: Int?) {
        rankLabel.text = rank == nil ? "  N/A  " : "  #\(rank!)  "
    }
    
    func setReaders(_ readers: Int?) {
        readersLabel.text = readers == nil ? "  N/A  " : "  \(readers!)  "
    }
}
