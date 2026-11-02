package dev.weather.data

import android.content.Context
import dev.weather.model.Location
import dev.weather.model.recentCities
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

public class RecentCitiesStore(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences("recent_cities", Context.MODE_PRIVATE)
    private val mutableCities = MutableStateFlow(read())
    public val cities: StateFlow<List<Location>> = mutableCities.asStateFlow()

    public fun record(location: Location) {
        val updated = recentCities(mutableCities.value, location)
        preferences.edit().putString("cities", JSONArray(updated.map { JSONObject(it.toMap()) }).toString()).apply()
        mutableCities.value = updated
    }

    private fun read(): List<Location> = try {
        val array = JSONArray(preferences.getString("cities", "[]"))
        List(array.length()) { locationFromJson(array.getJSONObject(it)) }.distinctBy(Location::id).take(5)
    } catch (_: JSONException) { emptyList() }
      catch (_: IllegalArgumentException) { emptyList() }
}
