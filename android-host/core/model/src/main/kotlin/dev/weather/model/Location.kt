package dev.weather.model

public data class Location(
    val id: Int,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val admin1: String = "",
    val country: String = "",
) {
    init {
        require(name.isNotBlank())
        require(latitude.isFinite() && latitude in -90.0..90.0)
        require(longitude.isFinite() && longitude in -180.0..180.0)
    }

    public val subtitle: String get() = listOf(admin1, country).filter(String::isNotBlank).joinToString(" · ")
    public fun toMap(): Map<String, Any> = mapOf(
        "id" to id, "name" to name, "latitude" to latitude,
        "longitude" to longitude, "admin1" to admin1, "country" to country,
    )
}

public fun recentCities(previous: List<Location>, selected: Location): List<Location> =
    (listOf(selected) + previous).distinctBy(Location::id).take(5)
