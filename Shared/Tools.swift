//
//  Tools.swift
//  BitClout
//
//  Created by Ludovic Landry on 3/22/21.
//

import Foundation

class Tools {
    
    static let nanoToUnit: Double = 1_000_000_000
    static let satoshiToBtc: Double = 100_000_000
    private static let bondingCurveMultiplierThird: Double = 0.001 // The real one is 0.003 but we always need to divide by 3 so here we go.
    
    // Price in BitClout = .003 * creator_coins_in_circulation^2
    // Price in USD = .003 * creator_coins_in_circulation^2 * bitclout_price_in_usd
    
    static func creatorTotalBitcloutNanoLocked(coinsNanoInCirculation: Int) -> Int {
        let coinsInCirculation = Double(coinsNanoInCirculation) / nanoToUnit
        return Int(0.001 * pow(coinsInCirculation, 3) * nanoToUnit) // 0.001 comes from 0.003 * 1/3
    }
    
    static func creatorCoinsNanoInCirculation(totalBitcloutNanoLocked: Int) -> Int {
        let totalBitcloutLocked = Double(totalBitcloutNanoLocked) / nanoToUnit
        return Int(10.0 * pow(totalBitcloutLocked, 1.0 / 3.0) * nanoToUnit) // 10 comes from cube root of (1 / (0.003 * 1/3)))
    }
    
    static func creatorCoinsNanoBaught(bitCloutNanoAmount: Int, totalBitcloutNanoLocked: Int) -> Int {
        let coinsNanoInCirculationBefore = creatorCoinsNanoInCirculation(totalBitcloutNanoLocked: totalBitcloutNanoLocked)
        let coinsNanoInCirculationAfter = creatorCoinsNanoInCirculation(totalBitcloutNanoLocked: totalBitcloutNanoLocked + bitCloutNanoAmount)
        return coinsNanoInCirculationAfter - coinsNanoInCirculationBefore
    }
    
    static func creatorCoinsNanoSold(creatorCoinNanoAmount: Int, totalBitcloutNanoLocked: Int) -> Int {
        let coinsNanoInCirculationBefore = creatorCoinsNanoInCirculation(totalBitcloutNanoLocked: totalBitcloutNanoLocked)
        let coinsNanoInCirculationAfter = coinsNanoInCirculationBefore - creatorCoinNanoAmount
        let newTotalBitcloutNanoLocked = totalBitcloutNanoLocked - creatorTotalBitcloutNanoLocked(coinsNanoInCirculation: coinsNanoInCirculationAfter)
        return newTotalBitcloutNanoLocked
    }
}

extension Double {

    func toString(decimal: Int = 9) -> String {
        let value = decimal < 0 ? 0 : decimal
        var string = String(format: "%.\(value)f", self)

        while string.last == "0" || string.last == "." {
            if string.last == "." { string = String(string.dropLast()); break}
            string = String(string.dropLast())
        }
        return string
    }
}
