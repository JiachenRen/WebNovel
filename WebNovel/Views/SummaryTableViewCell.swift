//
//  SummaryTableViewCell.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/21/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class SummaryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var summaryTextView: UITextView!
    
    @IBOutlet weak var collapseLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var moreInfoButton: UIButton!
    
    weak var delegate: InformationTableViewCellDelegate?
    var isShowingMore = false {
        didSet {
            collapseLayoutConstraint.priority = isShowingMore ? .defaultLow : .defaultHigh
            moreInfoButton.setTitle(isShowingMore ? "Show Less ↑" : "Show More ↓", for: .normal) 
            delegate?.cellLayoutDidChange()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Make the text view more stylish
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.foregroundColor: UIColor.darkGray,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ]
        summaryTextView.attributedText = NSAttributedString(string: summaryTextView.text, attributes: attributes)
    }
    
    @IBAction func moreInfoButtonTapped(_ sender: Any) {
        isShowingMore.toggle()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return systemLayoutSizeFitting(size)
    }
}
