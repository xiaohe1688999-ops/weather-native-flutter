import Foundation
import Combine

@MainActor
public final class HomeModel: ObservableObject {
    @Published public private(set) var query = ""
    @Published public private(set) var cities: [City] = []
    @Published public private(set) var recent: [City] = []
    @Published public private(set) var loading = false
    @Published public private(set) var searched = false
    @Published public private(set) var error: String?
    private let repository: any CityRepository
    private let defaults: UserDefaults
    private var task: Task<Void, Never>?
    private var generation = 0

    public init(repository: any CityRepository = OpenMeteoCityRepository(), defaults: UserDefaults = .standard) {
        self.repository = repository; self.defaults = defaults
        if let data = defaults.data(forKey: "recentCities"), let cities = try? JSONDecoder().decode([City].self, from: data) {
            var seen = Set<Int>()
            recent = Array(cities.filter { $0.isValid && seen.insert($0.id).inserted }.prefix(5))
        }
    }
    deinit { task?.cancel() }

    public func search(_ text: String, immediately: Bool = false) {
        task?.cancel(); generation += 1
        let requestID = generation
        query = text; cities = []; error = nil; searched = false; loading = false
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return }
        loading = true
        let repository = self.repository
        task = Task { [weak self] in
            do {
                if !immediately { try await Task.sleep(nanoseconds: 300_000_000) }
                let result = try await repository.search(text)
                guard !Task.isCancelled, let self, requestID == self.generation else { return }
                self.cities = result; self.loading = false; self.searched = true
            } catch {
                guard !Task.isCancelled, let self, requestID == self.generation else { return }
                self.loading = false
                if let error = error as? CityServiceError { self.error = error.localizedDescription }
                else if let error = error as? URLError, error.code == .timedOut { self.error = "请求超时，请重试" }
                else { self.error = "网络连接失败，请检查网络后重试" }
            }
        }
    }

    public func record(_ city: City) {
        recent = RecentCities.adding(city, to: recent)
        defaults.set(try? JSONEncoder().encode(recent), forKey: "recentCities")
    }
}
