package dev.weather.data

import org.junit.Assert.*
import org.junit.Test

class LocationParserTest {
    @Test fun `empty result and optional admin handled`() {
        assertTrue(parseLocations("{}").isEmpty())
        val cities = parseLocations("""{"results":[{"id":1,"name":"上海","latitude":31.2,"longitude":121.4}]}""")
        assertEquals("上海", cities.single().name)
        assertEquals("", cities.single().admin1)
    }
    @Test(expected = IllegalArgumentException::class)
    fun `bad coordinates fail instead of opening invalid city`() {
        parseLocations("""{"results":[{"id":1,"name":"X","latitude":100,"longitude":0}]}""")
    }
}
