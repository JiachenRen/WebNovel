//
//  InformationTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/21/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

fileprivate enum ID: String {
    case sectionHeader = "information.sectionHeader"
    case summary = "information.summary"
    case genres = "information.genres"
    case stats = "information.stats"
    case fact = "information.fact"
}

fileprivate enum Section: String, CaseIterable {
    case summary = "Summary"
    case genres = "Genres"
    case stats = "Stats"
    case facts = "Other Facts"
}

class InformationTableViewController: UITableViewController {
    
    @IBOutlet weak var coverImageView: UIImageView!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    var mgr: WNServiceManager {
        return WNServiceManager.shared
    }
    
    fileprivate var sections: [Section] = Section.allCases
    
    var facts: [(String, PartialKeyPath<WebNovel>)] = [
        ("Year", \WebNovel.year),
        ("Language", \WebNovel.language),
        ("Organization", \WebNovel.organization),
        ("Type", \WebNovel.type),
        ("Authors", \WebNovel.authors),
        ("Other Names", \WebNovel.aliases)
    ]
    
    var availableFacts: [(String, String)] {
        func describe(_ v: Any) -> String {
            if let arr = v as? [String] {
                return arr.joined(separator: "\n")
            } else if let str = v as? String {
                return str
            } else if let n = v as? Int {
                return String(n)
            }
            return "N/A"
        }
        return facts.compactMap { key, value in
            guard let v = webNovel?[keyPath: value] else {
                return nil
            }
            return (key, describe(v))
        }
    }
    
    var webNovel: WebNovel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelection = false
        tableView.separatorColor = .clear
        load()
    }
    
    @IBAction func resumeButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func chaptersButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func favoriteButtonTapped(_ sender: Any) {
        
    }
    
    /// Load and present detailed information about the WN
    func load() {
        presentWebNovel()
        mgr.serviceProvider.loadDetails(webNovel, cachePolicy: .usesCache)
            .done { wn in
                self.webNovel = wn
                self.presentWebNovel()
            }.catch(presentError)
    }
    
    func presentWebNovel() {
        if let url = webNovel.coverImageUrl {
            activityIndicatorView.startAnimating()
            downloadImage(from: url).done { image in
                self.coverImageView.image = image
            }.ensure {
                self.activityIndicatorView.stopAnimating()
            }.catch { err in
                print(err.localizedDescription)
                self.coverImageView.image = .coverPlaceholder
            }
        } else {
            coverImageView.image = .coverPlaceholder
        }
        titleLabel.text = webNovel.title
        statusLabel.text = webNovel.status ?? "Status Unknown"
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section] == .facts ? availableFacts.count : 1
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: ID.sectionHeader.rawValue)
        if let headerCell = cell as? SectionHeaderTableViewCell {
            headerCell.headlingLabel.text = sections[section].rawValue
        }
        cell?.contentView.backgroundColor = .white
        return cell?.contentView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    /// Get rid of spacing between grouped sections
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func makeCell<T>(_ id: ID, as type: T.Type) -> T {
            return tableView.dequeueReusableCell(withIdentifier: id.rawValue, for: indexPath) as! T
        }
        switch sections[indexPath.section] {
        case .summary:
            let cell = makeCell(.summary, as: SummaryTableViewCell.self)
            cell.summaryTextView.text = webNovel.fullDescription
            cell.delegate = self
            return cell
        case .genres:
            let cell = makeCell(.genres, as: GenresTableViewCell.self)
            cell.setGenres(webNovel.genres ?? [])
            return cell
        case .stats:
            let cell = makeCell(.stats, as: StatsTableViewCell.self)
            cell.setRank(webNovel.allTimeRank)
            cell.setReaders(webNovel.readers)
            return cell
        case .facts:
            let cell = makeCell(.fact, as: FactTableViewCell.self)
            let (name, value) = availableFacts[indexPath.row]
            cell.nameLabel.text = name
            cell.valueLabel.text = value
            return cell
        }
    }
}

extension InformationTableViewController: InformationTableViewCellDelegate {
    func cellLayoutDidChange() {
        tableView.performBatchUpdates({
            tableView.setNeedsLayout()
        })
    }
}
