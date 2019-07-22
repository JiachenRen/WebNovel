//
//  Alamofire+htmlRequestResponse.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/15/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import UIKit

/// Initiates a html response request to the given URL with speficied parameters
/// - Returns: A promise wrapping the response html string.
func htmlRequestResponse(
    _ url: URLConvertible,
    method: HTTPMethod = .get,
    parameters: Parameters = [:],
    encoding: String.Encoding = .utf8) -> Promise<String> {
    return Promise {seal in
        Alamofire.request(url, method: method, parameters: parameters)
            .validate()
            .response { response in
                guard let data = response.data else {
                    let err = WNError.unknownResponseError
                    seal.reject(response.error ?? err)
                    return
                }
                guard let htmlStr = String(data: data, encoding: encoding) else {
                    seal.reject(WNError.incorrectEncoding)
                    return
                }
                seal.fulfill(htmlStr)
        }
    }
}

/// Initiates a data request to the given image URL
/// If the requested image exists in cache, load it from cache.
/// - Returns: A promise wrapping a UIImage object
func downloadImage(from url: URLConvertible, cachePolicy: WNCache.Policy = .usesCache) -> Promise<UIImage> {
    if cachePolicy == .usesCache, let url = try? url.asURL().absoluteString {
        if let image = WNCache.fetch(by: url, object: WNCoverImage.self)?.uiImage {
            print("Loaded image at url \(url) from core data")
            return Promise { seal in
                seal.fulfill(image)
            }
        }
    }
    return Promise {seal in
        Alamofire.request(url)
            .validate()
            .response { response in
                guard let data = response.data, let image = UIImage(data: data) else {
                    let err = WNError.unknownResponseError
                    seal.reject(response.error ?? err)
                    return
                }
                seal.fulfill(image)
            }
        }.get { uiImage in
            guard let url = try? url.asURL().absoluteString,
                let wnCoverImage = WNCoverImage(uiImage: uiImage, url) else {
                throw WNError.decodingFailed
            }
            WNCache.save(wnCoverImage)
            print("Saved cover image for url \(url) to core data")
    }
}

