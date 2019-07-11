//
//  ChaptersTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/24/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import SafariServices

private let reuseIdentifier = "chapters.chapter"

class ChaptersTableViewController: UITableViewController {
    
    @IBOutlet weak var chaptersCountLabel: UILabel!
    
    @IBOutlet weak var orderButton: UIButton!
    
    @IBOutlet weak var loadingView: UIView!
    
    var webNovel: WebNovel!
    var chapters: [WNChapter] = [] {
        didSet {groupChaptersIntoSections()}
    }
    var sections: [[WNChapter]] = []
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
        loadChapters()
        
        observe(.downloadTaskInitiated, #selector(chaptersAddedToDownloads))
    }
    
    @IBAction func orderButtonTapped(_ sender: Any) {
        sortDescending.toggle()
        chapters.reverse()
        let title = sortDescending ? "Sort By: Descending ↓" : "Sort By: Ascending ↑"
        orderButton.setTitle(title, for: .normal)
        self.tableView.reloadData()
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
    
    private func loadChapters() {
        isLoadingChapters = true
        WNServiceManager.shared.serviceProvider.fetchChaptersCatagoue(for: webNovel, cachePolicy: .usesCache)
            .done(on: .main) { catalogue in
                self.chapters = catalogue.chapters
                self.chapters.sort(by: {self.sortDescending ? $0.id > $1.id : $0.id < $1.id})
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
        return sections[indexPath.section][indexPath.row]
    }
    
    // MARK: - Table view data source

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
        chapterCell.chapterLabel.text = chapter(at: indexPath).chapter
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
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController {
            if let chapterController = nav.topViewController as? ChapterViewController,
                let indexPath = tableView.indexPathForSelectedRow {
                chapterController.chapter = chapter(at: indexPath)
            } else if let downloadController = nav.topViewController as? DownloadChaptersTableViewController {
                downloadController.webNovelUrl = webNovel.url
            }
        }
    }
}
