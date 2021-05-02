//
//  Account.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/21/21.
//

import Foundation
#if os(iOS)
import UIKit
#endif

class Account: Hashable {
    
    typealias CreatorCoinsAccounting = (receivedNanoCoins: Int, creatorRewardNanoCoins: Int, totalPaidNanoCoins: Int)
    typealias MessagesAccounting = (sentCount: Int, receivedCount: Int)
    
    /// The accounting reason for the source or destination of the funds being added or removed.
    enum TransactionsAccounting {
        case bitcoinExchange
        case fees
        case genesis
        case transfer(String)
        case creatorCoins(String)
    }
    
    enum CreatorCoinsSource {
        case bought(Int)
        case founderReward(Int)
    }
    
    /// The currently used public key (latest one)
    var publicKey: String {
        get {
            return publicKeys.last!
        }
    }
    private(set) var publicKeys: [String]
    
    let firstTransactionDate: Date
    let isGenesis: Bool
    
    private(set) var walletAmountNanos: Int = 0
    private(set) var profileMetadata: [UpdateProfileMetadata] = []
    
    var bitcoinPublicKey: String?
    private(set) var satoshisBurned: Int = 0
    
    private(set) var transactionsCount = 0
    
    var hashValue: Int {
        get {
            return publicKey.first!.hashValue // The fist public key identify the account, this will never change
        }
    }
    
    init(publicKey: String, firstTransactionDate: Date, isGenesis: Bool) {
        self.firstTransactionDate = firstTransactionDate
        self.isGenesis = isGenesis
        self.publicKeys = [publicKey]
    }
    
    func hash(into hasher: inout Hasher) {
        publicKeys.first!.hash(into: &hasher)
    }
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.publicKeys.first! == rhs.publicKeys.first!
    }
    
    func increaseTransactionsCount() {
        transactionsCount += 1
    }
    
    // MARK: - Transactions
    
    private(set) var transfertToPublickKeys = Set<String>()
    private(set) var transfertFromPublickKeys = Set<String>()
    
    func addToWallet(amountNanos: Int, from: TransactionsAccounting) {
        walletAmountNanos += amountNanos
        if case TransactionsAccounting.transfer(let fromPublickKey) = from {
            transfertFromPublickKeys.insert(fromPublickKey)
        }
    }
    
    func removeFromWallet(amountNanos: Int, to: TransactionsAccounting) {
//        guard amountNanos <= walletAmountNanos else {
//            print(">>> Error spend: " + (profileMetadata.last?.newUsername ?? ""))
//            return
//        }
        walletAmountNanos -= amountNanos
        
        // Should not happen, but here we are... (commented previous guard)
        if walletAmountNanos < 0 {
            walletAmountNanos = 0
        }
        
        if case TransactionsAccounting.transfer(let toPublickKey) = to {
            transfertToPublickKeys.insert(toPublickKey)
        }
    }
    
    func addToSatoshisBurned(satoshis: Int) {
        satoshisBurned += satoshis
    }
    
    // MARK: - Profile & Identity
    
    /// Filter duplicates and empty values, keep order. Last one is the current one.
    var usernames: [String] {
        get {
            var uniqueUsernames = Set<String>()
            var orderedUniqueUsernames: [String] = []
            for profile in profileMetadata.reversed() {
                if !profile.newUsername.isEmpty && !uniqueUsernames.contains(profile.newUsername) {
                    uniqueUsernames.insert(profile.newUsername)
                    orderedUniqueUsernames.append(profile.newUsername)
                }
            }
            return orderedUniqueUsernames.reversed()
        }
    }
    
    /// Return only the username from the latest update.
    var currentUsername: String? {
        get {
            for profile in profileMetadata.reversed() {
                if !profile.newUsername.isEmpty {
                    return profile.newUsername
                }
            }
            return nil
        }
    }
    
    /// Return only the username from the latest update.
    var currentDescription: String? {
        get {
            for profile in profileMetadata.reversed() {
                if !profile.newDescription.isEmpty {
                    return profile.newDescription
                }
            }
            return nil
        }
    }
    
    #if os(iOS)
    /// Return only the picture from the latest update.
    var currentProfilePic: UIImage? {
        get {
            for profile in profileMetadata.reversed() {
                if !profile.newProfilePic.isEmpty {
                    let profilePicData = NSData(base64Encoded: String(profile.newProfilePic.dropFirst(23)), options: .ignoreUnknownCharacters)!
                    return UIImage(data: profilePicData as Data)!
                }
            }
            return nil
        }
    }
    #endif
    
    func swapToNewPublicKey(_ publicKey: String) {
        publicKeys.append(publicKey)
        
        //TODO: There is probably more to do here...
    }
    
    func addProfile(metadata: UpdateProfileMetadata) {
        profileMetadata.append(metadata)
    }
    
    // MARK: - Messages
    
    private(set) var messagePublickKeys = Dictionary<Account, MessagesAccounting>()
    
    func addSentMessage(to account: Account) {
        if messagePublickKeys[account] == nil {
            messagePublickKeys[account] = (sentCount: 1, receivedCount: 0)
        } else {
            messagePublickKeys[account]!.sentCount += 1
        }
    }
    
    func addReceivedMessage(from account: Account) {
        if messagePublickKeys[account] == nil {
            messagePublickKeys[account] = (sentCount: 0, receivedCount: 1)
        } else {
            messagePublickKeys[account]!.receivedCount += 1
        }
    }
    
    // MARK: - Creator Coins
    
    /// The total bitclout currently locked for this account creator coin
    private(set) var currentBitcloutNanoLockedInCreatorCoins: Int = 0 {
        didSet {
            maxReachedBitcloutNanoLockedInCreatorCoins = max(currentBitcloutNanoLockedInCreatorCoins, maxReachedBitcloutNanoLockedInCreatorCoins)
        }
    }
    
    /// The max locked for this account creator coin (keep track to know the creator reward % already paid)
    private(set) var maxReachedBitcloutNanoLockedInCreatorCoins: Int = 0
    
    var creatorBasisPoints: Int {
        get {
            return profileMetadata.last?.newCreatorBasisPoints ?? 0
        }
    }
    
    /// The creator coins (of self or other accounts) owned by bhis amount
    private(set) var ownedCreatorCoinsNano: [Account : Int] = [:]
    
    lazy var accountabilityCreatorCoin: [Account : CreatorCoinAccountability] = [:]
    
    /// Used when somebody buys coins from this account buy price in bitclout, returns the amount of coins bought in cc split between buyer and creator
    /// If buying own coins, if goes to the received buyer coins and the creator reward is ignored  (as the creator is the buyer - they are paying for it...)
    func lockBitcloutToBuyCreatorCoins(bitcloutAmountNanos: Int, fromSelf: Bool) -> CreatorCoinsAccounting {
        let coinsNanoBought = Tools.creatorCoinsNanoBaught(bitCloutNanoAmount: bitcloutAmountNanos, totalBitcloutNanoLocked: currentBitcloutNanoLockedInCreatorCoins)
        if fromSelf {
            currentBitcloutNanoLockedInCreatorCoins += bitcloutAmountNanos
            return (receivedNanoCoins: coinsNanoBought, creatorRewardNanoCoins: 0, totalPaidNanoCoins: coinsNanoBought)
        } else {
            let maxReachedSupplyCreatorCoinsNano = Tools.creatorCoinsNanoInCirculation(totalBitcloutNanoLocked: maxReachedBitcloutNanoLockedInCreatorCoins)
            let currentSupplyCreatorCoinsNano = Tools.creatorCoinsNanoInCirculation(totalBitcloutNanoLocked: currentBitcloutNanoLockedInCreatorCoins)
            let creatorCoinsNanoBoughtTaxFree = min(coinsNanoBought, maxReachedSupplyCreatorCoinsNano - currentSupplyCreatorCoinsNano)
            currentBitcloutNanoLockedInCreatorCoins += bitcloutAmountNanos
            
            let creatorRewardNanoCoins = Int(Double(coinsNanoBought - creatorCoinsNanoBoughtTaxFree) / 10_000.0 * Double(creatorBasisPoints))
            guard creatorCoinsNanoBoughtTaxFree >= 0, creatorRewardNanoCoins >= 0 else {
                fatalError("Cannot generate a negative amount of coins")
            }
            return (receivedNanoCoins: coinsNanoBought - creatorRewardNanoCoins, creatorRewardNanoCoins: creatorRewardNanoCoins, totalPaidNanoCoins: coinsNanoBought)
        }
    }
    
    /// Used when sells coins from this account sell price in cc, returns the amount of coins sold in bitclout
    func unlockBitcloutBySellingCreatorCoins(creatorCoinNanoAmount: Int) -> Int {
        let bitcloutNanoSold = Tools.creatorCoinsNanoSold(creatorCoinNanoAmount: creatorCoinNanoAmount,
                                                          totalBitcloutNanoLocked: currentBitcloutNanoLockedInCreatorCoins)
        guard bitcloutNanoSold <= currentBitcloutNanoLockedInCreatorCoins else {
            fatalError("Cannot sell more coins than exist")
        }
        currentBitcloutNanoLockedInCreatorCoins -= bitcloutNanoSold
        return bitcloutNanoSold
    }
    
    func addToOwnedCreatorCoins(from account: Account, coinsAmountNanos: Int, accounting: CreatorCoinsSource) {
        guard coinsAmountNanos >= 0 else {
            fatalError("Cannot add a negative amount of coins")
        }
        if ownedCreatorCoinsNano[account] == nil {
            ownedCreatorCoinsNano[account] = coinsAmountNanos
            accountabilityCreatorCoin[account] = CreatorCoinAccountability(account: account)
        } else {
            ownedCreatorCoinsNano[account]! += coinsAmountNanos
        }
        switch accounting {
            case .bought(let bitCloutNano): accountabilityCreatorCoin[account]!.buy(creatorCoinNano: coinsAmountNanos, fromBitCloutNano: bitCloutNano)
            case .founderReward(let bitCloutNano): accountabilityCreatorCoin[account]!.buy(creatorCoinNano: coinsAmountNanos, fromBitCloutNano: bitCloutNano)
        }
    }
    
    func removeFromOwnedCreatorCoins(from account: Account, coinsAmountNanos: Int, accounting: Int) {
        if coinsAmountNanos == 0 { return }
        guard let ownedCreatorCoinsNanoForAccount = ownedCreatorCoinsNano[account], ownedCreatorCoinsNanoForAccount >= coinsAmountNanos else {
            fatalError("Cannot sell more coins than owned")
        }
        ownedCreatorCoinsNano[account]! -= coinsAmountNanos
        accountabilityCreatorCoin[account]!.sell(creatorCoinNano: coinsAmountNanos, toBitCloutNano: accounting)
    }
    
    // MARK: - Creator Coins
    
    var followers = Set<Account>()
    var following = Set<Account>()
}

extension Account: CustomDebugStringConvertible {
    var debugDescription: String {
        "<Account username: \(currentUsername ?? "?"), publicKey:\(publicKey)>"
    }
}
