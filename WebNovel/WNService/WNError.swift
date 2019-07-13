//
//  WNError.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/14/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

enum WNError: Error, Equatable {
    case unknownResponseError
    case parsingError(_ supplementalMsg: String)
    case missingParameter(_ parameter: String)
    case urlNotFound
    case invalidUrl
    case unsupportedListingService
    case invalidListingServiceParameter
    case unsupportedSortingCriterion
    case incorrectEncoding
    case hostNotFound
    case unsupportedHost(_ host: String)
    case invalidParsingInstruction
    case decodingFailed
    case managedContextNotFound
    case cancelled
    case coverImageUrlNotFound
    case instanceDeallocated
    case loadingFailed
    
    var localizedDescription: String {
        switch self {
        case .unknownResponseError:
            return "An unknown response error has occurred"
        case .parsingError(let msg):
            return "Failed to parse response html - \(msg)"
        case .urlNotFound:
            return "Unable to find URL for this WN"
        case .unsupportedListingService:
            return "The requested listing service is not supported"
        case .invalidListingServiceParameter:
            return "The requested listing service option is not supported"
        case .unsupportedSortingCriterion:
            return "The requested sorting criteria is not available for this listing service"
        case .missingParameter(let p):
            return "Missing parameter \(p)"
        case .incorrectEncoding:
            return "The specified encoding does not match the response data"
        case .hostNotFound:
            return "Unable to find host"
        case .unsupportedHost(let host):
            return "The host \(host) is not yet supported"
        case .invalidParsingInstruction:
            return "Invalid parsing instruction"
        case .decodingFailed:
            return "Failed to decode html string"
        case .managedContextNotFound:
            return "Unable to find managed object context"
        case .cancelled:
            return "The operation is cancelled"
        case .coverImageUrlNotFound:
            return "The url for the cover image is not found"
        case .invalidUrl:
            return "The url is invalid"
        case .instanceDeallocated:
            return "The instance has been deallocated"
        case .loadingFailed:
            return "Failed to load content"
        }
    }
}
