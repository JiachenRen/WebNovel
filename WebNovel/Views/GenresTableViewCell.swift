//
//  GenresTableViewCell.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/21/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class GenresTableViewCell: UITableViewCell {

    @IBOutlet weak var genresView: UIView!
    
    @IBOutlet weak var heightLayoutConstraint: NSLayoutConstraint!
    
    var height: CGFloat!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Record initial height
        height = genresView.frame.height
    }
    
    func setGenres(_ genres: [String]) {
        // Clear existing genre labels & reset layout constraints
        heightLayoutConstraint.constant = height
        genresView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        var frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        for genre in genres {
            let label = GenreLabel(frame: frame, insets: .init(top: 0, left: 8, bottom: 0, right: 8))
            label.textColor = .darkGray
            label.backgroundColor = UIColor.darkGray.withAlphaComponent(0.1)
            label.layer.masksToBounds = true
            label.layer.cornerRadius = 4
            label.text = "\(genre)"
            label.font = .systemFont(ofSize: 13, weight: .regular)
            label.textAlignment = .center
            label.sizeToFit()
            label.frame.size.height = height
            if label.frame.maxX > genresView.frame.maxX {
                // Enlarge the genres view to contain 1 more row
                heightLayoutConstraint.constant += height + 10
                
                frame.origin.x = 0
                frame.origin.y += height + 10
                label.frame.origin = frame.origin
            }
            frame.origin.x += label.frame.width + 10
            genresView.addSubview(label)
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return genresView.frame.size
    }

}
