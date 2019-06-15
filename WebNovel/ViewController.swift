//
//  ViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/13/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import PromiseKit
import Alamofire

class ViewController: UIViewController {
    var serviceProvider: WNServiceProvider = NovelUpdatesProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        serviceProvider.delegate = self
        serviceProvider.fetchListing(for: .ranking, page: 201)
//        serviceProvider.search(byName: "The King")
    }
    
}

extension ViewController: WNServiceProviderDelegate {
    func wnListingFetched(_ entries: [WNItem]) {
        entries.forEach {
            print($0, terminator: "\n\n")
        }
    }
    
    func searchCompleted(_ results: [WNItem]) {
        results.forEach {
            print($0, terminator: "\n\n")
        }
    }
}

