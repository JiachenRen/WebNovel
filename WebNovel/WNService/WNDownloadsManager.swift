//
//  WNChaptersDownloadTask.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/10/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit

class WNDownloadsManager {
    static var shared: WNDownloadsManager = {
        return WNDownloadsManager()
    }()
    
    private let queue = DispatchQueue(
        label: "com.jiachenren.WebNovel.download",
        qos: .utility,
        attributes: .concurrent,
        autoreleaseFrequency: .workItem,
        target: nil
    )
    
    var currentTasks: [String: Task] = [:]
    
    private func register(_ task: Task) {
        if let existing = currentTasks[task.url] {
            existing.pending.append(contentsOf: task.pending)
        } else {
            currentTasks[task.url] = task
        }
    }
    
    func download(_ task: Task, using provider: WNServiceProvider) {
        register(task)
        postNotification(.downloadTaskInitiated, object: task)
        queue.async { [unowned self] in
            var chapters = task.pending.filter { ch in !task.completed.contains(where: {$0.url == ch.url})}
            
            func recursiveDownload(_ chapter: WNChapter) {
                provider.loadChapter(chapter, cachePolicy: .overwritesCache)
                    .done { chapter in
                        task.completed.append(chapter)
                    }.ensure {
                        task.pending.removeAll(where: {$0.url == chapter.url})
                        if chapters.count > 0 {
                            recursiveDownload(chapters.removeFirst())
                        } else if task.pending.count == 0 && self.currentTasks[task.url] != nil {
                            self.currentTasks.removeValue(forKey: task.url)
                            postNotification(.downloadTaskCompleted, object: task)
                        }
                        postNotification(.downloadTaskStatusUpdated, object: task)
                    }.catch { e in
                        print(e)
                        task.failed.append(chapter)
                }
            }
            
            // Allow a maximum of 10 concurrent downloads
            for _ in 0..<10 {
                if chapters.count == 0 {
                    break
                }
                recursiveDownload(chapters.removeFirst())
            }
        }
    }
    
    class Task {
        var pending: [WNChapter]
        var completed = [WNChapter]() {
            didSet { updateStats() }
        }
        var failed = [WNChapter]() {
            didSet { updateStats() }
        }
        
        /// Stats
        var durations: [TimeInterval] = []
        var estimatedTimeRemaining: TimeInterval? = nil
        var lastUpdated: TimeInterval = .now
        
        /// Url for the web novel
        var url: String
        
        init(_ url: String, _ chapters: [WNChapter]) {
            self.pending = chapters
            self.url = url
        }
        
        private func updateStats() {
            let now: TimeInterval = .now
            durations.append(now - lastUpdated)
            durations.removeAll(where: {$0.isInfinite || $0.isNaN})
            if durations.count > 5 {
                let avg = durations.reduce(0) {$0 + $1} / Double(durations.count)
                estimatedTimeRemaining = avg * Double(pending.count)
            }
            lastUpdated = now
        }
    }
}
