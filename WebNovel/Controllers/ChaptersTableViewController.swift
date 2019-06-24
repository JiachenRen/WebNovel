//
//  ChaptersTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/24/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

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
    }
    
    @IBAction func orderButtonTapped(_ sender: Any) {
        sortDescending.toggle()
        chapters.reverse()
        let title = sortDescending ? "Sort By: Descending ↓" : "Sort By: Ascending ↑"
        orderButton.setTitle(title, for: .normal)
        self.tableView.reloadData()
    }
    
    private func groupChaptersIntoSections() {
        if chaptersInSection == 0 {
            sections = [chapters]
            return
        }
        sections = chapters.enumerated().split { arg in
                let (idx, _) = arg
                return idx % chaptersInSection == 0
            }.map { slice in
                slice.map {$0.element}
        }
    }
    
    private func loadChapters() {
        isLoadingChapters = true
        WNServiceManager.shared.serviceProvider.fetchChapters(for: webNovel, cachePolicy: .usesCache)
            .done(on: .main) { chapters in
                self.chapters = chapters
                if !self.sortDescending {
                    self.chapters.reverse()
                }
                self.chaptersCountLabel.text = "\(chapters.count) chapters"
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
        chapterCell.chapterLabel.text = sections[indexPath.section][indexPath.row].chapter
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
}
