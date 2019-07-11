//
//  DownloadsCollectionViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/27/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

private let reuseIdentifier = "downloads.webNovel"

class DownloadsCollectionViewController: UICollectionViewController {
    var catalogues: [WNChaptersCatalogue] = []
    var coverImages: [String: UIImage] = [:]
    var webNovels: [String: WebNovel] = [:]
    var loaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.allowsMultipleSelection = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadAvailableWebNovels()
    }
    
    /// Load web novels with available downloads or ones that are being downloaded
    private func loadAvailableWebNovels() {
        guard var catalogues = try? WNCache.fetchAll(WNChaptersCatalogue.self) else {
            self.alert(title: "Error", msg: "Failed to load chapter catalogues")
            return
        }
        // Only present catalogues with downloaded chapters, also include ones that are currently being downloaded
        catalogues = catalogues.filter {
            $0.hasDownloads || WNDownloadsManager.shared.currentTasks.keys.contains($0.url)
        }
        self.catalogues = catalogues
        let urls: [String] = catalogues.map {$0.url}
        urls.forEach { [unowned self] url in
            if let wn = try? WNCache.fetch(by: url, object: WebNovel.self) {
                self.webNovels[url] = wn
                if let imageUrl = wn.coverImageUrl,
                    let coverImage = try? WNCache.fetch(by: imageUrl, object: WNCoverImage.self) {
                    self.coverImages[url] = UIImage(data: coverImage.imageData)
                }
            }
        }
        
        loaded = true
        collectionView.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return catalogues.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        let catalogue = catalogues[indexPath.row]
        guard let downloadsCell = cell as? DownloadsCollectionViewCell else {
            return cell
        }
        
        let url = catalogue.url
        downloadsCell.coverImageView.image = coverImages[url]
        downloadsCell.titleLabel.text = webNovels[url]?.title
        downloadsCell.numDownloadedLabel.text = "\(catalogue.downloadedChapters.count) downloaded"
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView: UICollectionReusableView! = nil
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "downloads.sectionHeader", for: indexPath) as! DownloadsSectionHeaderView
            header.numNovelsLabel.text = "\(catalogues.count) novel(s)"
            reusableView = header
        case UICollectionView.elementKindSectionFooter:
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "downloads.sectionFooter", for: indexPath) as! DownloadsSectionFooterView
            footer.isHidden = loaded
            reusableView = footer
        default:
            break
        }
        return reusableView
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? DownloadedNovelTableViewController, let idx = collectionView.indexPathsForSelectedItems?.first?.row {
            let cat = catalogues[idx]
            controller.catalogue = cat
            controller.coverImage = coverImages[cat.url]
            controller.webNovel = webNovels[cat.url]
        }
    }

}
