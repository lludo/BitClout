//
//  SubmitPostMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct SubmitPostMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case parentPostHashHex = "ParentPostHashHex"
        case postHashBeingModifiedHex = "PostHashBeingModifiedHex"
    }
    
    let parentPostHashHex: String
    let postHashBeingModifiedHex: String
}
