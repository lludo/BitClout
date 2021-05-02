//
//  SingleProfileResponse.swift
//  BitClout
//
//  Created by Ludovic Landry on 5/1/21.
//

import Foundation

typealias NoIdeaYet_SendPRIfYouFindOut_ThankYou = String

struct SingleProfileResponse: Codable {
    
    enum CodingKeys: String, CodingKey {
        case profile = "Profile"
    }
    
    let profile: Profile
}
