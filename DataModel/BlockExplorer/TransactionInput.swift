//
//  TransactionInput.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/19/21.
//

import Foundation

class TransactionInput: Codable {
    
    enum CodingKeys: String, CodingKey {
        case index = "Index"
        case transactionIDBase58Check = "TransactionIDBase58Check"
    }
    
    let index: Int
    let transactionIDBase58Check: String
}
