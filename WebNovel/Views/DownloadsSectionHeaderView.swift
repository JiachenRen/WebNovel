//
//  DownloadsSectionHeaderView.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/28/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class DownloadsSectionHeaderView: UICollectionReusableView {
        
    @IBOutlet weak var sortByButton: UIButton!
    @IBOutlet weak var numNovelsLabel: UILabel!
    weak var delegate: DownloadsSectionHeaderViewDelegate?
    
    @IBAction func sortByButtonTapped(_ sender: Any) {
        delegate?.sortByButtonTapped()
    }
}

protocol DownloadsSectionHeaderViewDelegate: AnyObject {
    func sortByButtonTapped()
}
