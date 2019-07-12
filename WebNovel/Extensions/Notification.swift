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
    static let sanitizationUpdated = Notification.Name("sanitization-updated")
    static let reloadChapter = Notification.Name("reload-chapter")
    static let attributesUpdated = Notification.Name("attributes-updated")
    static let fontFamilyUpdated = Notification.Name("font-family-updated")
    static let downloadTaskInitiated = Notification.Name("download-task-initiated")
    static let downloadTaskStatusUpdated = Notification.Name("download-task-status-updated")
    static let downloadTaskCompleted = Notification.Name("download-task-completed")
    static let chapterReadStatusUpdated = Notification.Name("chapter-read-status-updated")
    static let finishedReadingChapter = Notification.Name("finished-reading-chapter")
    static let startedReadingNextChapter = Notification.Name("started-reading-next-chapter")
    static let startedReadingChapter = Notification.Name("started-reading-chapter")
    static let requestShowChapter = Notification.Name("request-show-chapter")
}

func postNotification(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
    NotificationCenter.default.post(
        name: name,
        object: object,
        userInfo: userInfo
    )
    print("posted notification: \(name)")
}
