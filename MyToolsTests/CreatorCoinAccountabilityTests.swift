//
//  CreatorCoinAccountabilityTests.swift
//  CreatorCoinAccountabilityTests
//
//  Created by Ludovic Landry on 4/8/21.
//

import XCTest
@testable import BitClout

class CreatorCoinAccountabilityTests: XCTestCase {

    var account = Account(publicKey: "0123", firstTransactionDate: Date(), isGenesis: false)
    
    func testBuy() {
        let accountability = CreatorCoinAccountability(account: account)
        accountability.buy(creatorCoinNano: 10, fromBitCloutNano: 200)
        
        let summary = accountability.summary()
        assert(summary: summary,
               tokenIn: 200, coinIn: 10,
               tokenReward: 0, coinReward: 0,
               tokenLocked: 200, coinLocked: 10,
               tokenOut: 0, coinOut: 0)
    }
    
    func testBuy_updateCurrentCoinPrice() {
        let accountability = CreatorCoinAccountability(account: account)
        accountability.buy(creatorCoinNano: 10, fromBitCloutNano: 200)
        
        let summary = accountability.summary(currentCoinPriceNano: 50)
        assert(summary: summary,
               tokenIn: 200, coinIn: 10,
               tokenReward: 0, coinReward: 0,
               tokenLocked: 500, coinLocked: 10,
               tokenOut: 0, coinOut: 0)
    }
    
    func testSell() {
        let accountability = CreatorCoinAccountability(account: account)
        accountability.buy(creatorCoinNano: 10, fromBitCloutNano: 200)
        accountability.sell(creatorCoinNano: 4, toBitCloutNano: 150)
        
        let summary = accountability.summary()
        assert(summary: summary,
               tokenIn: 200, coinIn: 10,
               tokenReward: 0, coinReward: 0,
               tokenLocked: 50, coinLocked: 6,
               tokenOut: 150, coinOut: 4)
    }
    
    func testSell_updateCurrentCoinPrice() {
        let accountability = CreatorCoinAccountability(account: account)
        accountability.buy(creatorCoinNano: 10, fromBitCloutNano: 200)
        accountability.sell(creatorCoinNano: 4, toBitCloutNano: 150)
        
        let summary = accountability.summary(currentCoinPriceNano: 50)
        assert(summary: summary,
               tokenIn: 200, coinIn: 10,
               tokenReward: 0, coinReward: 0,
               tokenLocked: 300, coinLocked: 6,
               tokenOut: 150, coinOut: 4)
    }
    
    func testSellAll_ignoreCurrentCoinPrice() {
        let accountability = CreatorCoinAccountability(account: account)
        accountability.buy(creatorCoinNano: 10, fromBitCloutNano: 200)
        accountability.sell(creatorCoinNano: 10, toBitCloutNano: 2_000)
        
        let summary = accountability.summary(currentCoinPriceNano: 50_000_000)
        assert(summary: summary,
               tokenIn: 200, coinIn: 10,
               tokenReward: 0, coinReward: 0,
               tokenLocked: 0, coinLocked: 0,
               tokenOut: 2_000, coinOut: 10)
    }
    
    func testRebuy() {
        let accountability = CreatorCoinAccountability(account: account)
        accountability.buy(creatorCoinNano: 10, fromBitCloutNano: 200)
        accountability.sell(creatorCoinNano: 6, toBitCloutNano: 2_000)
        accountability.buy(creatorCoinNano: 1, fromBitCloutNano: 2_000)
        
        let summary = accountability.summary(currentCoinPriceNano: 1_000)
        assert(summary: summary,
               tokenIn: 200, coinIn: 10,
               tokenReward: 0, coinReward: 0,
               tokenLocked: 5000, coinLocked: 5,
               tokenOut: 0, coinOut: 5)
    }
    
    func testRebuy_moreTokensThanSold() {
        let accountability = CreatorCoinAccountability(account: account)
        accountability.buy(creatorCoinNano: 10, fromBitCloutNano: 200)
        accountability.sell(creatorCoinNano: 6, toBitCloutNano: 2_000)
        accountability.buy(creatorCoinNano: 1, fromBitCloutNano: 3_000)
        
        let summary = accountability.summary(currentCoinPriceNano: 1_000)
        assert(summary: summary,
               tokenIn: 1200, coinIn: 10,
               tokenReward: 0, coinReward: 0,
               tokenLocked: 5000, coinLocked: 5,
               tokenOut: 0, coinOut: 5)
    }
    
    func testRebuy_moreCoinsThanSold() {
        let accountability = CreatorCoinAccountability(account: account)
        accountability.buy(creatorCoinNano: 10, fromBitCloutNano: 200)
        accountability.sell(creatorCoinNano: 2, toBitCloutNano: 2_000)
        accountability.buy(creatorCoinNano: 4, fromBitCloutNano: 1_000)
        
        let summary = accountability.summary(currentCoinPriceNano: 1_000)
        assert(summary: summary,
               tokenIn: 200, coinIn: 12, // ?? 10 or 12
               tokenReward: 0, coinReward: 0,
               tokenLocked: 12000, coinLocked: 12,
               tokenOut: 1000, coinOut: 0) // ?? 0 or 2
    }
    
    func testResellAll() {
        let accountability = CreatorCoinAccountability(account: account)
        accountability.buy(creatorCoinNano: 10, fromBitCloutNano: 200)
        accountability.sell(creatorCoinNano: 2, toBitCloutNano: 2_000)
        accountability.buy(creatorCoinNano: 4, fromBitCloutNano: 3_000)
        accountability.sell(creatorCoinNano: 2, toBitCloutNano: 20_000)
        accountability.buy(creatorCoinNano: 1, fromBitCloutNano: 200)
        accountability.sell(creatorCoinNano: 11, toBitCloutNano: 100_000)
        
        let summary = accountability.summary(currentCoinPriceNano: 1_000)
        assert(summary: summary,
               tokenIn: 1_200, coinIn: 12,
               tokenReward: 0, coinReward: 0,
               tokenLocked: 0, coinLocked: 0,
               tokenOut: 119_800, coinOut: 12)
    }
    
    // MARK - Private
    
    func assert(summary: CreatorCoinAccountability.CreatorCoinTransactionSummary,
                tokenIn: Int, coinIn: Int,
                tokenReward: Int, coinReward: Int,
                tokenLocked: Int, coinLocked: Int,
                tokenOut: Int, coinOut: Int) {
        XCTAssertEqual(summary.bitCloutNanoIn, tokenIn)
        XCTAssertEqual(summary.creatorCoinNanoIn, coinIn)
        XCTAssertEqual(summary.bitCloutReward, tokenReward)
        XCTAssertEqual(summary.creatorCoinNanoReward, coinReward)
        XCTAssertEqual(summary.bitCloutLocked, tokenLocked)
        XCTAssertEqual(summary.creatorCoinNanoLocked, coinLocked)
        XCTAssertEqual(summary.bitCloutNanoOut, tokenOut)
        XCTAssertEqual(summary.creatorCoinNanoOut, coinOut)
    }
}
