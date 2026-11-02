package dev.weather.nativehost

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import dev.weather.home.HomeRoute
import org.json.JSONObject

internal class MainActivity : ComponentActivity() {
    private var opening = false
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val container = application as WeatherApplication
        setContent {
            HomeRoute(container.locations, container.recentCities) { city ->
                if (!opening) {
                    opening = true
                    startActivity(Intent(this, WeatherActivity::class.java)
                        .putExtra(WeatherActivity.CITY, JSONObject(city.toMap()).toString()))
                }
            }
        }
    }
    override fun onResume() { super.onResume(); opening = false }
}
