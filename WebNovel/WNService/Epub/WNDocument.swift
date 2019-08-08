//  Document.swift
//  FileSystemDemo
//
//  Created by Jiachen Ren on 8/6/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class WNDocument: UIDocument {
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    }
}

