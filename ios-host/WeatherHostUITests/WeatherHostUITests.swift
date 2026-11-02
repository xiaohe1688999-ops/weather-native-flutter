import XCTest

final class WeatherHostUITests: XCTestCase {
    func testHybridWeatherRoundTripAndPersistence() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let search = app.textFields["citySearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 15))
        search.tap(); search.typeText("Shanghai")
        let city = app.buttons["city-1796236"]
        XCTAssertTrue(city.waitForExistence(timeout: 25), "Requires a working Open-Meteo connection")
        city.tap()
        let forecast = app.descendants(matching: .any).matching(identifier: "forecast-heading").firstMatch
        XCTAssertTrue(forecast.waitForExistence(timeout: 30))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "iOS live weather"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["返回城市搜索"].tap()
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        app.buttons["清空搜索"].tap()
        XCTAssertTrue(app.staticTexts["最近查看"].waitForExistence(timeout: 10))
        XCTAssertTrue(city.exists)
        city.tap()
        XCTAssertTrue(forecast.waitForExistence(timeout: 30))
        app.buttons["返回城市搜索"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["city-1796236"].waitForExistence(timeout: 15))
    }
}
