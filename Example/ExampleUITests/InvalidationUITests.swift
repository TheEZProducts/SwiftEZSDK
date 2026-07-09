//
//  InvalidationUITests.swift
//  ExampleUITests
//
//  Created by Александр Сенин on 07.07.2026.
//

import XCTest

final class InvalidationUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func test_pureSUI_invalidates() {
        assertIncrementUpdatesLabel(mode: "pure", label: "counter.value", button: "counter.inc")
    }

    func test_structSView_invalidates() {
        assertIncrementUpdatesLabel(mode: "sview", label: "sview.vmCount", button: "sview.inc")
    }

    func test_uiViewSView_invalidates() {
        assertIncrementUpdatesLabel(mode: "suiv", label: "suiv.vmCount", button: "suiv.inc")
    }

    private func assertIncrementUpdatesLabel(mode: String, label: String, button: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", mode]
        app.launch()

        let value = app.staticTexts[label]
        XCTAssertTrue(value.waitForExistence(timeout: 10), "label \(label) not found on screen")
        let before = value.label

        let increment = app.buttons[button]
        XCTAssertTrue(increment.waitForExistence(timeout: 5), "button \(button) not found on screen")
        increment.tap()

        let changed = expectation(
            for: NSPredicate(format: "label != %@", before),
            evaluatedWith: value
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [changed], timeout: 5), .completed,
            "\(label) did not update after tapping \(button) — view-model invalidation is broken"
        )
    }
}
