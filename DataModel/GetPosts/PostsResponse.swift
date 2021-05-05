//
//  PostsResponse.swift
//  BitClout
//
//  Created by Ludovic Landry on 5/2/21.
//

import Foundation

struct PostsResponse: Codable {
    
    enum CodingKeys: String, CodingKey {
        case posts = "Posts"
        case lastPostHashHex = "LastPostHashHex"
        case error = "error"
    }
    
    let posts: [Post]?
    let lastPostHashHex: String?
    let error: String?
}
