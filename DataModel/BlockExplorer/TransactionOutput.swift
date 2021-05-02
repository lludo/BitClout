//
//  TransactionOutput.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/19/21.
//

import Foundation

class TransactionOutput: Codable {
    
    enum CodingKeys: String, CodingKey {
        case amountNanos = "AmountNanos"
        case publicKeyBase58Check = "PublicKeyBase58Check"
    }
    
    let amountNanos: Int
    let publicKeyBase58Check: String
}
