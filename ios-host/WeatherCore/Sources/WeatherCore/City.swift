import Foundation

public struct City: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let admin1: String?
    public let country: String?

    public init(id: Int, name: String, latitude: Double, longitude: Double, admin1: String? = nil, country: String? = nil) {
        self.id = id; self.name = name; self.latitude = latitude; self.longitude = longitude
        self.admin1 = admin1; self.country = country
    }
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
    public var subtitle: String { [admin1, country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ") }
    public var channelMap: [String: Any] {
        ["id": id, "name": name, "latitude": latitude, "longitude": longitude,
         "admin1": admin1 ?? "", "country": country ?? ""]
    }
}

public enum RecentCities {
    public static func adding(_ city: City, to previous: [City]) -> [City] {
        var seen = Set<Int>()
        return Array(([city] + previous).filter { $0.isValid && seen.insert($0.id).inserted }.prefix(5))
    }
}
