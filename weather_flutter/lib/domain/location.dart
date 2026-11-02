class Location {
  const Location({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1 = '',
    this.country = '',
  });
  final int id;
  final String name;
  final double latitude, longitude;
  final String admin1, country;

  factory Location.fromMap(Map<Object?, Object?> map) {
    final id = map['id'];
    final name = map['name'];
    final lat = map['latitude'];
    final lon = map['longitude'];
    if (id is! int ||
        name is! String ||
        name.trim().isEmpty ||
        lat is! num ||
        lon is! num ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      throw const FormatException('城市参数不完整');
    }
    return Location(
      id: id,
      name: name,
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      admin1: map['admin1'] as String? ?? '',
      country: map['country'] as String? ?? '',
    );
  }
  String get subtitle =>
      [admin1, country].where((s) => s.isNotEmpty).join(' · ');
}

class LaunchContext {
  const LaunchContext({required this.sessionId, required this.location});
  final String sessionId;
  final Location location;
  factory LaunchContext.fromMap(Map<Object?, Object?> map) {
    if (map['protocolVersion'] != 1 ||
        map['sessionId'] is! String ||
        (map['sessionId'] as String).isEmpty ||
        map['location'] is! Map) {
      throw const FormatException('不支持的宿主协议或城市参数');
    }
    return LaunchContext(
      sessionId: map['sessionId'] as String,
      location: Location.fromMap(
        Map<Object?, Object?>.from(map['location'] as Map),
      ),
    );
  }
}
