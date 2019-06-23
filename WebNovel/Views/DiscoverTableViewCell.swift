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
    
    var loadImageTask: WNCancellableTask?
    var loadingCoverImage = false
    var loadingDetails = false
    var wn: WebNovel?

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
        self.wn = wn
        setTitle(wn.title)
        setRating(wn.rating)
        setDescription(wn.shortDescription ?? wn.fullDescription)
    }
    
    /// Load details (other information for the WN
    func loadDetails() {
        guard let wn = self.wn, !loadingDetails else {
            return
        }
        loadingDetails = true
        self.serviceProvider.loadDetails(wn, cachePolicy: .usesCache)
            .done(on: .main) {
                self.setWNMetadata($0)
            }.ensure {
                self.loadingDetails = false
            }.catch { err in
                print(err)
        }
    }
    
    /// Load the cover image for the WN.
    func loadCoverImage(_ completionHandler: ((UIImage) -> Void)?) {
        guard let wn = self.wn, !loadingCoverImage else {
            return
        }
        /// Invalidates existing cover image
        activityIndicatorView.startAnimating()
        coverImageView.alpha = 0.1
        loadingCoverImage = true
        
        loadImageTask = WNCancellableTask { [unowned self] task in
            self.serviceProvider.loadDetails(wn, cachePolicy: .usesCache)
                .map { wn -> String in
                    guard let coverImgUrl = wn.coverImageUrl else {
                        throw WNError.urlNotFound
                    }
                    return coverImgUrl
                }.then { url in
                    downloadImage(from: url)
                }.done { image in
                    if !task.isCancelled {
                        self.setCoverImage(image)
                    }
                    completionHandler?(image)
                }.ensure {
                    self.loadingCoverImage = false
                }.catch { err in
                    self.setCoverImage(.coverPlaceholder)
                    print(err)
            }
        }
        loadImageTask?.run()
    }
    
    override func prepareForReuse() {
        loadImageTask?.isCancelled = true
        loadingCoverImage = false
    }
}
