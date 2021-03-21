//
//  TransactionMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/19/21.
//

import Foundation

class TransactionMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case affectedPublicKeys = "AffectedPublicKeys"
        case basicTransferTxindexMetadata = "BasicTransferTxindexMetadata"
        case bitcoinExchangeTxindexMetadata = "BitcoinExchangeTxindexMetadata"
        case blockHashHex = "BlockHashHex"
        case creatorCoinTxindexMetadata = "CreatorCoinTxindexMetadata"
        case followTxindexMetadata = "FollowTxindexMetadata"
        case likeTxindexMetadata = "LikeTxindexMetadata"
        case privateMessageTxindexMetadata = "PrivateMessageTxindexMetadata"
        case submitPostTxindexMetadata = "SubmitPostTxindexMetadata"
        case swapIdentityTxindexMetadata = "SwapIdentityTxindexMetadata"
        case transactorPublicKeyBase58Check = "TransactorPublicKeyBase58Check"
        case txnIndexInBlock = "TxnIndexInBlock"
        case txnType = "TxnType"
        case updateProfileTxindexMetadata = "UpdateProfileTxindexMetadata"
    }
    
    let affectedPublicKeys: [PublicKeyMetadata]
    let blockHashHex: String
    let transactorPublicKeyBase58Check: String
    let txnIndexInBlock: Int
    let txnType: Transaction.TransactionType
    
    // Depending on the txnType the following metadata is available.
    // - basicTransfer:     basicTransferTxindexMetadata
    // - bitcoinExchange:   bitcoinExchangeTxindexMetadata + basicTransferTxindexMetadata (fees)
    // - blockReward:       no transaction metadata
    // - creatorCoin:       creatorCoinTxindexMetadata + basicTransferTxindexMetadata (fees)
    // - follow:            followTxindexMetadata + basicTransferTxindexMetadata (fees)
    // - like:              likeTxindexMetadata + basicTransferTxindexMetadata (fees)
    // - privateMessage:    likeTxindexMetadata + basicTransferTxindexMetadata (fees)
    // - submitPost:        submitPostTxindexMetadata + basicTransferTxindexMetadata (fees)
    // - swapIdentity:      swapIdentityTxindexMetadata + basicTransferTxindexMetadata (fees)
    // - updateProfile:     updateProfileTxindexMetadata + basicTransferTxindexMetadata (fees)
    
    let basicTransferTxindexMetadata: BasicTransferMetadata?
    let bitcoinExchangeTxindexMetadata: BitcoinExchangeMetadata?
    let creatorCoinTxindexMetadata: CreatorCoinMetadata?
    let followTxindexMetadata: FollowMetadata?
    let likeTxindexMetadata: LikeMetadata?
    let privateMessageTxindexMetadata: PrivateMessageMetadata?
    let submitPostTxindexMetadata: SubmitPostMetadata?
    let swapIdentityTxindexMetadata: SwapIdentityMetadata?
    let updateProfileTxindexMetadata: UpdateProfileMetadata?
}
