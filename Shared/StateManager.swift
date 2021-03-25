//
//  StateManager.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/23/21.
//

import Foundation

class StateManager {
    
    private let queryManager = QueryManager()
    private let storage = StorageClient()
    private let userDefaults = UserDefaults.standard
    
    private let lastAvailableBlockHeightKey = "lastAvailableBlockHeight"
    
    var lastAvailableBlockHeight: Int
    
    init() {
        lastAvailableBlockHeight = userDefaults.integer(forKey: lastAvailableBlockHeightKey)
    }
    
    // Refresh blocks and validate them.
    func refresh(completion: @escaping ((Error?) -> Void)) {
        queryManager.fetchBlocks(fromHeight: lastAvailableBlockHeight) { result in
            switch result {
                case .success(let transactionCount):
                    print(">>>>>> Success! (\(transactionCount) transactions")
                    completion(nil)
                case .failure(let error):
                    if case BitCloutError.captchaFoundError(let htmlContent) = error {
                        print(">>>>>> Error: \(htmlContent)")
                        completion(error)
                    } else if case BitCloutError.responseBlockError(let message) = error {
                        if message.contains("must be >= 0 and <= height of best block chain") {
                            print(">>>>>> Done! (Reached the last available block)")
                            if let range = message.range(of: "block chain tip "), let tipBlockHeight = Int(message[range.upperBound...]) {
                                self.lastAvailableBlockHeight = tipBlockHeight
                                self.userDefaults.set(tipBlockHeight, forKey: self.lastAvailableBlockHeightKey)
                            }
                            completion(nil)
                        } else {
                            print(">>>>>> Error in block: \(error)")
                            completion(error)
                        }
                    } else {
                        print(">>>>>> Error: \(error)")
                        completion(error)
                    }
            }
        }
    }
    
    func printAllTransactionForCreatorCoins(privateKey: String) {
        print(">>>>>> Looking for all buy/sell transactions, this can take some time...")
        var totalBitcloutNanoLocked: Int = 0
        blockIteration: for blockHeight in 0...self.lastAvailableBlockHeight {
            let result = storage.readBlock(height: blockHeight)
            switch result {
                case .success(let block):
                    guard let transactions = block.transactions else { continue }
                    for transaction in transactions {
                        if transaction.transactionType == .creatorCoin {
                            guard let transactionMetadata = transaction.transactionMetadata else {
                                print(">>>>>> Failed to get metadata for transaction: \(transaction)")
                                break blockIteration
                            }
                            guard let metadata = transactionMetadata.creatorCoinTxindexMetadata else {
                                print(">>>>>> Failed to get metadata for creator coin transaction: \(transaction)")
                                break blockIteration
                            }
                            var creatorKeyBeingTransacted: String? = nil
                            for affectedPublicKey in transactionMetadata.affectedPublicKeys {
                                if affectedPublicKey.metadata == .creatorPublicKey {
                                    creatorKeyBeingTransacted = affectedPublicKey.publicKeyBase58Check
                                    break
                                }
                            }
                            guard let creatorKey = creatorKeyBeingTransacted else {
                                print(">>>>>> Failed to find creator key in transaction: \(transaction)")
                                break blockIteration
                            }
                            guard creatorKey == privateKey else { continue } // Ignore the other ones
                            switch metadata.operationType {
                                case .buy:
                                    let coinsNanoBought = Tools.creatorCoinsNanoBaught(bitCloutNanoAmount: metadata.bitCloutToSellNanos,
                                                                                       totalBitcloutNanoLocked: totalBitcloutNanoLocked)
                                    totalBitcloutNanoLocked += metadata.bitCloutToSellNanos
                                    print("\(blockHeight),\((Double(coinsNanoBought) / Tools.nanoToUnit).toString(decimal: 9))")
                                case .sell:
                                    let bitcloutNanoSold = Tools.creatorCoinsNanoSold(creatorCoinNanoAmount: metadata.creatorCoinToSellNanos,
                                                                                      totalBitcloutNanoLocked: totalBitcloutNanoLocked)
                                    totalBitcloutNanoLocked -= bitcloutNanoSold
                                    print("\(blockHeight),-\((Double(metadata.creatorCoinToSellNanos) / Tools.nanoToUnit).toString(decimal: 9))")
                            }
                        }
                    }
                case .failure(let error):
                    print(">>>>>> Failed to read with error: \(error)")
                    break blockIteration
            }
        }
        let totalCoinsNanoInCirculation = Tools.creatorCoinsNanoInCirculation(totalBitcloutNanoLocked: totalBitcloutNanoLocked)
        print("> ##### = {\tcoins: \(Double(totalCoinsNanoInCirculation) / Tools.nanoToUnit),\tbitclout: \(Double(totalBitcloutNanoLocked) / Tools.nanoToUnit) }")
        print("> Done!")
    }
}
