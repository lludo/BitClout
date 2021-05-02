//
//  PrivateMessageMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct PrivateMessageMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case timestampNanos = "TimestampNanos"
    }
    
    let timestampNanos: Int
}
