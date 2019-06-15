//
//  WNServiceProvider.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/14/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire

protocol WNServiceProvider {
    var delegate: WNServiceProviderDelegate? {get set}
    var availableListingServices: [ListingService] {get}
    func search(byName query: String)
    func fetchListing(for: ListingService, page: Int)
}
