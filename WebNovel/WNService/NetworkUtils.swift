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

/// Initiates a html response request to the given URL with speficied parameters
/// - Returns: A promise wrapping the response html string.
func htmlRequestResponse(_ url: URLConvertible, method: HTTPMethod = .get, parameters: Parameters = [:]) -> Promise<String> {
    return Promise {seal in
        Alamofire.request(url, method: method, parameters: parameters)
            .validate()
            .response { response in
                guard let data = response.data, let htmlStr = String(data: data, encoding: .utf8) else {
                    let err = WNError.unknownResponseError
                    seal.reject(response.error ?? err)
                    return
                }
                seal.fulfill(htmlStr)
        }
    }
}

