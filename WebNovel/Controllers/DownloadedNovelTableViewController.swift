//
//  DownloadedNovelTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/29/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import PromiseKit

class DownloadedNovelTableViewController: UITableViewController {

    @IBOutlet weak var coverImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var numDownloadedLabel: UILabel!
    
    @IBOutlet weak var storageUsedLabel: UILabel!
    
    @IBOutlet weak var readResumeButton: UIButton!
    
    weak var headerCell: DownloadedNovelSectionHeaderCell?
    
    private let queue = DispatchQueue(
        label: "com.jiachenren.webNovel.downloadedNovel.loadChapters",
        qos: .utility,
        attributes: .concurrent,
        autoreleaseFrequency: .workItem,
        target: nil
    )
    
    var catalogue: WNChaptersCatalogue!
    var downloadedChapters: [WNChapter] = []
    var webNovel: WebNovel!
    var coverImage: UIImage?
    var reloadTimer: Timer?
    var loading = true
    
    var downloadTask: WNDownloadsManager.Task? {
        return WNDownloadsManager.shared.currentTasks[catalogue.url]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateHeaderView()
        
        // Notification binding
        observe(.downloadTaskInitiated, #selector(downloadTaskStatusChanged(_:)))
        observe(.downloadTaskCompleted, #selector(downloadTaskStatusChanged(_:)))
        observe(.downloadTaskStatusUpdated, #selector(downloadTaskStatusChanged(_:)))
        observe(.chapterReadStatusUpdated, #selector(chapterReadStatusUpdated))
        observe(.groupsFilterUpdated, #selector(groupsFilterUpdated))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        reloadDownloadedChapters().done {
            [weak self] in
            self?.updateHeaderView()
            self?.updateReadResumeButton()
            self?.tableView.reloadData()
        }
    }
    
    @objc private func groupsFilterUpdated() {
        reloadDownloadedChapters().done(on: .main) {
            [weak self] in
            self?.tableView.reloadData()
            self?.updateHeaderView()
        }
    }
    
    @objc private func chapterReadStatusUpdated() {
        reloadDownloadedChapters().done(on: .main) {
            [weak self] in
            self?.tableView.reloadData()
            self?.updateReadResumeButton()
        }
    }
    
    /// Download task has started, ended, or updated its status
    @objc private func downloadTaskStatusChanged(_ notif: Notification) {
        guard let task = notif.object as? WNDownloadsManager.Task,
            task.url == catalogue.url else {
            return
        }
        
        reloadTimer?.invalidate()
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            DispatchQueue.main.async { [weak self] in
                self?.reloadDownloadedChapters().done(on: .main) {
                    self?.updateHeaderView()
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    private func reloadDownloadedChapters() -> Guarantee<Void> {
        loading = true
        return Guarantee { fulfill in
            queue.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.catalogue = WNCache.fetch(by: self.catalogue.url, object: WNChaptersCatalogue.self)
                self.downloadedChapters = self.catalogue
                    .chaptersForEnabledGroups()
                    .sorted {
                        $0.id < $1.id
                    }.filter {$0.isDownloaded}
                self.loading = false
                fulfill(())
            }
        }
    }
    
    private func updateReadResumeButton() {
        let title = catalogue.lastReadChapter == nil ? "READ" : "RESUME"
        readResumeButton.setTitle(title, for: .normal)
    }
    
    private func updateHeaderView() {
        coverImageView.image = coverImage
        numDownloadedLabel.text = "\(downloadedChapters.count) chapters downloaded"
        storageUsedLabel.text = "\(catalogue.storageSpaceUsed()) used"
        titleLabel.text = webNovel.title
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return downloadTask == nil ? 0 : 1
        case 1:
            return 1
        case 2:
            return downloadedChapters.count
        default:
            fatalError()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "downloads.progress", for: indexPath)
                as! DownloadedNovelProgressTableViewCell
            cell.url = downloadTask!.url
            cell.update(downloadTask!)
            return cell
        case 1:
            let headerCell = tableView.dequeueReusableCell(withIdentifier: "downloads.sectionHeader") as! DownloadedNovelSectionHeaderCell
            headerCell.numChaptersLabel.text = "\(downloadedChapters.count) chapters"
            headerCell.filterButton.isEnabled = !loading
            headerCell.delegate = self
            self.headerCell = headerCell
            return headerCell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "downloads.chapter", for: indexPath)
            let chapter = downloadedChapters[indexPath.row]
            cell.textLabel?.text = chapter.properTitle() ?? chapter.article?.title
            cell.textLabel?.textColor = chapter.isRead ? .lightGray : .black
            return cell
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 92
        case 1:
            return 50
        case 2:
            return 44
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 2
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let chapter = downloadedChapters.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            chapter.delete().then {
                self.reloadDownloadedChapters()
            }.done { [weak self] in
                self?.tableView.reloadData()
                self?.updateHeaderView()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let ch = downloadedChapters[indexPath.row]
        let title = "Mark as \(ch.isRead ? "Unread" : "Read")"
        let mark = UITableViewRowAction(style: .default, title: title) {
            [weak self] (_, indexPath) in
            ch.toggleReadStatus().done {
                self?.chapterReadStatusUpdated()
            }
        }
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") {
            [weak self] (_, indexPath) in
            guard let self = self else {
                return
            }
            self.tableView.dataSource?.tableView?(self.tableView, commit: .delete, forRowAt: indexPath)
        }
        mark.backgroundColor = .globalTint
        return [delete, mark]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let infoController = segue.destination as? InformationTableViewController {
            infoController.webNovel = webNovel
        } else if let nav = segue.destination as? UINavigationController,
            let chapterController = nav.topViewController as? ChapterViewController {
            if let idx = tableView.indexPathForSelectedRow?.row {
                chapterController.chapter = downloadedChapters[idx]
            } else {
                chapterController.chapter = catalogue.lastReadChapter ?? catalogue.firstChapter
            }
        }
    }
}

extension DownloadedNovelTableViewController: DownloadedNovelSectionHeaderCellDelegate {
    func filterButtonTapped() {
        let storyBoard = UIStoryboard(name: "GroupsFilter", bundle: .main)
        let nav = storyBoard.instantiateViewController(withIdentifier: "groupsFilter.nav") as! UINavigationController
        nav.modalPresentationStyle = .popover
        nav.popoverPresentationController?.delegate = self
        nav.popoverPresentationController?.sourceView = headerCell?.filterButton
        nav.popoverPresentationController?.sourceRect = headerCell?.filterButton.bounds ?? .zero
        nav.popoverPresentationController?.permittedArrowDirections = [.up]
        if let groupsFilterController = nav.topViewController as? GroupsFilterTableViewController {
            groupsFilterController.catalogue = catalogue
            present(nav, animated: true)
        }
    }
}

extension DownloadedNovelTableViewController: UIPopoverPresentationControllerDelegate {
    
    /// Ensure that the presentation controller is NOT fullscreen
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}
