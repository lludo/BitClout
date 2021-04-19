//
//  CreatorCoinAccountability.swift
//  Ttt
//
//  Created by Ludovic Landry on 4/10/21.
//

import Foundation

class CreatorCoinAccountability {
    
    struct CreatorCoinTransactionSummary {
        var bitCloutNanoIn: Int
        var creatorCoinNanoIn: Int
        
        var bitCloutReward: Int
        var creatorCoinNanoReward: Int
        
        var bitCloutLocked: Int
        var creatorCoinNanoLocked: Int
        
        var bitCloutNanoOut: Int
        var creatorCoinNanoOut: Int
    }
    
    private struct CreatorCoinTransactionItem {
        let creatorCoinNano: Int
        let bitCloutNano: Int
    }
    
    let account: Account
    private var transactions: [CreatorCoinTransactionItem] = []
    private var coinsOwnedNanoCount: Int = 0
    
    init(account: Account) {
        self.account = account
    }
    
    func buy(creatorCoinNano: Int, fromBitCloutNano bitCloutNano: Int) {
        guard creatorCoinNano != 0 else { return }
        guard creatorCoinNano > 0 else {
            fatalError("Cannot buy a negative amount!")
        }
        coinsOwnedNanoCount += creatorCoinNano
        transactions.append(CreatorCoinTransactionItem(creatorCoinNano: creatorCoinNano, bitCloutNano: bitCloutNano))
    }
    
    func founderReward(creatorCoinNano: Int, fromBitCloutNano bitCloutNano: Int) {
        guard creatorCoinNano != 0 else { return }
        guard creatorCoinNano > 0 else {
            fatalError("Cannot buy a negative amount!")
        }
        coinsOwnedNanoCount += creatorCoinNano
        transactions.append(CreatorCoinTransactionItem(creatorCoinNano: creatorCoinNano, bitCloutNano: bitCloutNano)) // TODO: Split in it's own category somehow
    }
    
    func sell(creatorCoinNano: Int, toBitCloutNano bitCloutNano: Int) {
        guard creatorCoinNano > 0 else {
            fatalError("Cannot sell a negative amount!")
        }
        guard creatorCoinNano <= coinsOwnedNanoCount else {
            fatalError("Cannot sell more coins thn owned!")
        }
        coinsOwnedNanoCount -= creatorCoinNano
        transactions.append(CreatorCoinTransactionItem(creatorCoinNano: -creatorCoinNano, bitCloutNano: bitCloutNano))
    }
    
    func summary(currentCoinPriceNano: Int? = nil) -> CreatorCoinTransactionSummary {
        return computeSummary(transactions: transactions, currentCoinPriceNano: currentCoinPriceNano)
    }
    
    // MARK: - Private
    
    private func computeSummary(transactions: [CreatorCoinTransactionItem], currentCoinPriceNano: Int? = nil) -> CreatorCoinTransactionSummary { // TODO: should use the amount of coins in circulation
        var bitCloutNanoIn: Int = 0
        var creatorCoinNanoIn: Int = 0
        
        var bitCloutNanoLocked: Int = 0
        var creatorCoinNanoLocked: Int = 0
        
        var bitCloutNanoOut: Int = 0
        var creatorCoinNanoOut: Int = 0
        
        for transaction in transactions {
            if transaction.creatorCoinNano > 0 { // Buy
                let bitCloutReinvested = min(bitCloutNanoOut, transaction.bitCloutNano)
                if bitCloutReinvested > 0 { // Reinvest from previous earnings (out)
                    bitCloutNanoOut -= bitCloutReinvested
                    if transaction.creatorCoinNano > creatorCoinNanoOut { // Rebuying more coins than previously sold
                        creatorCoinNanoIn += transaction.creatorCoinNano - creatorCoinNanoOut
                        creatorCoinNanoOut = 0
                    } else {
                        creatorCoinNanoOut -= transaction.creatorCoinNano
                    }
                    if bitCloutReinvested < transaction.bitCloutNano { // Reinvest + put new money in
                        let newBitCloutIn = transaction.bitCloutNano - bitCloutReinvested
                        bitCloutNanoIn += newBitCloutIn
                    }
                } else { // Put new money (in)
                    bitCloutNanoIn += transaction.bitCloutNano
                    creatorCoinNanoIn += transaction.creatorCoinNano
                }
                
                bitCloutNanoLocked += transaction.bitCloutNano
                creatorCoinNanoLocked += transaction.creatorCoinNano
            } else { // Sell
                bitCloutNanoLocked -= transaction.bitCloutNano
                creatorCoinNanoLocked += transaction.creatorCoinNano
                
                bitCloutNanoOut += transaction.bitCloutNano
                creatorCoinNanoOut -= transaction.creatorCoinNano
            }
        }
        
        if let currentCoinPriceNano = currentCoinPriceNano {
            bitCloutNanoLocked = currentValue(coinsNano:creatorCoinNanoLocked, currentCoinPriceNano: currentCoinPriceNano) // Override the last seen price with the current one
        }
        
        return CreatorCoinTransactionSummary(bitCloutNanoIn: bitCloutNanoIn,
                                             creatorCoinNanoIn: creatorCoinNanoIn,
                                             bitCloutReward: 0,
                                             creatorCoinNanoReward: 0,
                                             bitCloutLocked: bitCloutNanoLocked,
                                             creatorCoinNanoLocked: creatorCoinNanoLocked,
                                             bitCloutNanoOut: bitCloutNanoOut,
                                             creatorCoinNanoOut: creatorCoinNanoOut)
    }
    
    private func currentValue(coinsNano: Int, currentCoinPriceNano: Int) -> Int {
         return coinsNano * currentCoinPriceNano // TODO: this is wrong and should be computed using the bonding curve from the amount of coins in circulation
    }
}
