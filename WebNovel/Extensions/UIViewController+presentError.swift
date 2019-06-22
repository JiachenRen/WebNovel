//
//  UIViewController+error.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/21/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func presentError(_ err: Error) {
        let errMsg = (err as? WNError)?.localizedDescription ?? err.localizedDescription
        self.alert(title: "Error", msg: errMsg)
    }
}
