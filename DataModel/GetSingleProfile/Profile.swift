//
//  Profile.swift
//  BitClout
//
//  Created by Ludovic Landry on 5/1/21.
//

import Foundation
#if os(iOS)
import UIKit
#endif

typealias NoIdeaYet_SendPRIfYouFindOut_ThankYou = String

struct Profile: Codable {
    
    enum CodingKeys: String, CodingKey {
        case publicKeyBase58Check = "PublicKeyBase58Check"
        case username = "Username"
        case description = "Description"
        case profilePic = "ProfilePic"
        case isHidden = "IsHidden"
        case isReserved = "IsReserved"
        case isVerified = "IsVerified"
        case comments = "Comments"
        case posts = "Posts"
        case coinEntry = "CoinEntry"
        case coinPriceBitCloutNanos = "CoinPriceBitCloutNanos"
        case stakeMultipleBasisPoints = "StakeMultipleBasisPoints"
        case stakeEntryStats = "StakeEntryStats"
        case usersThatHODL = "usersThatHODL"
    }
    
    let publicKeyBase58Check: String
    let username: String
    let description: String
    let profilePic: String  // data:image/jpeg;base64
    let isHidden: Bool
    let isReserved: Bool
    let isVerified: Bool
    let comments: [NoIdeaYet_SendPRIfYouFindOut_ThankYou]?
    let posts: [NoIdeaYet_SendPRIfYouFindOut_ThankYou]?
    let coinEntry: CoinEntry
    let coinPriceBitCloutNanos: Int
    let stakeMultipleBasisPoints: Int   // Default is 12500 (125%)
    let stakeEntryStats: StakeEntryStats
    let usersThatHODL: [NoIdeaYet_SendPRIfYouFindOut_ThankYou]?
}

#if os(iOS)
extension Profile {
    
    /// Return the profile picture as image built from the base64 data
    var profileImage: UIImage {
        get {
            let profilePicData = NSData(base64Encoded: String(profilePic.dropFirst(23)), options: .ignoreUnknownCharacters)!
            return UIImage(data: profilePicData as Data)!
        }
    }
}
#endif
