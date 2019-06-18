//
//  WNNotification.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/18/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let listingServiceUpdated = Notification.Name("listing-service-updated")
}

func postNotification(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
    NotificationCenter.default.post(
        name: name,
        object: object,
        userInfo: userInfo
    )
    print("posted notification: \(name)")
}
