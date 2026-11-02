package dev.weather.nativehost

import android.app.Application
import dev.weather.data.RecentCitiesStore
import dev.weather.data.createLocationRepository

internal class WeatherApplication : Application() {
    val locations by lazy { createLocationRepository() }
    val recentCities by lazy { RecentCitiesStore(this) }
}
