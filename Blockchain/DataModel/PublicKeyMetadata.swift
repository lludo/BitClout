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
        case genesisBlockSeedBalance = "GenesisBlockSeedBalance"
        case mentionedPublicKeyBase58Check = "MentionedPublicKeyBase58Check"
        case parentPosterPublicKeyBase58Check = "ParentPosterPublicKeyBase58Check"
        case posterPublicKeyBase58Check = "PosterPublicKeyBase58Check"
        case profilePublicKeyBase58Check = "ProfilePublicKeyBase58Check"
        case receiverPublicKey = "ReceiverPublicKey"                            // Since block 19044
        case recipientPublicKeyBase58Check = "RecipientPublicKeyBase58Check"
        case recloutedPublicKeyBase58Check = "RecloutedPublicKeyBase58Check"    // Since block 13843
        case toPublicKeyBase58Check = "ToPublicKeyBase58Check"
    }
    
    // Depending on the txnType the following metadata is available.
    // - basicTransfer:     [basicTransferOutput]
    // - bitcoinExchange:   [burnPublicKey (BC1YLjWBf2qnDJmi8HZzzCPeXqy4dCKq95oqqzerAyW8MUTbuXTb1QT)]
    // - blockReward:       [genesisBlockSeedBalance] - no transaction metadata except genesis
    // - creatorCoin:       [basicTransferOutput, creatorPublicKey]
    // - follow:            [basicTransferOutput, rollowedPublicKeyBase58Check]
    // - like:              [basicTransferOutput, posterPublicKeyBase58Check]
    // - privateMessage:    [basicTransferOutput, recipientPublicKeyBase58Check]
    // - submitPost:        [basicTransferOutput, mentionedPublicKeyBase58Check? (mention), parentPosterPublicKeyBase58Check? (reply to)]
    // - swapIdentity:      [basicTransferOutput, fromPublicKeyBase58Check (source), toPublicKeyBase58Check (destination) (BC1YLg3oh6Boj8e2boCo1vQCYHLk1rjsHF6jthBdvSw79bixQvKK6Qa)]
    // - updateProfile:     [basicTransferOutput, profilePublicKeyBase58Check]
    
    let metadata: Metadata
    let publicKeyBase58Check: String
}
