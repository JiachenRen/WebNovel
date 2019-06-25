//
//  FontFamilyTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/25/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class FontFamilyTableViewController: UITableViewController {

    var currentFontFamily: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UIFont.familyNames.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fontFamily.name", for: indexPath)
        let family = UIFont.familyNames[indexPath.row]
        let attributes = [NSAttributedString.Key.font: UIFont(name: family, size: 17)!]
        let example = NSAttributedString(string: family, attributes: attributes)
        cell.textLabel?.attributedText = example
        cell.accessoryType = currentFontFamily == family ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Turn off checkmark for the outdated font family
        if let row = UIFont.familyNames.enumerated().filter({$0.element == currentFontFamily}).first?.offset {
            tableView.cellForRow(at: IndexPath(row: row, section: 0))?.accessoryType = .none
        }
        // Update font family
        currentFontFamily = UIFont.familyNames[indexPath.row]
        // Turn on checkmark for current font family
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        postNotification(.fontFamilyUpdated, object: currentFontFamily)
    }
}
