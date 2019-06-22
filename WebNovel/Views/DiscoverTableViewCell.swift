//
//  DiscoverTableViewCell.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class DiscoverTableViewCell: UITableViewCell {

    @IBOutlet weak var coverImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var ratingLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var starsLabel: UILabel!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var loadingCoverImage = false

    func setCoverImage(_ image: UIImage) {
        coverImageView.image = image
        coverImageView.alpha = 1
        activityIndicatorView.stopAnimating()
    }
    
    func setRating(_ rating: Double?) {
        let rating = rating ?? 0.0
        let filledStars = (0..<Int(round(rating)))
            .map {_ in "⭑"}
            .reduce("") {$0 + $1}
        let emptyStars = (0..<(5 - Int(round(rating))))
            .map {_ in "⭐︎"}
            .reduce("") {$0 + $1}
        starsLabel.text = filledStars + emptyStars
        ratingLabel.text = " \(rating) / 5.0"
    }
    
    func setTitle(_ title: String?) {
        titleLabel.text = title
    }
    
    func setDescription(_ desc: String?) {
        descriptionLabel.text = desc
    }
    
    func setWNMetadata(_ wn: WebNovel) {
        setTitle(wn.title)
        setRating(wn.rating)
        setDescription(wn.shortDescription ?? wn.fullDescription)
    }
}
