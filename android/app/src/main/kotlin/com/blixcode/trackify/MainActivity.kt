package com.blixcode.trackify

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val smsExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "queryInbox" -> {
                        val since = call.argument<Number>("sinceMillis")?.toLong() ?: 0L
                        val limit = call.argument<Int>("limit") ?: 5000
                        queryInbox(since, limit, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Reads inbox SMS newer than [since] off the main thread. Only the four
     * columns the app needs are requested, each with its proper type, so OEM
     * providers that add odd extra columns cannot break the read.
     */
    private fun queryInbox(since: Long, limit: Int, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("permission_denied", "READ_SMS is not granted", null)
            return
        }
        smsExecutor.execute {
            try {
                val rows = ArrayList<Map<String, Any?>>()
                contentResolver.query(
                    Uri.parse("content://sms/inbox"),
                    arrayOf("_id", "address", "body", "date"),
                    "date > ?",
                    arrayOf(since.toString()),
                    "date DESC",
                )?.use { c ->
                    val idCol = c.getColumnIndexOrThrow("_id")
                    val addrCol = c.getColumnIndexOrThrow("address")
                    val bodyCol = c.getColumnIndexOrThrow("body")
                    val dateCol = c.getColumnIndexOrThrow("date")
                    while (c.moveToNext() && rows.size < limit) {
                        rows.add(
                            mapOf(
                                "id" to c.getLong(idCol),
                                "address" to c.getString(addrCol),
                                "body" to c.getString(bodyCol),
                                "date" to c.getLong(dateCol),
                            )
                        )
                    }
                }
                mainHandler.post { result.success(rows) }
            } catch (e: Exception) {
                mainHandler.post { result.error("query_failed", e.message, null) }
            }
        }
    }

    override fun onDestroy() {
        smsExecutor.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val SMS_CHANNEL = "com.blixcode.trackify/sms"
    }
}
