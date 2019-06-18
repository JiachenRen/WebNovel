//
//  WebNovelTests.swift
//  WebNovelTests
//
//  Created by Jiachen Ren on 6/13/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import XCTest
import PromiseKit
@testable import WebNovel

class WebNovelTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testChaptersCatalogueCache() throws {
        let wnUrl = "www.novelupdates.com/id/234939"
        let chapters: [WNChapter] = [
            .init(url: "www.example.com", chapter: "Chapter 1", id: 1),
            .init(url: "www.jiachenren.com", chapter: "Chapter 2", id: 2),
            .init(url: "www.google.com", chapter: "Chapter 3", id: 3),
        ]
        let chaptersCatalogue = WNChaptersCatalogue(wnUrl, chapters)
        try WNCache.save(chaptersCatalogue)
        var f: WNChaptersCatalogue = try WNCache.fetchChaptersCatalogue(wnUrl)!
        print(f)
        XCTAssert(f.chapters.first!.url! == "www.example.com")
        chaptersCatalogue.chapters[1] = WNChapter(url: "www.changed.com", chapter: "Chapter 5", id: 4)
        try WNCache.save(chaptersCatalogue)
        f = try WNCache.fetchChaptersCatalogue(wnUrl)!
        print(f)
        XCTAssert(f.chapters[1].url == "www.changed.com")
        XCTAssert(try WNCache.fetchChaptersCatalogue("www.dne.com") == nil)
    }
    
    func testWNChapterCache() throws {
        let chapter = WNChapter(url: "www.novelupdates.com/id/39243042", chapter: "CC 3", id: 2)
        try WNCache.save(chapter)
        XCTAssert(try WNCache.fetchChapter("www.novelupdates.com/id/39243042")!.chapter == "CC 3")
    }
    
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

