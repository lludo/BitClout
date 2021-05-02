//
//  CreatorCoinMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct CreatorCoinMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case bitCloutToAddNanos = "BitCloutToAddNanos"
        case bitCloutToSellNanos = "BitCloutToSellNanos"
        case creatorCoinToSellNanos = "CreatorCoinToSellNanos"
        case operationType = "OperationType"
    }
    
    enum OperationType : String, Codable {
        case buy = "buy"
        case sell = "sell"
    }
    
    let bitCloutToAddNanos: Int
    let bitCloutToSellNanos: Int
    let creatorCoinToSellNanos: Int
    let operationType: OperationType
}
