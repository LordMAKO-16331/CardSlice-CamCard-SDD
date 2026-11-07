//
//  CardSliceUITests.swift
//  CardSliceUITests
//
//  Created by 谢薇 on 2026/11/2.
//

import XCTest

final class CardSliceUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing-mock-cards")
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testNavigationToDetail() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing-mock-cards")
        app.launch()

        // 1. 确认名片列表可见 (John Doe)
        let firstCard = app.staticTexts["John Doe"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5), "John Doe 应该在名片列表中可见")

        // 2. 点击进入详情页
        firstCard.tap()

        // 3. 验证进入详情页后的核心内容
        XCTAssertTrue(app.navigationBars["名片详情"].exists, "应该进入 名片详情页")
        XCTAssertTrue(app.staticTexts["Tech Innovators Inc."].exists, "详情页应该显示公司信息")
        XCTAssertTrue(app.staticTexts["john.doe@example.com"].exists, "详情页应该显示 Email")

        // 4. 返回列表
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // 5. 确认重新回到 CardHolder
        XCTAssertTrue(app.navigationBars["名片夹"].exists, "应该返回 名片夹列表页")
        XCTAssertTrue(app.staticTexts["John Doe"].exists, "返回后列表应该重新可见")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments.append("--ui-testing-mock-cards")
            app.launch()
        }
    }
}
