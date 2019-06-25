//
//  Readability.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/25/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import JavaScriptCore

/// Exposes Javascript API
fileprivate let exposeParseFn = """
var JSDOM = require('jsdom').JSDOM
var Readability = require('readability')
function parse(htmlStr) {
    var doc = new JSDOM(htmlStr)
    var reader = new Readability(doc.window.document)
    return reader.parse()
}
"""

/// Interface that wraps core functionality of Readability.js,
/// a script for extracting relevant content from any web page
class Readability {
    private var parseFn: JSValue
    
    init() {
        // Initialize Javascript Context
        let ctx = JSContext()!
        let window = JSValue(newObjectIn: ctx)!
        ctx.setObject(window, forKeyedSubscript: "window" as NSString)
        
        // Redirect log messages
        let consoleLog: @convention(block) (String) -> Void = { message in
            print("JS Log: " + message)
        }
        ctx.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "_consoleLog" as NSCopying & NSObjectProtocol)
        
        // Redirect exception messages
        ctx.exceptionHandler = { context, exception in
            print("JS Error: \(exception!)")
        }
        
        // Load Readability and JSDOM from bundle.js into the JS Context
        let scriptPath = Bundle.main.path(forResource: "bundle", ofType: "js")
        let script = try! String(contentsOfFile: scriptPath!)
        ctx.evaluateScript(script)
        
        // Let the magic happen!
        ctx.evaluateScript(exposeParseFn)
        self.parseFn = ctx.objectForKeyedSubscript("parse")!
    }
    
    /// Exposes Javascript API Readability:parse
    /// Extracts relevant information for an article from any web page.
    func parse(_ rawHtml: String) -> Article? {
        guard let dict = parseFn.call(withArguments: [rawHtml])?.toDictionary() else {
            return nil
        }
        var article = Article()
        article.title = dict["title"] as? String
        article.content = dict["content"] as? String
        article.textContent = dict["textContent"] as? String
        return article
    }
}
