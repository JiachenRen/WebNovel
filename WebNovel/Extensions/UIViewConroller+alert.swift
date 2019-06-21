//
//  UIViewConroller+error.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/21/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func alert(title: String, msg: String, actions: [UIAlertAction] = [UIAlertAction(title: "Ok", style: .default)]) {
        let controller = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        for action in actions {
            controller.addAction(action)
        }
        self.present(controller, animated: true)
    }
}
