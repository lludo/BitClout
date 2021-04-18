//
//  QueryManager.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

class QueryManager {
    
    private let networckClient = NetworkClient()
    private let storageClient = StorageClient()
    
    func fetchBlocks(fromHeight height: Int = 0, completion: @escaping (Result<Int, Error>) -> Void) {
        resursiveFetchBlock(fromHeight: height, transactionCount: 0, completion: completion)
    }
    
    // MARK: - Private
    
    private func resursiveFetchBlock(fromHeight height: Int,
                                     transactionCount: Int,
                                     completion: @escaping (Result<Int, Error>) -> Void) {
        fetchBlock(height: height) { result in
            switch result {
                case .success(let block):
                    self.resursiveFetchBlock(fromHeight: height + 1, transactionCount: transactionCount + (block.transactions?.count ?? 0), completion: completion)
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    private func fetchBlock(height: Int, completion: @escaping (Result<Block, Error>) -> Void) {
        if storageClient.hasDataForBlock(height: height) {
            let result = self.storageClient.readBlock(height: height)
            switch result {
                case .success(let block):
                    print(">>>>>> Block \(height) already stored on disk. Has \(block.transactions?.count ?? 0) transactions.")
                    completion(.success(block))
                case .failure(let error):
                    print(">>>>>> Block \(height) already stored on disk. Error while loading: \(error)!!!")
                    completion(.failure(error))
            }
        } else {
            networckClient.getTransactions(blockHeight: height) { result in
                switch result {
                    case .success(let result):
                        print(">>>>>> Block \(height) fetched from explorer!\t(\(result.block.transactions?.count ?? 0) transactions)")
                        if let error = self.storageClient.writeBlock(data: result.rawData, height: height) {
                            print(">>>>>> Error while saving data for block \(height): \(error)")
                            completion(.failure(error))
                        } else {
                            completion(.success(result.1))
                        }
                    case .failure(let error):
                        print(">>>>>> Error while fetching blocks: \(error)")
                        completion(.failure(error))
                }
            }
        }
    }
}
