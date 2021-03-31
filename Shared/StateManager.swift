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
                                print(">>>>>> Failed to get metadata at block #\(blockHeight) for transaction: \(transaction)")
                                continue blockIteration
                            }
                            guard let metadata = transactionMetadata.creatorCoinTxindexMetadata else {
                                print(">>>>>> Failed to get metadata for creator coin at block #\(blockHeight) for transaction: \(transaction)")
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
                                print(">>>>>> Failed to find creator key at block #\(blockHeight) in transaction: \(transaction)")
                                break blockIteration
                            }
                            guard creatorKey == privateKey else { continue } // Ignore the other ones
                            switch metadata.operationType {
                                case .buy:
                                    let coinsNanoBought = Tools.creatorCoinsNanoBaught(bitCloutNanoAmount: metadata.bitCloutToSellNanos,
                                                                                       totalBitcloutNanoLocked: totalBitcloutNanoLocked)
                                    totalBitcloutNanoLocked += metadata.bitCloutToSellNanos
                                    print("\(blockHeight),\((Double(coinsNanoBought) / Tools.nanoToUnit).toString(decimal: 9)),\(transactionMetadata.transactorPublicKeyBase58Check)")
                                case .sell:
                                    let bitcloutNanoSold = Tools.creatorCoinsNanoSold(creatorCoinNanoAmount: metadata.creatorCoinToSellNanos,
                                                                                      totalBitcloutNanoLocked: totalBitcloutNanoLocked)
                                    totalBitcloutNanoLocked -= bitcloutNanoSold
                                    print("\(blockHeight),-\((Double(metadata.creatorCoinToSellNanos) / Tools.nanoToUnit).toString(decimal: 9)),\(transactionMetadata.transactorPublicKeyBase58Check)")
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
    
    
    func parseAllAccounts() -> [Account] {
        let storage = StorageClient()
        var accountsByPublicKey: [String : Account] = [:]
        blockIteration: for blockHeight in 0...self.lastAvailableBlockHeight {
            let result = storage.readBlock(height: blockHeight)
            switch result {
                case .success(let block):
                    guard block.error.isEmpty else {
                        print("Error: block #\(blockHeight) returned error: \(block.error)")
                        continue
                    }
                    guard let transactions = block.transactions else {
                        print("Error: block #\(blockHeight) should have transactions, but none found!")
                        continue
                    }
                    for transaction in transactions {
                        switch transaction.transactionType {
                            case .basicTransfer:
                                guard let transactionMetadata = transaction.transactionMetadata else {
                                    print("Error: updateProfile block type should have transaction.transactionMetadata")
                                    continue
                                }
                                guard let basicTransferMetadata = transactionMetadata.basicTransferTxindexMetadata else {
                                    print("Error: updateProfile block type should have transaction.transactionMetadata.basicTransferTxindexMetadata")
                                    continue
                                }
                                guard transactionMetadata.transactorPublicKeyBase58Check != "BC1YLfjzDi33hEUC6MeiGPJuYD9xnJN9rf6TVBRZVZan3CE9y3111NB" else { continue }
                                var senderAccount: Account? = nil
                                var receiverAccount: Account? = nil
                                for affectedPublicKey in transactionMetadata.affectedPublicKeys {
                                    if affectedPublicKey.publicKeyBase58Check == transactionMetadata.transactorPublicKeyBase58Check {
                                        if senderAccount != nil { assert(true, "Error: cannot prepare the sender address more than once") }
                                        senderAccount = findOrCreateAccount(publicKey: affectedPublicKey.publicKeyBase58Check, block: block,
                                                                            from: &accountsByPublicKey)
                                    } else {
                                        if receiverAccount != nil { assert(true, "Error: cannot prepare the receiver address more than once") }
                                        receiverAccount = findOrCreateAccount(publicKey: affectedPublicKey.publicKeyBase58Check, block: block,
                                                                              from: &accountsByPublicKey)
                                    }
                                }
                                if senderAccount == nil { // Sender not specified, not sure why, then we assume transactor is the sender.
                                    senderAccount = findOrCreateAccount(publicKey: transactionMetadata.transactorPublicKeyBase58Check, block: block,
                                                                        from: &accountsByPublicKey)
                                }
                                guard let sender = senderAccount else {
                                    assert(true, "Error: did not find sender in the transaction, how is even this possible...")
                                    continue
                                }
                                if let receiver = receiverAccount {
                                    sender.removeFromWallet(amountNanos: basicTransferMetadata.totalOutputNanos, to: .transfer(receiver.publicKey))
                                    sender.removeFromWallet(amountNanos: basicTransferMetadata.feeNanos, to: .fees)
                                    sender.increaseTransactionsCount()
                                    receiver.addToWallet(amountNanos: basicTransferMetadata.totalInputNanos, from: .transfer(sender.publicKey))
                                    receiver.increaseTransactionsCount()
                                } else { // Receiver not specified, because we are sending to ourself? Assume transactor is
                                    sender.removeFromWallet(amountNanos: basicTransferMetadata.feeNanos, to: .fees)
                                    sender.increaseTransactionsCount()
                                }
                            case .bitcoinExchange:
                                guard let transactionMetadata = transaction.transactionMetadata else {
                                    print("Error: bitcoinExchange block type should have transaction.transactionMetadata")
                                    continue
                                }
                                guard let basicTransferMetadata = transactionMetadata.basicTransferTxindexMetadata else {
                                    print("Error: bitcoinExchange block type should have transaction.transactionMetadata.basicTransferTxindexMetadata")
                                    continue
                                }
                                guard let bitcoinExchangeMetadata = transactionMetadata.bitcoinExchangeTxindexMetadata else {
                                    print("Error: bitcoinExchange block type should have transaction.transactionMetadata.bitcoinExchangeTxindexMetadata")
                                    continue
                                }
                                let account = findOrCreateAccount(publicKey: transactionMetadata.transactorPublicKeyBase58Check, block: block,
                                                                  from: &accountsByPublicKey)
                                account.bitcoinPublicKey = bitcoinExchangeMetadata.bitcoinSpendAddress
                                account.addToSatoshisBurned(satoshis: bitcoinExchangeMetadata.satoshisBurned)
                                account.addToWallet(amountNanos: basicTransferMetadata.totalOutputNanos, from: .bitcoinExchange)
                                account.increaseTransactionsCount()
                            case .blockReward:
                                guard let outputs = transaction.outputs else {
                                    print("Error: .blockReward block type should have at least one object in transaction.outputs.")
                                    break
                                }
                                let isGenesisBlock = blockHeight == 0
                                if isGenesisBlock {
                                    for output in outputs {
                                        let outputAccount = findOrCreateAccount(publicKey: output.publicKeyBase58Check, block: block,
                                                                                from: &accountsByPublicKey, isGenesis: true)
                                        outputAccount.addToWallet(amountNanos: output.amountNanos, from: .genesis)
                                        outputAccount.increaseTransactionsCount()
                                    }
                                } else {
                                    guard outputs.count == 1, let output = outputs.first else {
                                        print("Error: .blockReward block type should have only one object in transaction.outputs (except for genesis block).")
                                        continue
                                    }
                                    let outputAccount = findOrCreateAccount(publicKey: output.publicKeyBase58Check, block: block, from: &accountsByPublicKey)
                                    outputAccount.addToWallet(amountNanos: output.amountNanos, from: .fees)
                                    outputAccount.increaseTransactionsCount()
                                }
                            case .creatorCoin:
                                // TODO: Implement, you can help?
                                break
                            case .follow:
                                // TODO: Implement, you can help?
                                break
                            case .like:
                                // TODO: Implement, you can help?
                                break
                            case .privateMessage:
                                // TODO: Implement, you can help?
                                break
                            case .submitPost:
                                // TODO: Implement, you can help?
                                break
                            case .swapIdentity:
                                // TODO: Implement, you can help?
                                break
                            case .updateBitcoinUsdExchangeRate:
                                // TODO: Implement, you can help?
                                break
                            case .updateProfile:
                                // TODO: Implement, you can help?
                        }
                    }
                case .failure(let error):
                    print(">>>>>> Failed to read with error: \(error)")
                    break blockIteration
            }
        }
        print(">>>>>> accounts found: \(accountsByPublicKey.count)")
        print("> Done!")
        
        return Array(accountsByPublicKey.values)
    }
    
    // mark: - Private
    
    func findOrCreateAccount(publicKey: String, block: Block, from accountsByPublicKey: inout [String : Account], isGenesis: Bool = false) -> Account {
        if let account = accountsByPublicKey[publicKey] {
            return account
        } else {
            let blockDate = Date(timeIntervalSince1970: Double(block.header!.tstampSecs))
            let account = Account(publicKey: publicKey, firstTransactionDate: blockDate, isGenesis: isGenesis)
            accountsByPublicKey[publicKey] = account
            return account
        }
    }
}
