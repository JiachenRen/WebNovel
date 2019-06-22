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

    @IBOutlet weak var votesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        rankLabel.clipsToBounds = true
        rankLabel.layer.cornerRadius = 4
        votesLabel.clipsToBounds = true
        votesLabel.layer.cornerRadius = 4
    }
    
    func setRank(_ rank: Int?) {
        rankLabel.text = rank == nil ? "  N/A  " : "  #\(rank!)  "
    }
    
    func setVotes(_ votes: Int?) {
        votesLabel.text = votes == nil ? "  N/A  " : "  \(votes!)  "
    }
}
