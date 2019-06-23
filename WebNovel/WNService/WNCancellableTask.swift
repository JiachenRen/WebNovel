//
//  CancellablePromise.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/23/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import PromiseKit

class WNCancellableTask {
    typealias Task = (WNCancellableTask) -> Void
    var isCancelled = false
    var task: Task
    
    init(_ task: @escaping Task) {
        self.task = task
    }
    
    func run() {
        task(self)
    }
}
