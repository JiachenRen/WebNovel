//
//  DownloadedNovelProgressTableViewCell.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/10/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class DownloadedNovelProgressTableViewCell: UITableViewCell {
    
    @IBOutlet weak var numChaptersRemainingLabel: UILabel!
    
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var pauseResumeButton: UIButton!
    
    var url: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        observe(.downloadTaskStatusUpdated, #selector(downloadTaskStatusUpdated(_:)))
    }
    
    func update(_ task: WNDownloadsManager.Task) {
        numChaptersRemainingLabel.text = "\(task.pending.count) chapter(s) remaining"
        timeRemainingLabel.text = task.estimatedTimeRemaining?.formattedString ?? "calculating"
        let resolved = Float(task.failed.count + task.completed.count)
        let all = Float(task.pending.count + Int(resolved))
        progressView.progress = resolved / all
    }
    
    @objc func downloadTaskStatusUpdated(_ notif: Notification) {
        guard let task = notif.object as? WNDownloadsManager.Task,
            task.url == self.url else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.update(task)
        }
    }
}
