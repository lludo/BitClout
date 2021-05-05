//
//  Post.swift
//  BitClout
//
//  Created by Ludovic Landry on 5/2/21.
//

import Foundation

struct Post: Codable {
    
    enum CodingKeys: String, CodingKey {
        case posterPublicKeyBase58Check = "PosterPublicKeyBase58Check"
        case body = "Body"
        case stakeEntryStats = "StakeEntryStats"
        
        // TODO: imcomplete
    }
    
    let posterPublicKeyBase58Check: String
    let body: String
    let stakeEntryStats: StakeEntryStats
    
    // TODO: imcomplete
}
