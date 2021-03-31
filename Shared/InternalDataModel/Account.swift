//
//  Account.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/21/21.
//

import Foundation

class Account: Hashable {
    
    typealias MessagesAccounting = (sentCount: Int, receivedCount: Int)
    
    /// The accounting reason for the source or destination of the funds being added or removed.
    enum TransactionsAccounting {
        case bitcoinExchange
        case fees
        case genesis
        case transfer(String)
    }
    
    let publicKey: String
    let firstTransactionDate: Date
    let isGenesis: Bool
    
    private(set) var walletAmountNanos: Int = 0
    private(set) var profileMetadata: [UpdateProfileMetadata] = []
    
    var bitcoinPublicKey: String?
    private(set) var satoshisBurned: Int = 0
    
    private(set) var transactionsCount = 0
    private(set) var accountTransfertPublickKeys = Set<String>()
    
    var totalBitcloutNanoLocked: Int = 0        // The total bitclout locked for this account creator coin
    var ownCreatorCoins: [Account : Int] = [:]  // The creator coins owned with their amount (approximation, does not take the creator reward % into accoint yet)
    
    var hashValue: Int {
        get {
            return publicKey.hashValue
        }
    }
    
    init(publicKey: String, firstTransactionDate: Date, isGenesis: Bool) {
        self.firstTransactionDate = firstTransactionDate
        self.isGenesis = isGenesis
        self.publicKey = publicKey
    }
    
    func hash(into hasher: inout Hasher) {
        publicKey.hash(into: &hasher)
    }
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.publicKey == rhs.publicKey
    }
    
    func addToWallet(amountNanos: Int, from: TransactionsAccounting) {
        walletAmountNanos += amountNanos
        if case TransactionsAccounting.transfer(let fromPublickKey) = from {
            accountTransfertPublickKeys.insert(fromPublickKey)
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
            accountTransfertPublickKeys.insert(toPublickKey)
        }
    }
    
    func increaseTransactionsCount() {
        transactionsCount += 1
    }
    
    func addToSatoshisBurned(satoshis: Int) {
        satoshisBurned += satoshis
    }
    
    func addProfile(metadata: UpdateProfileMetadata) {
        profileMetadata.append(metadata)
    }
}
