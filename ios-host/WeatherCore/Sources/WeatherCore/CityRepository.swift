import Foundation

public protocol CityRepository: Sendable {
    func search(_ query: String) async throws -> [City]
}

public enum CityServiceError: Error, LocalizedError {
    case service(Int), invalidData
    public var errorDescription: String? {
        switch self {
        case .service(429): return "请求过于频繁，请稍后重试"
        case .service: return "地点服务暂不可用，请重试"
        case .invalidData: return "地点数据格式异常，请重试"
        }
    }
}

public struct OpenMeteoCityRepository: CityRepository {
    public init() {}
    public func search(_ query: String) async throws -> [City] {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [URLQueryItem(name: "name", value: query.trimmingCharacters(in: .whitespacesAndNewlines)),
            URLQueryItem(name: "count", value: "10"), URLQueryItem(name: "language", value: "zh"),
            URLQueryItem(name: "format", value: "json")]
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CityServiceError.invalidData }
        guard (200..<300).contains(http.statusCode) else { throw CityServiceError.service(http.statusCode) }
        return try Self.decode(data)
    }
    public static func decode(_ data: Data) throws -> [City] {
        struct Response: Decodable { let results: [City]?; let error: Bool? }
        do {
            let response = try JSONDecoder().decode(Response.self, from: data)
            guard response.error != true else { throw CityServiceError.invalidData }
            let cities = response.results ?? []
            guard cities.allSatisfy(\.isValid) else { throw CityServiceError.invalidData }
            return cities
        } catch { throw CityServiceError.invalidData }
    }
}
