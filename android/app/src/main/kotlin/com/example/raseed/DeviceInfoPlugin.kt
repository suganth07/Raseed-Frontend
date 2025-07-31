package com.example.raseed

import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class DeviceInfoPlugin {
    companion object {
        private const val CHANNEL = "raseed.com/device_info"
        
        fun registerWith(flutterEngine: FlutterEngine) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceInfo" -> {
                        val deviceInfo = mapOf(
                            "sdkInt" to Build.VERSION.SDK_INT,
                            "model" to Build.MODEL,
                            "manufacturer" to Build.MANUFACTURER,
                            "brand" to Build.BRAND,
                            "device" to Build.DEVICE,
                            "androidVersion" to Build.VERSION.RELEASE
                        )
                        result.success(deviceInfo)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }
}
