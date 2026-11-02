import XCTest
@testable import WeatherCore

final class WeatherCoreTests: XCTestCase {
    private func city(_ id: Int) -> City { City(id: id, name: "城市\(id)", latitude: 31, longitude: 121) }

    func testRecentCitiesDeduplicateAndLimit() {
        let original = (1...5).map(city)
        XCTAssertEqual(RecentCities.adding(city(3), to: original).map(\.id), [3, 1, 2, 4, 5])
        XCTAssertEqual(RecentCities.adding(city(6), to: original).map(\.id), [6, 1, 2, 3, 4])
    }
    func testDecodeEmptyMissingOptionalFieldsAndInvalidCoordinates() throws {
        XCTAssertTrue(try OpenMeteoCityRepository.decode(Data("{}".utf8)).isEmpty)
        let valid = Data(#"{"results":[{"id":1,"name":"上海","latitude":31,"longitude":121}]}"#.utf8)
        XCTAssertEqual(try OpenMeteoCityRepository.decode(valid).first?.name, "上海")
        let invalid = Data(#"{"results":[{"id":1,"name":"X","latitude":100,"longitude":0}]}"#.utf8)
        XCTAssertThrowsError(try OpenMeteoCityRepository.decode(invalid))
        XCTAssertThrowsError(try OpenMeteoCityRepository.decode(Data("not JSON".utf8)))
    }
    @MainActor
    func testPersistenceRoundTrip() throws {
        let name = "weather-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = HomeModel(defaults: defaults)
        model.record(city(1)); model.record(city(2)); model.record(city(1))
        XCTAssertEqual(HomeModel(defaults: defaults).recent.map(\.id), [1, 2])
    }
    @MainActor
    func testClearingSearchSuppressesOlderResponse() async throws {
        let name = "weather-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let repository = DelayedRepository()
        let model = HomeModel(repository: repository, defaults: defaults)
        model.search("Shanghai", immediately: true)
        // 等待测试替身实际收到请求，避免依赖固定时长的休眠。
        await repository.waitForRequest()
        model.search("")
        await repository.complete(with: [city(1)])
        for _ in 0..<10 { await Task.yield() }
        XCTAssertTrue(model.cities.isEmpty)
        XCTAssertFalse(model.loading)
    }
}

private actor DelayedRepository: CityRepository {
    private var continuation: CheckedContinuation<[City], Error>?
    private var waiter: CheckedContinuation<Void, Never>?
    func search(_ query: String) async throws -> [City] {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            waiter?.resume(); waiter = nil
        }
    }
    func waitForRequest() async {
        if continuation != nil { return }
        await withCheckedContinuation { waiter = $0 }
    }
    func complete(with cities: [City]) { continuation?.resume(returning: cities); continuation = nil }
}
