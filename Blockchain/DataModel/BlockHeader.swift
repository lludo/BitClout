//
//  BlockHeader.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct BlockHeader: Codable {
    
    enum CodingKeys: String, CodingKey {
        case blockHashHex = "BlockHashHex"
        case version = "Version"
        case prevBlockHashHex = "PrevBlockHashHex"
        case transactionMerkleRootHex = "TransactionMerkleRootHex"
        case tstampSecs = "TstampSecs"
        case height = "Height"
        case nonce = "Nonce"
    }
    
    let blockHashHex: String
    let version: Int
    let prevBlockHashHex: String
    let transactionMerkleRootHex: String
    let tstampSecs: Int
    let height: Int
    let nonce: Int
}
