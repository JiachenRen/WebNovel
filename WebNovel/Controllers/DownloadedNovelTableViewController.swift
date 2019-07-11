//
//  DownloadedNovelTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/29/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class DownloadedNovelTableViewController: UITableViewController {

    @IBOutlet weak var coverImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var numDownloadedLabel: UILabel!
    
    @IBOutlet weak var storageUsedLabel: UILabel!
    
    @IBOutlet weak var readResumeButton: UIButton!
    
    var catalogue: WNChaptersCatalogue!
    var downloadedChapters: [WNChapter] = []
    var webNovel: WebNovel!
    var coverImage: UIImage?
    var reloadTimer: Timer?
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        reloadDownloadedChapters()
        updateHeaderView()
        updateReadResumeButton()
        tableView.reloadData()
    }
    
    @objc private func chapterReadStatusUpdated() {
        reloadDownloadedChapters()
        tableView.reloadData()
        updateReadResumeButton()
    }
    
    /// Download task has started, ended, or updated its status
    @objc private func downloadTaskStatusChanged(_ notif: Notification) {
        guard let task = notif.object as? WNDownloadsManager.Task,
            task.url == catalogue.url else {
            return
        }
        
        reloadTimer?.invalidate()
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                self.reloadDownloadedChapters()
                self.updateHeaderView()
                self.tableView.reloadData()
            }
        }
    }
    
    private func reloadDownloadedChapters() {
        self.catalogue = try! WNCache.fetch(by: self.catalogue.url, object: WNChaptersCatalogue.self)
        downloadedChapters = catalogue.downloadedChapters.sorted {
            $0.id < $1.id
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
        return downloadTask == nil ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadTask == nil ? downloadedChapters.count :
            section == 0 ? 1 : downloadedChapters.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let task = downloadTask, indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "downloads.progress", for: indexPath)
                as! DownloadedNovelProgressTableViewCell
            cell.url = task.url
            cell.update(task)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "downloads.chapter", for: indexPath)
            let chapter = downloadedChapters[indexPath.row]
            cell.textLabel?.text = chapter.properTitle() ?? chapter.article?.title
            cell.textLabel?.textColor = chapter.isRead ? .lightGray : .black
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard downloadTask == nil && section == 0 || downloadTask != nil && section == 1 else {
            return nil
        }
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "downloads.sectionHeader") as! DownloadedNovelSectionHeaderCell
        headerCell.numChaptersLabel.text = "\(downloadedChapters.count) chapters"
        let view = headerCell.contentView
        view.backgroundColor = .white
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return downloadTask != nil && section == 0 ? 0 : 50
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return downloadTask != nil && indexPath.section == 0 ? 92 : 44
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return downloadTask == nil || indexPath.section != 0
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let chapter = downloadedChapters.remove(at: indexPath.row)
            chapter.delete()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            reloadDownloadedChapters()
            tableView.reloadData()
            updateHeaderView()
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let ch = downloadedChapters[indexPath.row]
        let mark = UITableViewRowAction(style: .default, title: "Mark as \(ch.isRead ? "Unread" : "Read")") {(_, indexPath) in
            if ch.isRead {
                ch.markAsUnread()
            } else {
                ch.markAsRead()
            }
            self.chapterReadStatusUpdated()
        }
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { [unowned self] (_, indexPath) in
            self.tableView.dataSource?.tableView?(self.tableView, commit: .delete, forRowAt: indexPath)
        }
        mark.backgroundColor = #colorLiteral(red: 0.1229935065, green: 0.6172919869, blue: 0.9974135756, alpha: 1)
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