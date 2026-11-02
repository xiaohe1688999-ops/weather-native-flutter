package dev.weather.nativehost

import android.content.Context
import android.os.Bundle
import dev.weather.model.Location
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONException
import org.json.JSONObject
import java.util.UUID

internal class WeatherActivity : FlutterActivity() {
    private var bridge: MethodChannel? = null
    private var sessionId = ""
    private var city: Location? = null
    private var reported = false
    private var closed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        sessionId = savedInstanceState?.getString("session") ?: UUID.randomUUID().toString()
        reported = savedInstanceState?.getBoolean("reported") ?: false
        city = parseCity(savedInstanceState?.getString(CITY) ?: intent.getStringExtra(CITY))
        super.onCreate(savedInstanceState)
    }

    // 在 FlutterActivity 启动新引擎的 Dart 入口前注册通道处理器。
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.weather/host").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (closed) { result.error("closed", "Session closed", null); return@setMethodCallHandler }
                when (call.method) {
                    "getLaunchContext" -> result.success(mapOf("protocolVersion" to 1,
                        "sessionId" to sessionId, "location" to city?.toMap()))
                    "weatherLoaded" -> {
                        if (call.argument<String>("sessionId") != sessionId || city == null) {
                            result.error("session", "Invalid session", null)
                        } else {
                            if (!reported) {
                                (application as WeatherApplication).recentCities.record(city!!)
                                reported = true
                            }
                            result.success(null)
                        }
                    }
                    "closeWeather" -> {
                        val requested = call.argument<String>("sessionId")
                        if (requested != null && requested != sessionId) result.error("session", "Invalid session", null)
                        else { result.success(null); closed = true; finish() }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putString("session", sessionId)
        outState.putBoolean("reported", reported)
        outState.putString(CITY, city?.let { JSONObject(it.toMap()).toString() })
        super.onSaveInstanceState(outState)
    }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        closed = true
        bridge?.setMethodCallHandler(null)
        bridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
    override fun shouldDestroyEngineWithHost(): Boolean = true

    private fun parseCity(raw: String?): Location? = try {
        val value = JSONObject(raw ?: "{}")
        Location(value.getInt("id"), value.getString("name"), value.getDouble("latitude"),
            value.getDouble("longitude"), value.optString("admin1"), value.optString("country"))
    } catch (_: JSONException) { null } catch (_: IllegalArgumentException) { null }

    companion object { const val CITY = "city" }
}
