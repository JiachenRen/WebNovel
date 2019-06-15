//
//  WNError.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/14/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

enum WNError: Error {
    case unknownResponseError
    case parsingError(_ supplementalMsg: String)
    
    var localizedDescription: String {
        switch self {
        case .unknownResponseError:
            return "An unknown response error has occurred"
        case .parsingError(let msg):
            return "Failed to parse response html - \(msg)"
        }
    }
}
