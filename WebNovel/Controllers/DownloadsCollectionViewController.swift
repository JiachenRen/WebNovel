//
//  DownloadsCollectionViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/27/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import PromiseKit

class DownloadsCollectionViewController: UICollectionViewController {
    var sortingCriterion: CatalogueSortingCriterion = .name
    var catalogues: [WNChaptersCatalogue] = []
    var coverImages: [String: UIImage] = [:]
    var webNovels: [String: WebNovel] = [:]
    var headerView: DownloadsSectionHeaderView?
    var reloadTimer: Timer?
    var loading = true
    
    private let queue = DispatchQueue(label: "com.jiachenren.WebNovel.downloads.load", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    enum CatalogueSortingCriterion: String, CaseIterable {
        case name = "Name"
        case lastModified = "Last Modified"
        case lastRead = "Last Read"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsMultipleSelection = false
        reload()
        observe(.downloadTaskStatusUpdated, #selector(downloadTaskUpdated))
        observe(.downloadTaskInitiated, #selector(downloadTaskUpdated))
    }
    
    @objc private func downloadTaskUpdated() {
        reloadTimer?.invalidate()
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {
            [weak self] _ in
            self?.reload()
        }
    }
    
    /// Reload available downloads
    private func reload() {
        loadAvailableWebNovels().done(on: .main) {
            self.sortCatalogue()
            self.collectionView.reloadData()
        }.catch(presentError)
    }
    
    /// Sort the WN catalogues according to specified sorting criterion
    private func sortCatalogue() {
        catalogues.sort { a, b in
            switch sortingCriterion {
            case .lastModified:
                return a.lastModified > b.lastModified
            case .lastRead:
                return a.lastReadChapter?.lastRead ?? 0 > b.lastReadChapter?.lastRead ?? 0
            case .name:
                return webNovels[a.url]?.title ?? "" < webNovels[b.url]?.title ?? ""
            }
        }
    }
    
    /// Load web novels with available downloads or ones that are being downloaded
    private func loadAvailableWebNovels() -> Promise<Void> {
        loading = true
        return Promise { seal in
                queue.async { [weak self] in
                    guard let self = self else {
                        seal.reject(WNError.instanceDeallocated)
                        return
                    }
                    var catalogues = WNCache.fetchAll(WNChaptersCatalogue.self)
                    // Only present catalogues with downloaded chapters, also include ones that are currently being downloaded
                    catalogues = catalogues.filter {
                        $0.hasDownloads || WNDownloadsManager.shared.currentTasks.keys.contains($0.url)
                    }
                    self.catalogues = catalogues
                    let urls: [String] = catalogues.map {$0.url}
                    urls.forEach { url in
                        if let wn = WNCache.fetch(by: url, object: WebNovel.self) {
                            self.webNovels[url] = wn
                            if let imageUrl = wn.coverImageUrl,
                                let coverImage = WNCache.fetch(by: imageUrl, object: WNCoverImage.self) {
                                self.coverImages[url] = UIImage(data: coverImage.imageData)
                            }
                        }
                    }
                    seal.fulfill(())
                }
            }.ensure { [weak self] in
                self?.loading = false
        }
    }
    
}

// MARK: - Collection view data source

extension DownloadsCollectionViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return catalogues.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "downloads.webNovel", for: indexPath)
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
            header.delegate = self
            self.headerView = header
            updateSortByButton()
            reusableView = header
        case UICollectionView.elementKindSectionFooter:
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "downloads.sectionFooter", for: indexPath) as! DownloadsSectionFooterView
            footer.isHidden = !loading
            reusableView = footer
        default:
            break
        }
        return reusableView
    }
    
}

// MARK: - Navigation

extension DownloadsCollectionViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? DownloadedNovelTableViewController, let idx = collectionView.indexPathsForSelectedItems?.first?.row {
            let cat = catalogues[idx]
            controller.catalogue = cat
            controller.coverImage = coverImages[cat.url]
            controller.webNovel = webNovels[cat.url]
        }
    }
    
}

extension DownloadsCollectionViewController: DownloadsSectionHeaderViewDelegate {
    
    func sortByButtonTapped() {
        let alert = UIAlertController(title: "Sort by", message: nil, preferredStyle: .actionSheet)
        CatalogueSortingCriterion.allCases.forEach { criterion in
            alert.addAction(UIAlertAction(title: criterion.rawValue, style: .default) {
                [weak self] _ in
                self?.sortingCriterion = criterion
                self?.sortCatalogue()
                self?.updateSortByButton()
                self?.collectionView.reloadData()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    private func updateSortByButton() {
        headerView?.sortByButton.setTitle("Sort By: \(sortingCriterion.rawValue)", for: .normal)
    }
    
}
