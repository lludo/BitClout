//
//  Transaction.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/19/21.
//

import Foundation

struct Transaction: Codable {
    
    enum CodingKeys: String, CodingKey {
        case blockHashHex = "BlockHashHex"
        case inputs = "Inputs"
        case outputs = "Outputs"
        case rawTransactionHex = "RawTransactionHex"
        case signatureHex = "SignatureHex"
        case transactionIDBase58Check = "TransactionIDBase58Check"
        case transactionMetadata = "TransactionMetadata"
        case transactionType = "TransactionType"
    }
    
    enum TransactionType : String, Codable {
        case basicTransfer = "BASIC_TRANSFER"
        case bitcoinExchange = "BITCOIN_EXCHANGE"
        case blockReward = "BLOCK_REWARD"
        case creatorCoin = "CREATOR_COIN"
        case creatorCoinTransfer = "CREATOR_COIN_TRANSFER"
        case follow = "FOLLOW"
        case like = "LIKE"
        case privateMessage = "PRIVATE_MESSAGE"
        case submitPost = "SUBMIT_POST"
        case swapIdentity = "SWAP_IDENTITY"
        case updateBitcoinUsdExchangeRate = "UPDATE_BITCOIN_USD_EXCHANGE_RATE"
        case updateGlobalParams = "UPDATE_GLOBAL_PARAMS"    // Since block 19011
        case updateProfile = "UPDATE_PROFILE"
    }
    
    let blockHashHex: String
    let inputs: [TransactionInput]?
    let outputs: [TransactionOutput]?
    let rawTransactionHex: String // Contains submitted post, private message, etc.
    let signatureHex: String
    let transactionIDBase58Check: String
    let transactionMetadata: TransactionMetadata? // The genesis block has no metadata
    let transactionType: TransactionType
}

extension Transaction {
    
    static let unconfirmedBlockHashHex = "0000000000000000000000000000000000000000000000000000000000000000"
    
    var isConfirmed: Bool {
        return blockHashHex != Transaction.unconfirmedBlockHashHex
    }
}
