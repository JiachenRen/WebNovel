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
        
//        let sp: WNServiceProvider = NovelUpdates()
//        sp.search(byName: "Kumo desu ga").then {
//            sp.fetchChapters(for: $0.first!, cachePolicy: .usesCache)
//        }.done { chapters in
//            chapters.forEach {
//                print($0)
//            }
//        }.catch { err in
//            print(err)
//        }
        
//        .map { chapters in
//            Array(chapters[100...200])
//        }.then { chapters in
//            sp.loadChapters(chapters)
//        }.done { arg in
//            let (loaded, failed) = arg
//            print(loaded.map {$0.id}.sorted {$0 < $1}.map {String($0)}.joined(separator: ", "))
//            print(failed.map {$0.id}.sorted {$0 < $1}.map {String($0)}.joined(separator: ", "))
//        }.catch { err in
//            print((err as! WNError).localizedDescription)
//        }
    }
    
}

