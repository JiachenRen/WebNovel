//
//  EditWebNovelsCollectionViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/22/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import PromiseKit

class EditWebNovelsCollectionViewController: UICollectionViewController {
    @IBOutlet weak var selectAllButton: UIBarButtonItem!
    
    @IBOutlet weak var destructiveActionButton: UIBarButtonItem!
    
    var webNovelUrls: [String]!
    var collectionType: CollectionType!
    var isSelectingAll = true
    
    private let queue = DispatchQueue(label: "com.jiachenren.WebNovel.EditWebNovels.delete", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    enum CollectionType {
        case downloads
        case favorites
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.allowsMultipleSelection = true
        switch collectionType! {
        case .downloads:
            navigationItem.title = "Edit Downloads"
            destructiveActionButton.title = "Delete"
        case .favorites:
            navigationItem.title = "Edit Favorites"
            destructiveActionButton.title = "Unfavorite"
        }
        updateDestructiveButton()
    }
    
    func updateDestructiveButton() {
        destructiveActionButton.isEnabled = collectionView.indexPathsForSelectedItems?.count != 0
    }
    
    private func delete(_ urls: [String]) -> Guarantee<Void> {
        let alert = UIAlertController(title: "Deleting...", message: nil, preferredStyle: .alert)
        present(alert, animated: true)
        return Guarantee { fulfill in
                queue.async {
                    urls.forEach { url in
                        if let cat = WNCache.fetch(by: url, object: WNCatalogue.self) {
                            cat.loadChapters(.downloaded).done { chapters in
                                chapters.forEach { ch in
                                    ch.delete()
                                }
                            }.wait()
                        }
                    }
                    fulfill(())
                }
            }.get {
                self.webNovelUrls.removeAll(where: {urls.contains($0)})
                alert.dismiss(animated: true)
                self.collectionView.reloadData()
                self.updateDestructiveButton()
        }
    }
    
    @IBAction func destructiveActionButtonTapped(_ sender: Any) {
        switch collectionType! {
        case .downloads:
            if let urls = collectionView.indexPathsForSelectedItems?
                .map({ ip in webNovelUrls[ip.row]}) {
                delete(urls).done {}
            }
        case .favorites:
            fatalError("Not implemented")
        }
    }
    
    @IBAction func selectAllButtonTapped(_ sender: Any) {
        webNovelUrls.enumerated().map {
                IndexPath(row: $0.offset, section: 0)
            }.forEach {
                if isSelectingAll {
                    collectionView.selectItem(at: $0, animated: false, scrollPosition: .top)
                } else {
                    collectionView.deselectItem(at: $0, animated: false)
                }
        }
        isSelectingAll.toggle()
        updateDestructiveButton()
        selectAllButton.title = isSelectingAll ? "Select all" : "Deselect all"
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return webNovelUrls.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "editWebNovels.webNovel", for: indexPath) as! EditWebNovelsCollectionViewCell
        guard let wn = WNCache.fetch(by: webNovelUrls[indexPath.row], object: WebNovel.self) else {
            return cell
        }
        cell.coverImageView.image = wn.loadCoverImage()?.uiImage
        cell.titleLabel.text = wn.title
        switch collectionType! {
        case .downloads:
            if let catalogue = WNCache.fetch(by: wn.url, object: WNCatalogue.self) {
                cell.infoLabel.text = "\(catalogue.numDownloads) downloaded"
            }
        case .favorites:
            cell.infoLabel.text = wn.authors?.joined(separator: ",")
        }
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateDestructiveButton()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateDestructiveButton()
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     }
     */

}
