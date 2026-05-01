package com.example.phoneshame

import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ResolveInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar

class UsageStatsPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "com.phoneshame/usage_stats"
        private const val TAG = "PhoneShame"
        private const val EVENT_ACTIVITY_STOPPED         = 23   // API 29
        private const val EVENT_DEVICE_SHUTDOWN          = 26   // API 29
        private const val EVENT_FOREGROUND_SERVICE_START = 19   // API 26
        private const val EVENT_FOREGROUND_SERVICE_STOP  = 20   // API 26
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getTodayUsage" -> {
                try { result.success(getTodayUsage()) }
                catch (e: Exception) { result.error("ERROR", e.message, null) }
            }
            "checkPermission" -> {
                val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
                val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    appOps.unsafeCheckOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                        android.os.Process.myUid(), context.packageName)
                } else {
                    appOps.checkOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                        android.os.Process.myUid(), context.packageName)
                }
                result.success(mode == android.app.AppOpsManager.MODE_ALLOWED)
            }
            "requestUsageAccess" -> {
                val intent = Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    data = android.net.Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                try { context.startActivity(intent); result.success(true) }
                catch (e: Exception) {
                    try {
                        context.startActivity(Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
                            .apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                        result.success(true)
                    } catch (fe: Exception) { result.success(false) }
                }
            }
            "getAppIcon" -> {
                val pkg = call.argument<String>("packageName") ?: ""
                try { result.success(getAppIconBytes(pkg)) }
                catch (e: Exception) { result.success(null) }
            }
            else -> result.notImplemented()
        }
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            val drawable = context.packageManager.getApplicationIcon(packageName)
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val w = drawable.intrinsicWidth.coerceAtLeast(1)
                val h = drawable.intrinsicHeight.coerceAtLeast(1)
                val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    private fun getTodayUsage(): List<Map<String, Any>> {
        return UsageStatsHelper.getTodayUsage(context)
    }
}
