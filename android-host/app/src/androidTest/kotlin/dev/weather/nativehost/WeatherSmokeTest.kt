package dev.weather.nativehost

import android.content.Intent
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class WeatherSmokeTest {
    @Test fun nativeSearchFlutterWeatherAndReturn() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val device = UiDevice.getInstance(instrumentation)
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)!!
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        context.startActivity(launch)
        val search = device.wait(Until.findObject(By.res("citySearch")), 45_000)
        assertNotNull("Native search field missing", search)
        search.text = "Shanghai"
        val city = device.wait(Until.findObject(By.res("city-1796236")), 25_000)
        assertNotNull("Requires working Open-Meteo connection", city)
        // Compose may replace the result node while the keyboard/layout settles.
        device.waitForIdle()
        device.findObject(By.res("city-1796236")).click()
        // Flutter 在 Android 上通过无障碍描述暴露不可编辑的 Text 文本。
        assertTrue(device.wait(Until.hasObject(By.descContains("当前天气")), 35_000))
        val forecastVisible = showForecast(device)
        device.executeShellCommand("screencap -p /sdcard/weather-flutter.png")
        assertTrue("Flutter forecast not visible", forecastVisible)
        try {
            device.setOrientationLeft()
            assertTrue(showForecast(device))
            device.setOrientationNatural()
        } finally { device.unfreezeRotation() }
        device.pressBack()
        assertTrue(device.wait(Until.hasObject(By.res("citySearch")), 10_000))
        device.findObject(By.res("citySearch")).text = ""
        assertTrue(device.wait(Until.hasObject(By.text("最近查看")), 5_000))
        assertTrue(device.hasObject(By.res("city-1796236")))
        device.findObject(By.res("city-1796236")).click()
        val reopened = device.wait(Until.hasObject(By.descContains("当前天气")), 35_000)
        device.executeShellCommand("screencap -p /sdcard/weather-reopened.png")
        assertTrue("Reopened engine did not load weather", reopened)
        device.pressBack()
    }

    private fun showForecast(device: UiDevice): Boolean {
        repeat(5) {
            if (device.wait(Until.hasObject(By.descContains("未来 7 天")), 2_000)) return true
            device.swipe(device.displayWidth / 2, device.displayHeight * 4 / 5,
                device.displayWidth / 2, device.displayHeight / 3, 30)
        }
        return false
    }
}
