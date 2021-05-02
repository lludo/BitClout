//
//  Block.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/19/21.
//

import Foundation

struct Block: Codable {
    
    enum CodingKeys: String, CodingKey {
        case balanceNanos = "BalanceNanos"
        case error = "Error"
        case header = "Header"
        case transactions = "Transactions"
    }
    
    let balanceNanos: Int?
    let error: String
    let header: BlockHeader?
    let transactions: [Transaction]?
}
