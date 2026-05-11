package com.chevallierlepage.mariefrancops

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val prefs = getSharedPreferences("operations_records", Context.MODE_PRIVATE)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "marie_franc_ops/local_store"
        ).setMethodCallHandler { call, result ->
            val key = call.argument<String>("key")
            if (key.isNullOrBlank()) {
                result.error("bad_args", "Missing storage key", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "read" -> result.success(prefs.getString(key, null))
                "write" -> {
                    val value = call.argument<String>("value") ?: ""
                    prefs.edit().putString(key, value).apply()
                    result.success(null)
                }
                "clear" -> {
                    prefs.edit().remove(key).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
