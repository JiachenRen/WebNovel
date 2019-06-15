//
//  WNServiceProviderDelegate.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/14/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

protocol WNServiceProviderDelegate: NSObject {
    func wnEntriesFetched(_ entries: [WNItem])
    func searchCompleted(_ results: [WNItem])
}
