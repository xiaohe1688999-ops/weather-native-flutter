package dev.weather.home

import androidx.lifecycle.SavedStateHandle
import dev.weather.data.LocationRepository
import dev.weather.model.Location
import java.io.IOException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.Assert.*
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class HomeViewModelTest {
    @Test fun `debounce cancels previous search and retry recovers failure`() = runTest {
        Dispatchers.setMain(StandardTestDispatcher(testScheduler))
        try {
            val queries = mutableListOf<String>()
            var failing = true
            val repository = object : LocationRepository {
                override suspend fun search(query: String): List<Location> {
                    queries += query
                    if (failing) throw IOException("offline")
                    return listOf(Location(1, "上海", 31.0, 121.0))
                }
            }
            val saved = SavedStateHandle()
            val model = HomeViewModel(repository, saved)
            model.search("Sh"); advanceTimeBy(100); model.search("Shanghai"); advanceUntilIdle()
            assertEquals(listOf("Shanghai"), queries)
            assertEquals("offline", model.state.value.error)
            failing = false
            model.search("Shanghai", immediately = true); advanceUntilIdle()
            assertEquals("上海", model.state.value.results.single().name)
            assertNull(model.state.value.error)
            assertEquals("Shanghai", saved.get<String>("query"))
            model.search(""); advanceUntilIdle()
            assertFalse(model.state.value.loading)
            assertTrue(model.state.value.results.isEmpty())
        } finally { Dispatchers.resetMain() }
    }
}
