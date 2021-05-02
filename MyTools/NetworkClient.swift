//
//  NetworkClient.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/19/21.
//

import Foundation

enum BitCloutError: Error {
    case responseBlockError(String)
    case unknownError
    case jsonFormatError
    case captchaFoundError(String)
}

class NetworkClient {
    
    let baseUrl = "https://api.bitclout.com"
    
    typealias ExplorerResult = (rawData: Data, block: Block)
    
    // MARK: - Get Profile
    
    func getSingleProfile(username: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        let url = URL(string: "\(baseUrl)/get-single-profile")!
        let body = ["PublicKeyBase58Check" : "", "Username" : username]
        let httpMethod = "POST"
        
        fetch(url: url, body: body, httpMethod: httpMethod) { result in
            switch result {
                case .success(let data):
                    let decoder = JSONDecoder()
                    do {
                        let singleProfileResponse = try decoder.decode(SingleProfileResponse.self, from: data)
                        completion(.success(singleProfileResponse.profile))
                    } catch {
                        completion(.failure(BitCloutError.jsonFormatError))
                    }
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    // MARK: - Block Explorer
    
    func getTransactions(address: String, completion: @escaping (Result<ExplorerResult, Error>) -> Void) {
        let url = URL(string: "\(baseUrl)/api/v1/transaction-info")!
        let body = ["PublicKeyBase58Check" : address]
        let httpMethod = "POST"
        
        fetch(url: url, body: body, httpMethod: httpMethod) { result in
            switch result {
                case .success(let data):
                    let result = self.parseBlockData(data: data)
                    completion(result)
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    func getTransactions(blockHeight: Int, completion: @escaping (Result<ExplorerResult, Error>) -> Void) {
        let url = URL(string: "\(baseUrl)/api/v1/block")!
        let body: [String : Any] = ["Height" : blockHeight, "FullBlock" : true]
        let httpMethod = "POST"
        
        fetch(url: url, body: body, httpMethod: httpMethod) { result in
            switch result {
                case .success(let data):
                    let result = self.parseBlockData(data: data)
                    completion(result)
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private
    
    private func fetch(url: URL, body: [String : Any]?, httpMethod: String, completion: @escaping (Result<Data, Error>) -> Void) {
        
        // Configure request authentication
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.1 Safari/605.1.15", forHTTPHeaderField: "User-Agent")

        // Change the URLRequest to a POST request
        request.httpMethod = httpMethod
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        }
        
        // Create the HTTP request
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in

            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                let content = String(decoding: data, as: UTF8.self)
                if content.starts(with: "<!DOCTYPE html>") {
                    completion(.failure(BitCloutError.captchaFoundError(content)))
                } else {
                    completion(.success(data))
                }
            } else {
                completion(.failure(BitCloutError.unknownError))
            }
        }
        
        // Start HTTP Request
        task.resume()
    }
    
    func parseBlockData(data: Data) -> Result<ExplorerResult, Error> {
        do {
            let decoder = JSONDecoder()
            let block = try decoder.decode(Block.self, from: data)
            guard block.error.isEmpty else {
                return .failure(BitCloutError.responseBlockError(block.error))
            }
            return .success((rawData: data, block: block))
        } catch (let error) {
            print(error)
            return .failure(BitCloutError.jsonFormatError)
        }
    }
}
