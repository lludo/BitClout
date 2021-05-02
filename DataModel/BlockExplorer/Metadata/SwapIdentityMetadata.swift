//
//  SwapIdentityMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct SwapIdentityMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case fromPublicKeyBase58Check = "FromPublicKeyBase58Check"
        case toPublicKeyBase58Check = "ToPublicKeyBase58Check"
    }
    
    let fromPublicKeyBase58Check: String
    let toPublicKeyBase58Check: String
}
