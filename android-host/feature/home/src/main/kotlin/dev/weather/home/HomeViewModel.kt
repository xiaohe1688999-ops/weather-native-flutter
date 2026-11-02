package dev.weather.home

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dev.weather.data.LocationRepository
import dev.weather.model.Location
import java.io.IOException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

internal data class SearchState(
    val query: String = "",
    val loading: Boolean = false,
    val results: List<Location> = emptyList(),
    val error: String? = null,
    val searched: Boolean = false,
)

internal class HomeViewModel(
    private val repository: LocationRepository,
    private val savedState: SavedStateHandle,
) : ViewModel() {
    private val mutableState = MutableStateFlow(SearchState(query = savedState["query"] ?: ""))
    val state = mutableState.asStateFlow()
    private var searchJob: Job? = null
    private var generation = 0

    fun search(query: String, immediately: Boolean = false) {
        savedState["query"] = query
        searchJob?.cancel()
        val requestId = ++generation
        mutableState.value = SearchState(query = query)
        if (query.trim().length < 2) return
        mutableState.value = SearchState(query = query, loading = true)
        searchJob = viewModelScope.launch {
            if (!immediately) delay(300)
            try {
                val locations = repository.search(query)
                if (requestId == generation) mutableState.value = SearchState(query = query, results = locations, searched = true)
            } catch (error: IOException) {
                if (requestId == generation) mutableState.value = SearchState(query = query, error = error.message ?: "网络异常，请重试")
            }
        }
    }
}
