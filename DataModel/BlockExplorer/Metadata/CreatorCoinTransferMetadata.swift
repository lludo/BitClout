//
//  CreatorCoinTransferMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 4/27/21.
//

import Foundation

struct CreatorCoinTransferMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case creatorUsername = "CreatorUsername"
        case creatorCoinToTransferNanos = "CreatorCoinToTransferNanos"
    }
    
    let creatorUsername: String
    let creatorCoinToTransferNanos: Int
}
