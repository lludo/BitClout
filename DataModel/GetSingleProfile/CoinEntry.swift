//
//  CoinEntry.swift
//  BitClout
//
//  Created by Ludovic Landry on 5/1/21.
//

import Foundation

struct CoinEntry: Codable {
    
    enum CodingKeys: String, CodingKey {
        case creatorBasisPoints = "CreatorBasisPoints"
        case bitCloutLockedNanos = "BitCloutLockedNanos"
        case numberOfHolders = "NumberOfHolders"
        case coinsInCirculationNanos = "CoinsInCirculationNanos"
        case coinWatermarkNanos = "CoinWatermarkNanos"
    }
    
    let creatorBasisPoints: Int // Default is 1000 (10%)
    let bitCloutLockedNanos: Int
    let numberOfHolders: Int
    let coinsInCirculationNanos: Int
    let coinWatermarkNanos: Int
}
