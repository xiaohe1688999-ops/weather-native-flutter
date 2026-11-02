package dev.weather.model

import org.junit.Assert.*
import org.junit.Test

class RecentCitiesTest {
    private fun city(id: Int) = Location(id, "城市$id", 31.0, 121.0)
    @Test fun `deduplicate move to front and keep five`() {
        val original = (1..5).map(::city)
        assertEquals(listOf(3, 1, 2, 4, 5), recentCities(original, city(3)).map(Location::id))
        assertEquals(listOf(6, 1, 2, 3, 4), recentCities(original, city(6)).map(Location::id))
    }
    @Test(expected = IllegalArgumentException::class)
    fun `invalid coordinates rejected`() { Location(1, "Invalid", Double.NaN, 0.0) }
}
