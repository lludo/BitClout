//
//  LikeMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct LikeMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case isUnlike = "IsUnlike"
        case postHashHex = "PostHashHex"
    }
    
    let isUnlike: Bool
    let postHashHex: String
}
