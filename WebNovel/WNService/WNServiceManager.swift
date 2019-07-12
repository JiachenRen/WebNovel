//
//  WNServiceManager.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/18/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit

class WNServiceManager {
    static var shared: WNServiceManager = {
        return WNServiceManager()
    }()
    
    /// List of available service providers.
    /// SPI -> service provider
    static var availableServiceProviders: [String: WNServiceProvider] = [
        NovelUpdates.identifier: NovelUpdates()
    ]
    
    var serviceProvider: WNServiceProvider = availableServiceProviders[NovelUpdates.identifier]!
}
