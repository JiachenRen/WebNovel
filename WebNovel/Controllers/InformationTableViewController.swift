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
    case entry = "information.entry"
}

fileprivate enum Section: String, CaseIterable {
    case summary = "Summary"
    case genres = "Genres"
    case stats = "Stats"
    case facts = "Other Facts"
    case relatedSeries = "Related Series"
    case recommendations = "Recommendations"
}

class InformationTableViewController: UITableViewController {
    
    @IBOutlet weak var coverImageView: UIImageView!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var readResumeLabel: UILabel!
    
    @IBOutlet weak var readResumeButton: UIButton!
    
    var mgr: WNServiceManager {
        return WNServiceManager.shared
    }
    
    var lastReadChapter: WNChapter? {
        if let url = WNCache.fetch(by: webNovel.url, object: WNChaptersCatalogue.self)?.lastReadChapter {
            return WNCache.fetch(by: url, object: WNChapter.self)
        }
        return nil
    }
    
    fileprivate var sections: [Section] {
        var secs = Section.allCases
        if webNovel.relatedSeries == nil {
            secs.removeAll(where: {$0 == .relatedSeries})
        }
        if webNovel.recommendations == nil {
            secs.removeAll(where: {$0 == .recommendations})
        }
        return secs
    }
    
    var facts: [(String, PartialKeyPath<WebNovel>)] = [
        ("Year", \WebNovel.year),
        ("Rating", \WebNovel.rating),
        ("Votes", \WebNovel.votes),
        ("Language", \WebNovel.language),
        ("Organization", \WebNovel.organization),
        ("Type", \WebNovel.type),
        ("Authors", \WebNovel.authors),
        ("Other Names", \WebNovel.aliases)
    ]
    
    var availableFacts: [(String, String)] {
        func describe(_ v: Any) -> String? {
            if let arr = v as? [String] {
                return arr.joined(separator: "\n")
            } else if let n: Any = v as? String ?? v as? Double ?? v as? Int {
                return String(describing: n)
            }
            return nil
        }
        return facts.compactMap { key, value in
            guard let v = webNovel?[keyPath: value],
                let str = describe(v) else {
                return nil
            }
            return (key, str)
        }
    }
    
    var webNovel: WebNovel!
    
    var firstChapter: WNChapter?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorColor = .clear
        tableView.backgroundColor = .white
        loadWNInformation()
        findFirstChapter()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateReadResumeStatus()
    }
    
    private func updateReadResumeStatus() {
        readResumeLabel.text = lastReadChapter == nil ? "Read" : "Resume"
        let enabled = lastReadChapter != nil || firstChapter != nil
        readResumeLabel.isEnabled = enabled
        readResumeButton.isEnabled = enabled
    }
    
    @IBAction func favoriteButtonTapped(_ sender: Any) {
        
    }
    
    /// Load and present detailed information about the WN
    private func loadWNInformation() {
        presentWebNovel()
        mgr.serviceProvider.loadDetails(webNovel, cachePolicy: .usesCache)
            .done { wn in
                self.webNovel = wn
                self.loadCoverImage()
                self.presentWebNovel()
            }.catch(presentError)
    }
    
    private func loadCoverImage() {
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
    }
    
    private func findFirstChapter() {
        mgr.serviceProvider.loadChaptersCatagoue(from: webNovel.url, cachePolicy: .usesCache)
            .done(on: .main) { catalogue in
                if let url = catalogue.firstChapter {
                    self.firstChapter = WNCache.fetch(by: url, object: WNChapter.self)
                }
                self.updateReadResumeStatus()
            }.catch(presentError)
    }
    
    private func presentWebNovel() {
        titleLabel.text = webNovel.title
        statusLabel.text = webNovel.status ?? "Status Unknown"
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .facts:
            return availableFacts.count
        case .recommendations:
            return webNovel.recommendations?.count ?? 0
        case .relatedSeries:
            return webNovel.relatedSeries?.count ?? 0
        default:
            return 1
        }
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
        case .recommendations, .relatedSeries:
            let cell = makeCell(.entry, as: DiscoverTableViewCell.self)
            if let wn = webNovelForIndexPath(at: indexPath) {
                cell.setWNMetadata(wn)
                cell.coverImageView.image = nil
                cell.activityIndicatorView.startAnimating()
                mgr.serviceProvider.loadDetails(wn, cachePolicy: .usesCache)
                .done { wn in
                    cell.setWNMetadata(wn)
                    cell.coverImageView.image = .coverPlaceholder
                    cell.coverImageView.alpha = 0.1
                    if let url = wn.coverImageUrl {
                        downloadImage(from: url).done { image in
                            cell.setCoverImage(image)
                        }.catch { err in
                            print(err)
                            cell.setCoverImage(.coverPlaceholder)
                        }
                    } else {
                        cell.setCoverImage(.coverPlaceholder)
                    }
                }.catch {err in
                    print(err)
                }
            }
            return cell
        }
    }
    
    private func webNovelForIndexPath(at indexPath: IndexPath) -> WebNovel? {
        let list = sections[indexPath.section] == .recommendations ? webNovel.recommendations : webNovel.relatedSeries
        return list?[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let section = sections[indexPath.section]
        return section == .recommendations || section == .relatedSeries ? indexPath : nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard.init(name: "NovelDetails", bundle: nil)
        guard let infoController = storyboard.instantiateViewController(withIdentifier: "novelDetails.information") as? InformationTableViewController,
            let wn = webNovelForIndexPath(at: indexPath) else {
            return
        }
        infoController.webNovel = wn
        infoController.navigationItem.title = wn.title
        navigationController?.pushViewController(infoController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let chaptersController = segue.destination as? ChaptersTableViewController {
            chaptersController.catalogueUrl = webNovel.url
        } else if let nav = segue.destination as? UINavigationController {
            if let chapterController = nav.topViewController as? ChapterViewController {
                chapterController.chapter = lastReadChapter ?? firstChapter
            }
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
