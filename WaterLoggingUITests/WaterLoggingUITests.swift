//
//  WaterLoggingUITests.swift
//  WaterLoggingUITests
//
//  Created by Lucas Best on 6/24/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import XCTest

class WaterLoggingUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAddGoal() throws {
        let app = XCUIApplication()
        app.launch()

        let goalCell = app.cells.firstMatch
        let foundGoalCell = goalCell.waitForExistence(timeout: 10.0)

        XCTAssert(foundGoalCell, "Could not find Goal Label in cell.")

        goalCell.tap()

        // In case this is the first time seeing HealthKit Permissions
        let turnOnButton = app.cells.staticTexts["Turn All Categories On"].firstMatch
        let turnOnButtonExists = turnOnButton.waitForExistence(timeout: 5.0)

        if turnOnButtonExists {
            turnOnButton.tap()

            let allowButton = app.buttons["Allow"]
            let enabled = NSPredicate(format: "enabled == 1")

            self.expectation(for: enabled, evaluatedWith: allowButton, handler: nil)
            self.waitForExpectations(timeout: 10, handler: nil)

            allowButton.tap()
        }

        let goalSlider = app.sliders.firstMatch

        let foundGoalSlider = goalSlider.waitForExistence(timeout: 10.0)

        XCTAssert(foundGoalSlider, "Could not find Goal slider.")

        goalSlider.adjust(toNormalizedSliderPosition: 0.75)

        let goalLabel = app.staticTexts["goalLabel"]

        XCTAssertEqual(goalLabel.label, "3.5 quarts", "Goal label has incorrect label after sliding.")

        let setGoalButton = app.buttons["setGoalButton"]
        let setGoalButtonExists = setGoalButton.waitForExistence(timeout: 5.0)

        XCTAssert(setGoalButtonExists)

        setGoalButton.tap()

        let goalLabelInCell = goalCell.staticTexts["cellGoalLabel"]
        let goalLabelInCellExists = goalCell.waitForExistence(timeout: 5.0)

        XCTAssert(goalLabelInCellExists)
        XCTAssertEqual(goalLabelInCell.label, "Intake Goal: 3.5 quarts", "Goal label has incorrect label after sliding.")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
