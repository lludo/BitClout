//
//  StateManager.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/23/21.
//

import Foundation

class StateManager {
    
    enum StateManagerErrors: Error {
        case transactionMetadataMissing
        case basicTransferTransactionMetadataMissing
        case basicTransferNoSender
        case bitcoinExchangeTransactionMetadataMissing
        case rewardHasNoTransactionOutputs
        case rewardHasMoreThanOneTransactionOutputs // Only for non genesis block
        case creatorCoinMetadataMissing
        case creatorCoinBuyInvalid
        case creatorCoinSellInvalid
        case creatorKeyBeingTransactedMissing
        case followTransactionMetadataMissing
        case privateMessageSenderOrReceiverMissing
        case unfollowTransactionIsNotValid
        case updateProfileMetadataMissing
    }
    
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
    
    var publicKeysInOrder: [String] = []
    
    func parseAllAccounts() -> [Account] {
        var accountsByPublicKey: [String : Account] = [:]
        var publicKeyOriginalToNewSwap: [String : String] = [:]
        blockIteration: for blockHeight in 0...self.lastAvailableBlockHeight {
            World.currentBlockHeight = blockHeight
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
                        do {
                            switch transaction.transactionType {
                                case .basicTransfer:
                                    try parseBasicTransfer(transaction: transaction, block: block,
                                                           accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: publicKeyOriginalToNewSwap)
                                case .bitcoinExchange:
                                    try parseBitcoinExchange(transaction: transaction, block: block,
                                                             accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: publicKeyOriginalToNewSwap)
                                case .blockReward:
                                    try parseBlockReward(transaction: transaction, block: block,
                                                         accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: publicKeyOriginalToNewSwap)
                                case .creatorCoin:
                                    try parseCreatorCoin(transaction: transaction, block: block,
                                                         accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: publicKeyOriginalToNewSwap)
                                    break
                                case .creatorCoinTransfer:
                                    // TODO: implement
                                    break
                                case .follow:
                                    try parseFollow(transaction: transaction, block: block,
                                                    accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: publicKeyOriginalToNewSwap)
                                case .like:
                                    try parseLike(transaction: transaction, block: block,
                                                  accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: publicKeyOriginalToNewSwap)
                                case .privateMessage:
                                    try parsePrivateMessage(transaction: transaction, block: block,
                                                            accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: publicKeyOriginalToNewSwap)
                                case .submitPost:
                                    try parseSubmitPost(transaction: transaction, block: block,
                                                        accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: publicKeyOriginalToNewSwap)
                                case .swapIdentity:
                                    try parseSwapIdentity(transaction: transaction, block: block,
                                                          accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: &publicKeyOriginalToNewSwap)
                                case .updateBitcoinUsdExchangeRate:
                                    try parseUpdateBitcoinUsdExchangeRate(transaction: transaction, block: block,
                                                                          accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: publicKeyOriginalToNewSwap)
                                    break
                                case .updateGlobalParams:
                                    // TODO: implement
                                    break
                                case .updateProfile:
                                    try parseUpdateProfile(transaction: transaction, block: block,
                                                           accountsByPublicKey: &accountsByPublicKey, publicKeyOriginalToNewSwap: publicKeyOriginalToNewSwap)
                            }
                        } catch StateManagerErrors.transactionMetadataMissing {
                            print("Error: .\(transaction.transactionType) block type should have transaction.transactionMetadata at #\(blockHeight)")
                        } catch StateManagerErrors.basicTransferTransactionMetadataMissing {
                            print("Error: .basicTransfer block type should have transaction.transactionMetadata.basicTransferTxindexMetadata at #\(blockHeight)")
                        } catch StateManagerErrors.basicTransferNoSender {
                            assert(true, "Error: did not find sender in the transaction, how is even this possible...")
                        } catch StateManagerErrors.bitcoinExchangeTransactionMetadataMissing {
                            print("Error: .bitcoinExchange block type should have transaction.transactionMetadata.bitcoinExchangeTxindexMetadata at #\(blockHeight)")
                        } catch StateManagerErrors.rewardHasNoTransactionOutputs {
                            print("Error: .blockReward block type should have at least one object in transaction.outputs.")
                        } catch StateManagerErrors.rewardHasMoreThanOneTransactionOutputs {
                            print("Error: .blockReward block type should have only one object in transaction.outputs (except for genesis block).")
                        } catch StateManagerErrors.creatorCoinMetadataMissing {
                            print("Error: .creatorCoin block type should have metadata at block #\(blockHeight)")
                        } catch StateManagerErrors.creatorCoinBuyInvalid {
                            print("Error: .creatorCoin invalid buy at block #\(blockHeight)")
                        } catch StateManagerErrors.creatorCoinSellInvalid {
                            print("Error: .creatorCoin invalid sell at block #\(blockHeight)")
                        } catch StateManagerErrors.creatorKeyBeingTransactedMissing {
                            print("Error: .creatorCoin transaction, no creator key found at block #\(blockHeight)")
                        } catch StateManagerErrors.followTransactionMetadataMissing {
                            print("Error: .follow transaction, no valid follow metadata found at block #\(blockHeight)")
                        } catch StateManagerErrors.privateMessageSenderOrReceiverMissing {
                            assert(true, "Error: .privateMessage block type should have a sender or receiver in the transaction at block #\(blockHeight)")
                        } catch StateManagerErrors.unfollowTransactionIsNotValid {
                            print("Error: .follow transaction, cannot unfollow without following first at block #\(blockHeight)")
                        } catch StateManagerErrors.updateProfileMetadataMissing {
                            print("Error: .updateProfile block type should have transaction.transactionMetadata.updateProfileTxindexMetadata")
                        } catch {
                            print("Error: unknown error: \(error)...")
                        }
                    }
                case .failure(let error):
                    print(">>>>>> Failed to read with error: \(error)")
                    break blockIteration
            }
        }
        print(">>>>>> accounts found: \(accountsByPublicKey.count)")
        print("> Done!")
        
        return publicKeysInOrder.map { accountsByPublicKey[$0]! }
    }
    
    // MARK: - Private
    
    func findOrCreateAccount(publicKey: String,
                             block: Block,
                             fromPool accountsByPublicKey: inout [String : Account],
                             swapPool publicKeyOriginalToNewSwap: [String : String],
                             isGenesis: Bool = false) -> Account {
        
        let publicKey = publicKeyOriginalToNewSwap[publicKey] ?? publicKey
        
        if let account = accountsByPublicKey[publicKey] {
            return account
        } else {
            let blockDate = Date(timeIntervalSince1970: Double(block.header!.tstampSecs))
            let account = Account(publicKey: publicKey, firstTransactionDate: blockDate, isGenesis: isGenesis)
            accountsByPublicKey[publicKey] = account
            publicKeysInOrder.append(publicKey)
            return account
        }
    }
    
    func parseBasicTransfer(transaction: Transaction, block: Block,
                            accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: [String : String]) throws {
        guard let transactionMetadata = transaction.transactionMetadata, let outputs = transaction.outputs else {
            throw StateManagerErrors.transactionMetadataMissing
        }
        guard let basicTransferMetadata = transactionMetadata.basicTransferTxindexMetadata else {
            throw StateManagerErrors.basicTransferTransactionMetadataMissing
        }
        var senderAccount: Account? = nil
        var receiverAccounts: [Account : Int] = [:]
        var totalAmountNanosSent: Int = 0
        for output in outputs {
            if output.publicKeyBase58Check == transactionMetadata.transactorPublicKeyBase58Check {
                if senderAccount != nil { assert(true, "Error: cannot prepare the sender address more than once") }
                senderAccount = findOrCreateAccount(publicKey: output.publicKeyBase58Check, block: block,
                                                    fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
            } else {
                let receiverAccount = findOrCreateAccount(publicKey: output.publicKeyBase58Check, block: block,
                                                          fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
                receiverAccounts[receiverAccount] = output.amountNanos
                totalAmountNanosSent += output.amountNanos
            }
        }
        if senderAccount == nil { // Sender not specified, not sure why, then we assume transactor is the sender.
            senderAccount = findOrCreateAccount(publicKey: transactionMetadata.transactorPublicKeyBase58Check, block: block,
                                                fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        }
        guard let sender = senderAccount else {
            throw StateManagerErrors.basicTransferNoSender
        }
        if receiverAccounts.count > 0 {
            for (receiver, amountNanos) in receiverAccounts {
                receiver.addToWallet(amountNanos: amountNanos, from: .transfer(sender.publicKey))
                receiver.increaseTransactionsCount()
            }
            sender.removeFromWallet(amountNanos: totalAmountNanosSent, to: .transfer(receiverAccounts.first!.key.publicKey)) // /!\ Only one receiver for now /!\
            sender.removeFromWallet(amountNanos: basicTransferMetadata.feeNanos, to: .fees)
            sender.increaseTransactionsCount()
        } else { // Receiver not specified, because we are sending to ourself? Assume transactor is receiver so just pay fees for no reason?
            sender.removeFromWallet(amountNanos: basicTransferMetadata.feeNanos, to: .fees)
            sender.increaseTransactionsCount()
        }
    }
    
    func parseBitcoinExchange(transaction: Transaction, block: Block,
                              accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: [String : String]) throws {
        guard let transactionMetadata = transaction.transactionMetadata else {
            throw StateManagerErrors.transactionMetadataMissing
        }
        guard let basicTransferMetadata = transactionMetadata.basicTransferTxindexMetadata else {
            throw StateManagerErrors.basicTransferTransactionMetadataMissing
        }
        guard let bitcoinExchangeMetadata = transactionMetadata.bitcoinExchangeTxindexMetadata else {
            throw StateManagerErrors.bitcoinExchangeTransactionMetadataMissing
        }
        let account = findOrCreateAccount(publicKey: transactionMetadata.transactorPublicKeyBase58Check, block: block,
                                          fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        account.bitcoinPublicKey = bitcoinExchangeMetadata.bitcoinSpendAddress
        account.addToSatoshisBurned(satoshis: bitcoinExchangeMetadata.satoshisBurned)
        account.addToWallet(amountNanos: basicTransferMetadata.totalOutputNanos, from: .bitcoinExchange)
        account.increaseTransactionsCount()
    }
    
    func parseUpdateBitcoinUsdExchangeRate(transaction: Transaction, block: Block,
                                           accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: [String : String]) throws {
        guard let transactionMetadata = transaction.transactionMetadata else {
            throw StateManagerErrors.transactionMetadataMissing
        }
        
        // print(">> BTC_UPDATE,\(block.header!.height),\(Date(timeIntervalSince1970: TimeInterval(block.header!.tstampSecs)))")
        
        // TODO: implement
    }
    
    func parseBlockReward(transaction: Transaction, block: Block,
                          accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: [String : String]) throws {
        guard let outputs = transaction.outputs else {
            throw StateManagerErrors.rewardHasNoTransactionOutputs
        }
        let isGenesisBlock = block.header!.height == 0
        if isGenesisBlock {
            for output in outputs {
                let outputAccount = findOrCreateAccount(publicKey: output.publicKeyBase58Check, block: block,
                                                        fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap, isGenesis: true)
                outputAccount.addToWallet(amountNanos: output.amountNanos, from: .genesis)
                outputAccount.increaseTransactionsCount()
            }
        } else {
            guard outputs.count == 1, let output = outputs.first else {
                throw StateManagerErrors.rewardHasMoreThanOneTransactionOutputs
            }
            let outputAccount = findOrCreateAccount(publicKey: output.publicKeyBase58Check, block: block,
                                                    fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
            outputAccount.addToWallet(amountNanos: output.amountNanos, from: .fees)
            outputAccount.increaseTransactionsCount()
        }
    }
    
    func parseCreatorCoin(transaction: Transaction, block: Block,
                          accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: [String : String]) throws {
        guard let transactionMetadata = transaction.transactionMetadata else {
            throw StateManagerErrors.transactionMetadataMissing
        }
        guard let basicTransferMetadata = transactionMetadata.basicTransferTxindexMetadata else {
            throw StateManagerErrors.basicTransferTransactionMetadataMissing
        }
        guard let metadata = transactionMetadata.creatorCoinTxindexMetadata else {
            throw StateManagerErrors.creatorCoinMetadataMissing
        }
        var creatorKeyBeingTransacted: String? = nil
        for affectedPublicKey in transactionMetadata.affectedPublicKeys {
            if affectedPublicKey.metadata == .creatorPublicKey {
                creatorKeyBeingTransacted = affectedPublicKey.publicKeyBase58Check
                break
            }
        }
        guard let creatorKey = creatorKeyBeingTransacted else {
            throw StateManagerErrors.creatorKeyBeingTransactedMissing
        }
        let transactorAccount = findOrCreateAccount(publicKey: transactionMetadata.transactorPublicKeyBase58Check, block: block,
                                                    fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        let creatorAccount = findOrCreateAccount(publicKey: creatorKey, block: block,
                                                 fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        switch metadata.operationType {
            case .buy:
                guard transactorAccount.walletAmountNanos >= metadata.bitCloutToSellNanos else {
                    throw StateManagerErrors.creatorCoinBuyInvalid
                }
                let isBuyingOwnCoins = (transactorAccount == creatorAccount)
                let boughtCoins = creatorAccount.lockBitcloutToBuyCreatorCoins(bitcloutAmountNanos: metadata.bitCloutToSellNanos, fromSelf: isBuyingOwnCoins)
                if boughtCoins.creatorRewardNanoCoins > 0 {
                    let transactorAcounting = Int(Double(boughtCoins.receivedNanoCoins) / Double(boughtCoins.totalPaidNanoCoins) * Double(metadata.bitCloutToSellNanos))
                    transactorAccount.addToOwnedCreatorCoins(from: creatorAccount,
                                                             coinsAmountNanos: boughtCoins.receivedNanoCoins,
                                                             accounting: .bought(transactorAcounting))
                    
                    let creatorAcounting = Int(Double(boughtCoins.creatorRewardNanoCoins) / Double(boughtCoins.totalPaidNanoCoins) * Double(metadata.bitCloutToSellNanos))
                    creatorAccount.addToOwnedCreatorCoins(from: creatorAccount,
                                                          coinsAmountNanos: boughtCoins.creatorRewardNanoCoins,
                                                          accounting: .founderReward(creatorAcounting))
                } else {
                    let transactorAcounting = metadata.bitCloutToSellNanos
                    transactorAccount.addToOwnedCreatorCoins(from: creatorAccount,
                                                             coinsAmountNanos: boughtCoins.receivedNanoCoins,
                                                             accounting: .bought(transactorAcounting))
                }
                transactorAccount.removeFromWallet(amountNanos: metadata.bitCloutToSellNanos, to: .creatorCoins(creatorAccount.publicKey))
            case .sell:
                guard transactorAccount.ownedCreatorCoinsNano[creatorAccount] != nil else {
                    throw StateManagerErrors.creatorCoinSellInvalid // Not even owned, how can you sell?
                }
                let bitcloutAmount = creatorAccount.unlockBitcloutBySellingCreatorCoins(creatorCoinNanoAmount: metadata.creatorCoinToSellNanos)
                transactorAccount.removeFromOwnedCreatorCoins(from: creatorAccount, coinsAmountNanos: metadata.creatorCoinToSellNanos, accounting: bitcloutAmount)
                transactorAccount.addToWallet(amountNanos: bitcloutAmount, from: .creatorCoins(creatorAccount.publicKey))
        }
        transactorAccount.removeFromWallet(amountNanos: basicTransferMetadata.feeNanos, to: .fees)
        transactorAccount.increaseTransactionsCount()
    }
    
    func parseFollow(transaction: Transaction, block: Block,
                     accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: [String : String]) throws {
        guard let transactionMetadata = transaction.transactionMetadata else {
            throw StateManagerErrors.transactionMetadataMissing
        }
        guard let basicTransferMetadata = transactionMetadata.basicTransferTxindexMetadata else {
            throw StateManagerErrors.basicTransferTransactionMetadataMissing
        }
        guard let followMetadata = transactionMetadata.followTxindexMetadata else {
            throw StateManagerErrors.followTransactionMetadataMissing
        }
        assert(transactionMetadata.affectedPublicKeys.count == 2, "Follow transaction should have 2 affectedPublicKeys.")
        var transactorKey: String? = nil
        var followedKey: String? = nil
        for affectedPublicKey in transactionMetadata.affectedPublicKeys {
            if affectedPublicKey.metadata == .basicTransferOutput {
                transactorKey = affectedPublicKey.publicKeyBase58Check
            } else if affectedPublicKey.metadata == .followedPublicKeyBase58Check {
                followedKey = affectedPublicKey.publicKeyBase58Check
            }
        }
        guard let transactor = transactorKey, let followed = followedKey else {
            throw StateManagerErrors.followTransactionMetadataMissing
        }
        let transactorAccount = findOrCreateAccount(publicKey: transactor, block: block,
                                                    fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        let followedAccount = findOrCreateAccount(publicKey: followed, block: block,
                                                  fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        if followMetadata.isUnfollow {
            if !followedAccount.followers.contains(transactorAccount) { throw StateManagerErrors.unfollowTransactionIsNotValid }
            if !transactorAccount.following.contains(followedAccount) { throw StateManagerErrors.unfollowTransactionIsNotValid }
            followedAccount.followers.remove(transactorAccount)
            transactorAccount.following.remove(followedAccount)
        } else {
            followedAccount.followers.insert(transactorAccount)
            transactorAccount.following.insert(followedAccount)
        }
        transactorAccount.removeFromWallet(amountNanos: basicTransferMetadata.feeNanos, to: .fees)
    }
    
    func parseLike(transaction: Transaction, block: Block,
                   accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: [String : String]) throws {
        guard let transactionMetadata = transaction.transactionMetadata else {
            throw StateManagerErrors.transactionMetadataMissing
        }
        
        // TODO: Implement
    }
    
    func parsePrivateMessage(transaction: Transaction, block: Block,
                             accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: [String : String]) throws {
        guard let transactionMetadata = transaction.transactionMetadata else {
            throw StateManagerErrors.transactionMetadataMissing
        }
        var senderKey: String? = nil
        var receiverKey: String? = nil
        for affectedPublicKey in transactionMetadata.affectedPublicKeys {
            if affectedPublicKey.metadata == .basicTransferOutput {
                senderKey = affectedPublicKey.publicKeyBase58Check
            } else if affectedPublicKey.metadata == .recipientPublicKeyBase58Check {
                receiverKey = affectedPublicKey.publicKeyBase58Check
            }
        }
        guard let sender = senderKey, let receiver = receiverKey else {
            throw StateManagerErrors.privateMessageSenderOrReceiverMissing
        }
        let senderAccount = findOrCreateAccount(publicKey: sender, block: block,
                                                fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        let receiverAccount = findOrCreateAccount(publicKey: receiver, block: block,
                                                  fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        senderAccount.addSentMessage(to: receiverAccount)
        senderAccount.increaseTransactionsCount()
        receiverAccount.addReceivedMessage(from: senderAccount)
        receiverAccount.increaseTransactionsCount()
    }
    
    func parseSubmitPost(transaction: Transaction, block: Block,
                         accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: [String : String]) throws {
        guard let transactionMetadata = transaction.transactionMetadata else {
            throw StateManagerErrors.transactionMetadataMissing
        }
        guard let basicTransferMetadata = transactionMetadata.basicTransferTxindexMetadata else {
            throw StateManagerErrors.basicTransferTransactionMetadataMissing
        }
     
        
        // TODO: Implement
        
        
        let transactorAccount = findOrCreateAccount(publicKey: transactionMetadata.transactorPublicKeyBase58Check, block: block,
                                                    fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        transactorAccount.removeFromWallet(amountNanos: basicTransferMetadata.feeNanos, to: .fees)
    }
    
    func parseSwapIdentity(transaction: Transaction, block: Block,
                           accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: inout [String : String]) throws {
        guard let transactionMetadata = transaction.transactionMetadata else {
            throw StateManagerErrors.transactionMetadataMissing
        }
        guard let basicTransferMetadata = transactionMetadata.basicTransferTxindexMetadata else {
            throw StateManagerErrors.basicTransferTransactionMetadataMissing
        }
        guard let swapIdentityMetadata = transactionMetadata.swapIdentityTxindexMetadata else {
            throw StateManagerErrors.basicTransferTransactionMetadataMissing
        }
        
        let fromAccount = findOrCreateAccount(publicKey: swapIdentityMetadata.fromPublicKeyBase58Check, block: block,
                                              fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        fromAccount.swapToNewPublicKey(swapIdentityMetadata.toPublicKeyBase58Check)
        fromAccount.removeFromWallet(amountNanos: basicTransferMetadata.feeNanos, to: .fees)
        fromAccount.increaseTransactionsCount()
        
        publicKeyOriginalToNewSwap[swapIdentityMetadata.toPublicKeyBase58Check] = fromAccount.publicKeys.first
    }
    
    func parseUpdateProfile(transaction: Transaction, block: Block,
                            accountsByPublicKey: inout [String : Account], publicKeyOriginalToNewSwap: [String : String]) throws {
        guard let transactionMetadata = transaction.transactionMetadata else {
            throw StateManagerErrors.transactionMetadataMissing
        }
        guard let basicTransferMetadata = transactionMetadata.basicTransferTxindexMetadata else {
            throw StateManagerErrors.basicTransferTransactionMetadataMissing
        }
        guard let updateProfileMetadata = transactionMetadata.updateProfileTxindexMetadata else {
            throw StateManagerErrors.updateProfileMetadataMissing
        }
        let account = findOrCreateAccount(publicKey: transactionMetadata.transactorPublicKeyBase58Check, block: block,
                                          fromPool: &accountsByPublicKey, swapPool: publicKeyOriginalToNewSwap)
        account.addProfile(metadata: updateProfileMetadata)
        account.removeFromWallet(amountNanos: basicTransferMetadata.feeNanos, to: .fees)
        account.increaseTransactionsCount()
    }
}
