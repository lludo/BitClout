//
//  PublicKeyMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct PublicKeyMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case metadata = "Metadata"
        case publicKeyBase58Check = "PublicKeyBase58Check"
    }
    
    enum Metadata : String, Codable {
        case basicTransferOutput = "BasicTransferOutput"
        case burnPublicKey = "BurnPublicKey"
        case creatorPublicKey = "CreatorPublicKey"
        case followedPublicKeyBase58Check = "FollowedPublicKeyBase58Check"
        case fromPublicKeyBase58Check = "FromPublicKeyBase58Check"
        case mentionedPublicKeyBase58Check = "MentionedPublicKeyBase58Check"
        case parentPosterPublicKeyBase58Check = "ParentPosterPublicKeyBase58Check"
        case posterPublicKeyBase58Check = "PosterPublicKeyBase58Check"
        case profilePublicKeyBase58Check = "ProfilePublicKeyBase58Check"
        case recipientPublicKeyBase58Check = "RecipientPublicKeyBase58Check"
        case toPublicKeyBase58Check = "ToPublicKeyBase58Check"
    }
    
    // Depending on the txnType the following metadata is available.
    // - basicTransfer:     [basicTransferOutput, basicTransferOutput]
    // - bitcoinExchange:   [burnPublicKey]
    // - blockReward:       no transaction metadata
    // - creatorCoin:       [basicTransferOutput, creatorPublicKey]
    // - follow:            [basicTransferOutput, rollowedPublicKeyBase58Check]
    // - like:              [basicTransferOutput, posterPublicKeyBase58Check]
    // - privateMessage:    [basicTransferOutput, recipientPublicKeyBase58Check]
    // - submitPost:        [basicTransferOutput, mentionedPublicKeyBase58Check? (mention), parentPosterPublicKeyBase58Check? (reply to)]
    // - swapIdentity:      [basicTransferOutput, fromPublicKeyBase58Check (source), toPublicKeyBase58Check (destination)]
    // - updateProfile:     [basicTransferOutput, profilePublicKeyBase58Check]
    
    let metadata: Metadata
    let publicKeyBase58Check: String
}
