//
//  WaterLoggingTests.swift
//  WaterLoggingTests
//
//  Created by Jessie Pease on 5/18/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import XCTest
@testable import WaterLogging

class WaterLoggingTests: XCTestCase {

    func testRecommendedIntake() throws {
        let defaultRecommendation = DataService.shared.recommendedIntakeBasedOnMass(nil)

        XCTAssertEqual(defaultRecommendation.converted(to: .fluidOunces).value
            , 100.0, accuracy: 0.1)

        let healthKitRecommendation = DataService.shared.recommendedIntakeBasedOnMass(Measurement<UnitMass>(value: 200.0, unit: .pounds))

        XCTAssertEqual(healthKitRecommendation.converted(to: .fluidOunces).value
            , 133.33, accuracy: 0.1)
    }
}
