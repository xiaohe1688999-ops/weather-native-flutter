package dev.weather.data

import dev.weather.model.Location
import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.HttpUrl.Companion.toHttpUrl
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

public interface LocationRepository {
    public suspend fun search(query: String): List<Location>
}

public fun createLocationRepository(): LocationRepository = OpenMeteoLocationRepository()

internal class OpenMeteoLocationRepository : LocationRepository {
    private val client = OkHttpClient.Builder().callTimeout(15, TimeUnit.SECONDS).build()
    override suspend fun search(query: String): List<Location> {
        val url = "https://geocoding-api.open-meteo.com/v1/search".toHttpUrl().newBuilder()
            .addQueryParameter("name", query.trim()).addQueryParameter("count", "10")
            .addQueryParameter("language", "zh").addQueryParameter("format", "json").build()
        return suspendCancellableCoroutine { continuation ->
            val call = client.newCall(Request.Builder().url(url).build())
            continuation.invokeOnCancellation { call.cancel() }
            call.enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    if (continuation.isActive) continuation.resumeWithException(e)
                }
                override fun onResponse(call: Call, response: Response) {
                    response.use {
                        if (!continuation.isActive) return
                        try {
                            if (!it.isSuccessful) throw IOException(if (it.code == 429) "请求过于频繁，请稍后重试" else "地点服务暂不可用")
                            val body = it.body?.string() ?: throw IOException("地点服务返回空数据")
                            continuation.resume(parseLocations(body))
                        } catch (error: IOException) {
                            continuation.resumeWithException(error)
                        } catch (error: JSONException) {
                            continuation.resumeWithException(IOException("地点数据格式异常", error))
                        } catch (error: IllegalArgumentException) {
                            continuation.resumeWithException(IOException("地点坐标无效", error))
                        }
                    }
                }
            })
        }
    }
}

internal fun parseLocations(body: String): List<Location> {
    val root = JSONObject(body)
    if (root.optBoolean("error")) throw IOException("地点服务返回错误")
    val items = root.optJSONArray("results") ?: return emptyList()
    return List(items.length()) { index -> locationFromJson(items.getJSONObject(index)) }
}

internal fun locationFromJson(json: JSONObject): Location = Location(
    id = json.getInt("id"), name = json.getString("name"),
    latitude = json.getDouble("latitude"), longitude = json.getDouble("longitude"),
    admin1 = json.optString("admin1", ""), country = json.optString("country", ""),
)
