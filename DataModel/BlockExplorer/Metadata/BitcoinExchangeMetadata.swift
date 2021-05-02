//
//  BitcoinExchangeMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct BitcoinExchangeMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case bitcoinSpendAddress = "BitcoinSpendAddress"
        case bitcoinTxnHash = "BitcoinTxnHash"
        case nanosCreated = "NanosCreated"
        case satoshisBurned = "SatoshisBurned"
        case totalNanosPurchasedAfter = "TotalNanosPurchasedAfter"
        case totalNanosPurchasedBefore = "TotalNanosPurchasedBefore"
    }
    
    let bitcoinSpendAddress: String
    let bitcoinTxnHash: String
    let nanosCreated: Int
    let satoshisBurned: Int
    let totalNanosPurchasedAfter: Int
    let totalNanosPurchasedBefore: Int
}
