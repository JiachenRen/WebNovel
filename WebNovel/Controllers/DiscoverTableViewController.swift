//
//  DiscoverTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import PromiseKit

fileprivate let entryReuseIdentifier = "discover.entry"

class DiscoverTableViewController: UITableViewController {
    
    @IBOutlet weak var loadingView: UIView!
    
    @IBOutlet weak var listingServiceLabel: UILabel!
    
    @IBOutlet weak var sortingCriterionButton: UIButton!
    
    @IBOutlet weak var sortingOrderButton: UIButton!
    
    @IBOutlet var tableHeaderView: UIView!
    
    var mgr: WNServiceManager {
        return WNServiceManager.shared
    }
    
    var listingService: WNListingService? {
        return serviceProvider.listingService
    }
    
    var listingServiceParameter: String? {
        return listingService?.parameterValue
    }
    
    var serviceProvider: WNServiceProvider {
        return mgr.serviceProvider
    }
    
    // MARK: Listing Service
    
    var novelListing = [WebNovel]()
    var cachedCoverImages = [IndexPath: UIImage]()
    var currentPage = 1
    var fetchingInProgress = false {
        didSet {
            DispatchQueue.main.async {
                self.loadingView.isHidden = !self.fetchingInProgress
            }
        }
    }
    
    // MARK: Search
    
    let searchController = UISearchController(searchResultsController: nil)
    var isSearching = false
    var searchTimer: Timer?
    var searchTask: WNCancellableTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Titles"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true

        // Update UI
        updateListingServiceLabel()
        updateSortingCriterionButton()
        updateSortingOrderButton()
        fetchListing()
        
        // Observe notifications
        observe(.listingServiceUpdated, #selector(listingServiceUpdated))
    }
    
    @IBAction func sortingCriterionButtonTouched(_ sender: Any) {
        let controller = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        serviceProvider.listingService?.availableSortingCriteria.forEach { criterion in
            controller.addAction(UIAlertAction(title: criterion.rawValue, style: .default) { _ in
                self.mgr.serviceProvider.listingService?.sortingCriterion = criterion
                self.listingServiceUpdated()
            })
        }
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(controller, animated: true)
    }
    
    @IBAction func sortingOrderButtonTouched(_ sender: Any) {
        mgr.serviceProvider.listingService?.sortAscending.toggle()
        listingServiceUpdated()
    }
    
    @IBAction func searchButtonTouched(_ sender: Any) {
        searchController.searchBar.becomeFirstResponder()
    }
    
    @objc func listingServiceUpdated() {
        updateListingServiceLabel()
        updateSortingCriterionButton()
        updateSortingOrderButton()
        
        waitThen {
            // Reset everything
            self.reset()
            // Fetch listing data using the new listing service
            self.fetchListing()
        }
    }
    
    /// Wait for current fetches to complete, then execute the handler
    func waitThen(on queue: DispatchQueue = .main, _ handler: @escaping () -> Void) {
        let backgroundQueue = DispatchQueue(label: "com.wn.fetch-listing.wait")
        backgroundQueue.async {
            while self.fetchingInProgress {
                Thread.sleep(forTimeInterval: 0.1)
            }
            queue.async {
                handler()
            }
        }
    }
    
    func updateSortingOrderButton() {
        guard let ls = serviceProvider.listingService else {
            return
        }
        let image: UIImage = ls.sortAscending ? .sortAscIcon: .sortDescIcon
        sortingOrderButton.setImage(image, for: .normal)
    }
    
    func updateSortingCriterionButton() {
        let title = serviceProvider.listingService?.sortingCriterion?.rawValue ?? "None"
        sortingCriterionButton.setTitle(title, for: .normal)
    }
    
    /// Updates the listing service label
    func updateListingServiceLabel() {
        guard let listingService = serviceProvider.listingService else {
            listingServiceLabel.text = "Listing service unavailable"
            return
        }
        var parameterStr = ""
        if let parameter = listingService.parameterValue {
            parameterStr = " / \(parameter)"
        }
        listingServiceLabel.text = "Listing - \(listingService.serviceType.rawValue)\(parameterStr)"
    }
    
    func reset() {
        // Reset current page
        currentPage = 1
        // Clear listing data & cover image cache from previous listing
        cachedCoverImages = [:]
        novelListing = []
        tableView.reloadData()
    }
    
    func fetchListing() {
        if fetchingInProgress {
            return
        }
        fetchingInProgress = true
        serviceProvider.listingService?.fetchListing(page: currentPage)
            .done(on: .main) { webNovels in
                self.novelListing.append(contentsOf: webNovels)
                self.tableView.reloadData()
                self.currentPage += 1
            }.ensure {
                self.fetchingInProgress = false
            }.catch(presentError)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return novelListing.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: entryReuseIdentifier, for: indexPath)
        guard let discoverCell = cell as? DiscoverTableViewCell else {
            return cell
        }
        let wn = novelListing[indexPath.row]
        discoverCell.setWNMetadata(wn)
        
        // Load cover image
        if let image = cachedCoverImages[indexPath] {
            discoverCell.setCoverImage(image)
        } else {
            discoverCell.loadCoverImage { image in
                if !self.isSearching {
                    self.cachedCoverImages[indexPath] = image
                }
            }
        }
        
        if isSearching {
            discoverCell.loadDetails()
        }
        
        return discoverCell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 185
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isSearching {
            return
        }
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if distanceFromBottom < height {
            fetchListing()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let infoController = segue.destination as? InformationTableViewController,
            let idx = tableView.indexPathForSelectedRow?.row {
            let wn = novelListing[idx]
            infoController.webNovel = wn
        }
    }
}

extension DiscoverTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let name = searchController.searchBar.text, isSearching else {
            return
        }
        searchTimer?.invalidate()
        // Introduce latency before filing the search request
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) {
            [unowned self] timer in
            // If the search task is already running, cancel it and launch a new one,
            // since the query is updated
            self.searchTask?.isCancelled = true
            self.searchTask = WNCancellableTask { task in
                self.reset()
                self.fetchingInProgress = true
                self.serviceProvider.search(byName: name)
                    .done(on: .main) {
                        if !task.isCancelled {
                            // Only update the search results if the task is the most updated one
                            print("Search task completed with query \(name)")
                            self.novelListing = $0
                            self.tableView.reloadData()
                        } else {
                            print("Search task cancelled with query \(name)")
                        }
                    }.ensure {
                        self.fetchingInProgress = task.isCancelled
                    }.catch(self.presentError)
            }
            self.searchTask?.run()
        }
    }
}

extension DiscoverTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        tableView.tableHeaderView = tableHeaderView
        // Cancel current search task; cancel latent search task.
        searchTask?.isCancelled = true
        searchTimer?.invalidate()
        isSearching = false
        reset()
        fetchListing()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        tableView.tableHeaderView = nil
        isSearching = true
    }
}
