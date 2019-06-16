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
import SwiftSoup

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sp: WNServiceProvider = NovelUpdatesProvider()
        sp.search(byName: "Kumo desu ga").then {
            sp.fetchChapters(for: $0.first!)
        }.then {
            sp.loadChapter($0.first!)
        }.done {
            print($0)
        }.catch { err in
            print(err)
        }
    }
    
}

