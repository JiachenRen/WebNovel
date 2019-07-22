//
//  EditWebNovelsCollectionViewCell.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/22/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class EditWebNovelsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var coverImageView: UIImageView!
    
    @IBOutlet weak var selectedButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    override var isSelected: Bool {
        didSet {
           print("selected \(isSelected)")
            selectedButton.tintColor = isSelected ? .globalTint : .white
            selectedButton.setImage(isSelected ? .okFilled : .emptyCircle, for: .normal)
        }
    }
}
