//
//  FollowMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct FollowMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case isUnfollow = "IsUnfollow"
    }
    
    let isUnfollow: Bool
}
