//
//  ChapterContentSourceTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 2/17/20.
//  Copyright © 2020 Jiachen Ren. All rights reserved.
//

import UIKit

class ChapterContentSourceTableViewController: UITableViewController {
    var contentSources: [WNChapter] = []
    var contentSourceId: Int?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        postNotification(.contentSourceIdUpdated, object: indexPath.row)
        self.contentSourceId = indexPath.row
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return contentSources.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contentSource.source", for: indexPath)
        let contentSource = contentSources[indexPath.row]
        cell.textLabel?.text = contentSource.article?.title
        let compactTxtContent = contentSource.article?.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "No content available"
        cell.detailTextLabel?.text = compactTxtContent == "" ? "No content available" : compactTxtContent
        cell.accessoryType = contentSourceId == indexPath.row ? .checkmark : .none
        return cell
    }
}
