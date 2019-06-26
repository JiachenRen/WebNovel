//
//  DownloadChaptersTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/26/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class DownloadChaptersTableViewController: UITableViewController {

    @IBOutlet weak var selectAllButton: UIBarButtonItem!
    
    @IBOutlet weak var selectedChaptersLabel: UIBarButtonItem!
    
    @IBOutlet weak var downloadButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedChaptersLabel.setTitleTextAttributes(
            [NSAttributedString.Key.foregroundColor: UIColor.black],
            for: .normal
        )
        updateBarItems()
    }
    
    var chapters: [WNChapter]! {
        didSet {
            selections = [Bool](repeating: false, count: chapters.count)
        }
    }
    var webNovelUrl: String!
    
    var selectedAll = false
    var selections: [Bool]!
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func selectAllButtonTapped(_ sender: Any) {
        selectAllButton.title = selectedAll ? "Deselect All" : "Select All"
        selections = [Bool](repeating: !selectedAll, count: chapters.count)
        selectedAll = !selectedAll
        tableView.reloadData()
        updateBarItems()
    }
    
    @IBAction func downloadButtonTapped(_ sender: Any) {
        let selectedChapters = zip(chapters, selections)
            .filter {$0.1}
            .map {$0.0}
        let catalogue = WNChaptersCatalogue(webNovelUrl, selectedChapters)
        postNotification(.downloadChapters, object: catalogue)
        self.dismiss(animated: true)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chapters.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "downloadChapters.chapter", for: indexPath)
        guard let chapterCell = cell as? SelectableChapterTableViewCell else {
            return cell
        }
        chapterCell.chapterLabel.text = chapters[indexPath.row].chapter
        chapterCell.deselectedStateButton.isHidden = selections[indexPath.row]
        chapterCell.selectedStateButton.isHidden = !selections[indexPath.row]
        
        return cell
    }
    
    private func toggleCell(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? SelectableChapterTableViewCell else {
            fatalError()
        }
        cell.deselectedStateButton.isHidden.toggle()
        cell.selectedStateButton.isHidden.toggle()
    }
    
    private func updateBarItems() {
        let n = selections.filter {$0}.count
        selectedChaptersLabel.title = n == 0 ? "No chapters selected" : "\(n) chapter(s) selected"
        selectedChaptersLabel.isEnabled = n != 0
        downloadButton.isEnabled = n != 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleCell(at: indexPath)
        selections[indexPath.row].toggle()
        updateBarItems()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(chapters.count) chapters"
    }

}
