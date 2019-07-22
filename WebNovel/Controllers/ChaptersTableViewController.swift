//
//  ChaptersTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/24/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import SafariServices
import PromiseKit

private let reuseIdentifier = "chapters.chapter"

class ChaptersTableViewController: UITableViewController {
    
    @IBOutlet weak var chaptersCountLabel: UILabel!
    
    @IBOutlet weak var orderButton: UIButton!
    
    @IBOutlet weak var loadingView: UIView!
    
    @IBOutlet weak var filterButton: UIBarButtonItem!
    
    var catalogueUrl: String!
    var catalogue: WNCatalogue? {
        didSet {filterButton.isEnabled = catalogue != nil}
    }
    var chapters: [String] = [] {
        didSet {groupChaptersIntoSections()}
    }
    var sections: [[String]] = []
    var desiredSections = 20
    var chaptersInSection: Int {
        return chapters.count / desiredSections
    }
    var sortDescending = true
    var isLoadingChapters = false {
        didSet {loadingView.isHidden = !isLoadingChapters}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sectionIndexMinimumDisplayRowCount = 100
        filterButton.isEnabled = catalogue != nil
        
        observe(.downloadTaskInitiated, #selector(chaptersAddedToDownloads))
        observe(.groupsFilterUpdated, #selector(loadChapters))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadChapters()
    }
    
    @IBAction func orderButtonTapped(_ sender: Any) {
        sortDescending.toggle()
        chapters.reverse()
        let title = sortDescending ? "Sort By: Descending ↓" : "Sort By: Ascending ↑"
        orderButton.setTitle(title, for: .normal)
        self.tableView.reloadData()
    }
    
    @IBAction func filterButtonTapped(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "GroupsFilter", bundle: .main)
        let nav = storyBoard.instantiateViewController(withIdentifier: "groupsFilter.nav") as! UINavigationController
        nav.modalPresentationStyle = .popover
        nav.popoverPresentationController?.delegate = self
        nav.popoverPresentationController?.barButtonItem = filterButton
        if let groupsFilterController = nav.topViewController as? GroupsFilterTableViewController {
            groupsFilterController.catalogue = catalogue
            present(nav, animated: true)
        }
    }
    
    @objc private func chaptersAddedToDownloads() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            let controller = UIAlertController(title: "Added To Downloads", message: nil, preferredStyle: .alert)
            self.present(controller, animated: true) {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    controller.dismiss(animated: true)
                }
            }
        }
    }
    
    private func groupChaptersIntoSections() {
        if chaptersInSection == 0 {
            sections = [chapters]
            return
        }
        sections = []
        for i in stride(from: 0, to: chapters.count, by: chaptersInSection) {
            var endIdx = i + chaptersInSection
            endIdx = endIdx > chapters.count ? chapters.count : endIdx
            sections.append(Array(chapters[i..<endIdx]))
        }
    }
    
    @objc private func loadChapters() {
        isLoadingChapters = true
        WNServiceManager.shared.serviceProvider.loadCatalogue(from: catalogueUrl, cachePolicy: .usesCache)
            .done(on: .main) { catalogue in
                self.catalogue = catalogue
                self.chapters = catalogue.enabledChapterUrls
                self.chapters = self.sortDescending ? Array(self.chapters.reversed()) : self.chapters
                self.chaptersCountLabel.text = "\(self.chapters.count) chapters"
                self.tableView.reloadData()
            }.ensure {
                self.isLoadingChapters = false
            }.catch { err in
                self.alert(
                    title: "Error",
                    msg: (err as? WNError)?.localizedDescription ?? err.localizedDescription,
                    actions: [
                        .init(title: "Ok", style: .cancel),
                        .init(title: "Retry", style: .default) {
                            [unowned self] _ in
                            self.loadChapters()
                        }
                    ]
                )
        }
    }
    
    private func chapter(at indexPath: IndexPath) -> WNChapter {
        return WNCache.fetch(by: sections[indexPath.section][indexPath.row], object: WNChapter.self)!
    }
    
}

// MARK: - Table view data source & delegate

extension ChaptersTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        guard let chapterCell = cell as? ChapterTableViewCell else {
            return cell
        }
        let ch = chapter(at: indexPath)
        chapterCell.titleLabel.text = ch.name
        chapterCell.titleLabel.textColor = ch.isRead ? .lightGray : .black
        return cell
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        let range = (0..<sections.count).map {$0}
        let indices = sortDescending ? range.reversed() : range
        return indices.map {$0 * chaptersInSection + 1}.map {"\($0)"}
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "chapters->chapter", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let ch = chapter(at: indexPath)
        let action = UITableViewRowAction(style: .default, title: "Mark as \(ch.isRead ? "Unread" : "Read")") { [weak self] (_, indexPath) in
            ch.markAs(isRead: !ch.isRead, self?.catalogue)
            self?.tableView.reloadData()
        }
        action.backgroundColor = #colorLiteral(red: 0.1229935065, green: 0.6172919869, blue: 0.9974135756, alpha: 1)
        return [action]
    }
    
}

// MARK: - Navigation

extension ChaptersTableViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController {
            if let chapterController = nav.topViewController as? ChapterViewController,
                let indexPath = tableView.indexPathForSelectedRow {
                chapterController.chapter = chapter(at: indexPath)
            } else if let downloadController = nav.topViewController as? DownloadChaptersTableViewController {
                downloadController.webNovelUrl = catalogueUrl
            }
        } else if let groupsFilterController = segue.destination as? GroupsFilterTableViewController {
            groupsFilterController.catalogue = self.catalogue
        }
    }
    
}

// MARK: - Popover presentation controller delegate

extension ChaptersTableViewController: UIPopoverPresentationControllerDelegate {
    
    /// Ensure that the presentation controller is NOT fullscreen
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}
