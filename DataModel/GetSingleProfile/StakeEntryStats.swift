//
//  StakeEntryStats.swift
//  BitClout
//
//  Created by Ludovic Landry on 5/1/21.
//

import Foundation

struct StakeEntryStats: Codable {
    
    enum CodingKeys: String, CodingKey {
        case totalStakeNanos = "TotalStakeNanos"
        case totalStakeOwedNanos = "TotalStakeOwedNanos"
        case totalCreatorEarningsNanos = "TotalCreatorEarningsNanos"
        case totalFeesBurnedNanos = "TotalFeesBurnedNanos"
        case totalPostStakeNanos = "TotalPostStakeNanos"
    }
    
    let totalStakeNanos: Int
    let totalStakeOwedNanos: Int
    let totalCreatorEarningsNanos: Int
    let totalFeesBurnedNanos: Int
    let totalPostStakeNanos: Int
}
