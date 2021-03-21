//
//  BasicTransferMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct BasicTransferMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case feeNanos = "FeeNanos"
        case totalInputNanos = "TotalInputNanos"
        case totalOutputNanos = "TotalOutputNanos"
        case utxoOpsDump = "UtxoOpsDump"
    }
    
    let feeNanos: Int
    let totalInputNanos: Int
    let totalOutputNanos: Int
    let utxoOpsDump: String
}
