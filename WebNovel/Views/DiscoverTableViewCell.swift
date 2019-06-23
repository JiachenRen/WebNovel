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
    
    var serviceProvider: WNServiceProvider {
        return WNServiceManager.shared.serviceProvider
    }
    
    var wn: WebNovel?
    
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
        self.wn = wn
        setTitle(wn.title)
        setRating(wn.rating)
        setDescription(wn.shortDescription ?? wn.fullDescription)
    }
    
    func setCoverImage(_ image: UIImage?) {
        guard let image = image else {
            activityIndicatorView.startAnimating()
            coverImageView?.alpha = 0.1
            return
        }
        activityIndicatorView.stopAnimating()
        coverImageView.alpha = 1
        coverImageView.image = image
    }
}
