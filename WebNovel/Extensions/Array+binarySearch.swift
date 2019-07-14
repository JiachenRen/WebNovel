//
//  Array+binarySearch.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/14/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

extension Array {
    
    /// Binary search for an element in an sorted array.
    /// - index: A function that maps the element to its index
    func binarySearch(for element: Element, index: (Element) -> Int) -> Int? {
        // Binary search
        var left = 0;
        var right = count - 1
        
        while (true) {
            let currentIndex = (left + right) / 2
            if index(self[currentIndex]) == index(element) {
                return currentIndex
            } else if (left > right) {
                return nil
            } else {
                if index(self[currentIndex]) > index(element) {
                    right = currentIndex - 1
                } else {
                    left = currentIndex + 1
                }
            }
        }
    }
}
