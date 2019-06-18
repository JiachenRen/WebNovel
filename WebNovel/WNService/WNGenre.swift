//
//  WNGenre.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/18/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation

enum WNGenre: CaseIterable {
    case action
    case adult
    case adventure
    case comedy
    case drama
    case ecchi
    case fantasy
    case genderBender
    case harem
    case historical
    case horror
    case Josei
    case martialArts
    case mature
    case mecha
    case mystery
    case psychological
    case romance
    case schoolLife
    case sciFi
    case seinen
    case shoujo
    case shoujoAi
    case shounen
    case shounenAi
    case sliceOfLife
    case smut
    case sports
    case supernatural
    case tragedy
    case wuxia
    case xianxia
    case xuanhuan
    case yaoi
    case yuri
    
    /// e.g. "schoolLife" becomes "School Life"
    var camelCased: String {
        return "\(self)"
            .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .split(separator: " ")
            .map {
                // Uppercase first letter of each word
                $0.prefix(1).uppercased() + $0.lowercased().dropFirst()
            }.reduce("") {
                "\($0) \($1)"
        }
    }
    
    /// e.g. "genderBender" becomes "gender-bender"
    var dashSeparated: String {
        return camelCased.lowercased()
            .replacingOccurrences(of: " ", with: "-")
    }
}
