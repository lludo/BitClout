//
//  UpdateProfileMetadata.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

struct UpdateProfileMetadata: Codable {
    
    enum CodingKeys: String, CodingKey {
        case isHidden = "IsHidden"
        case newCreatorBasisPoints = "NewCreatorBasisPoints"
        case newDescription = "NewDescription"
        case newProfilePic = "NewProfilePic"
        case newStakeMultipleBasisPoints = "NewStakeMultipleBasisPoints"
        case newUsername = "NewUsername"
        case profilePublicKeyBase58Check = "ProfilePublicKeyBase58Check"
    }
    
    let isHidden: Bool
    let newCreatorBasisPoints: Int
    let newDescription: String
    let newProfilePic: String
    let newStakeMultipleBasisPoints: Int
    let newUsername: String
    let profilePublicKeyBase58Check: String
}
