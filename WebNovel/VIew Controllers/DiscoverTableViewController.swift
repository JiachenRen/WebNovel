//
//  DiscoverTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import PromiseKit

fileprivate let entryReuseIdentifier = "discover.entry"

class DiscoverTableViewController: UITableViewController {
    
    @IBOutlet weak var loadingView: UIView!

    var novelListing = [WebNovel]() {
        didSet {
            tableView.reloadData()
        }
    }
    var cachedCoverImages = [IndexPath: UIImage]()
    let serviceProvider: WNServiceProvider = NovelUpdates()
    var currentPage = 1
    var fetchingInProgress = false {
        didSet {
            loadingView.isHidden = !fetchingInProgress
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchListing()
    }
    
    func fakeListing() -> Promise<[WebNovel]> {
        return Promise { seal in
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 2)
                let entries: [(title: String, rating: Double, description: String)] = [
                    ("Kumo desu ga, nani ka?", 4.8, "The story about a spider that crawled out of no where blah blah blah... I'm not supposed to write for this long"),
                    ("Tensei Slime Dentai Kun", 2.4, "A reincarnation who turns out to be a slime"),
                    ("Black Butler", 3.5, "Ehh... I haven't read this novel at all, so I can't comment about it"),
                    ("The Rise of the Shield Hero", 2.5, "The shield here, the spear hero, the bow hero, ")
                ]
                seal.fulfill(entries.map {(title, rating, desc) in
                    let wn = WebNovel()
                    wn.title = title
                    wn.rating = rating
                    wn.shortDescription = desc
                    return wn
                })
            }
        }
    }
    
    func fetchListing() {
        if fetchingInProgress {
            return
        }
        fetchingInProgress = true
        print(currentPage)
        serviceProvider.fetchListing(for: .popularMonthlyRanking, page: currentPage)
//            fakeListing()
            .done { webNovels in
                self.novelListing.append(contentsOf: webNovels)
                self.currentPage += 1
            }.ensure {
                self.fetchingInProgress = false
            }.catch { err in
                print(err)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return novelListing.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: entryReuseIdentifier, for: indexPath)
        guard let discoverCell = cell as? DiscoverTableViewCell else {
            return cell
        }
        let wn = novelListing[indexPath.row]
        
        // Load cover image
        if let coverImage = cachedCoverImages[indexPath] {
            discoverCell.coverImageView.alpha = 1
            discoverCell.coverImageView.image = coverImage
        } else {
            discoverCell.activityIndicatorView.startAnimating()
            discoverCell.coverImageView.alpha = 0.5
            serviceProvider.loadDetails(wn, cachePolicy: .usesCache)
                .map { wn -> String in
                    guard let coverImgUrl = wn.coverImageUrl else {
                        throw WNError.urlNotFound
                    }
                    return coverImgUrl
                }.then { url in
                    downloadImage(from: url)
                }.done { image in
                    discoverCell.coverImageView.image = image
                    self.cachedCoverImages[indexPath] = image
                }.ensure {
                    discoverCell.coverImageView.alpha = 1
                    discoverCell.activityIndicatorView.stopAnimating()
                }.catch { err in
                    discoverCell.coverImageView.image = UIImage(named: "cover-placeholder")
                    print(err)
            }
        }
        
        discoverCell.titleLabel.text = wn.title
        let rating = wn.rating ?? 0.0
        let filledStars = (0..<Int(round(rating)))
            .map {_ in "⭑"}
            .reduce("") {$0 + $1}
        let emptyStars = (0..<(5 - Int(round(rating))))
            .map {_ in "⭐︎"}
            .reduce("") {$0 + $1}
        discoverCell.starsLabel.text = filledStars + emptyStars
        discoverCell.ratingLabel.text = " \(rating) / 5.0"
        discoverCell.descriptionLabel.text = wn.shortDescription ?? wn.fullDescription

        return discoverCell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 185
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if distanceFromBottom < height {
            fetchListing()
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
