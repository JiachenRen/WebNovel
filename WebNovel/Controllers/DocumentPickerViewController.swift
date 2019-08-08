//
//  DocumentBrowserViewController.swift
//  FileSystemDemo
//
//  Created by Jiachen Ren on 8/6/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit


class DocumentPickerViewController: UIDocumentPickerViewController, UIDocumentPickerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        allowsMultipleSelection = true
    }
    
    // MARK: UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("Selected URLs: \(urls)")
    }
    
}

