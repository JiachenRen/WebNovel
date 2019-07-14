//
//  GroupsFilterTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/14/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class GroupsFilterTableViewController: UITableViewController {
    
    var catalogue: WNChaptersCatalogue!

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return catalogue.groups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupsFilter.group", for: indexPath)
        let grp = catalogue.groups[indexPath.row]
        cell.textLabel?.text = grp.name
        cell.accessoryType = grp.isEnabled ? .checkmark : .none
        return cell
    }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        catalogue.groups[indexPath.row].isEnabled = !catalogue.groups[indexPath.row].isEnabled
        WNCache.save(catalogue)
        tableView.reloadData()
        postNotification(.groupsFilterUpdated, object: catalogue)
    }

}
