//
//  StorageClient.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/20/21.
//

import Foundation

class StorageClient {
    
    private let fileManager = FileManager.default
    
    func hasDataForBlock(height: Int) -> Bool {
        let filename = getFilenameForBlock(height: height)
        return fileManager.fileExists(atPath: filename.path)
    }
    
    func writeBlock(data: Data, height: Int) -> Error? {
        let filename = getFilenameForBlock(height: height)
        do {
            try data.write(to: filename, options: .atomic)
        } catch (let error) {
            return error
        }
        return nil
    }
    
    func readBlock(height: Int) -> Result<Block, Error> {
        let filename = getFilenameForBlock(height: height)
        do {
            let data = try Data(contentsOf: filename)
            let result = self.parseBlockData(data: data)
            return result
        } catch (let error) {
            return .failure(error)
        }
    }
    
    func deleteBlock(height: Int) -> Error? {
        let filename = getFilenameForBlock(height: height)
        do {
            try fileManager.removeItem(at: filename)
        } catch (let error) {
            return error
        }
        return nil
    }
    
    // MARK: - Private
    
    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func getFilenameForBlock(height: Int) -> URL {
        return getDocumentsDirectory().appendingPathComponent("blocks/\(height).txt")
    }
    
    private func parseBlockData(data: Data) -> Result<Block, Error> {
        do {
            let decoder = JSONDecoder()
            let block = try decoder.decode(Block.self, from: data)
            guard block.error.isEmpty else {
                return .failure(BitCloutError.responseBlockError(block.error))
            }
            return .success(block)
        } catch (let error) {
            print(error)
            return .failure(BitCloutError.jsonFormatError)
        }
    }
}
