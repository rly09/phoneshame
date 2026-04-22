package com.example.phoneshame

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class UsageStatsPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "com.phoneshame/usage_stats"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "getTodayUsage") {
            try {
                val usageData = getTodayUsage()
                result.success(usageData)
            } catch (e: Exception) {
                result.error("ERROR", e.message, null)
            }
        } else if (call.method == "checkPermission") {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), context.packageName)
            } else {
                appOps.checkOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), context.packageName)
            }
            result.success(mode == android.app.AppOpsManager.MODE_ALLOWED)
        } else if (call.method == "requestUsageAccess") {
            val intent = Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.data = android.net.Uri.parse("package:" + context.packageName)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            try {
                context.startActivity(intent)
                result.success(true)
            } catch (e: Exception) {
                // If opening with package fails, open general usage settings
                val fallbackIntent = Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
                fallbackIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                try {
                    context.startActivity(fallbackIntent)
                    result.success(true)
                } catch (fallbackEx: Exception) {
                     result.success(false)
                }
            }
        } else {
            result.notImplemented()
        }
    }

    private fun getTodayUsage(): List<Map<String, Any>> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = context.packageManager

        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val appUsageMap = mutableMapOf<String, Long>()
        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        val event = android.app.usage.UsageEvents.Event()
        var activePackage: String? = null
        var activeStartTime = 0L

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            val packageName = event.packageName ?: continue

            if (isForegroundEvent(event.eventType)) {
                if (activePackage != null && activeStartTime > 0L && event.timeStamp > activeStartTime) {
                    val session = event.timeStamp - activeStartTime
                    appUsageMap[activePackage!!] = (appUsageMap[activePackage!!] ?: 0L) + session
                }
                activePackage = packageName
                activeStartTime = event.timeStamp
            } else if (isBackgroundEvent(event.eventType)) {
                if (activePackage == packageName && activeStartTime > 0L && event.timeStamp > activeStartTime) {
                    val session = event.timeStamp - activeStartTime
                    appUsageMap[packageName] = (appUsageMap[packageName] ?: 0L) + session
                    activePackage = null
                    activeStartTime = 0L
                }
            }
        }

        if (activePackage != null && activeStartTime > 0L && endTime > activeStartTime) {
            val session = endTime - activeStartTime
            appUsageMap[activePackage!!] = (appUsageMap[activePackage!!] ?: 0L) + session
        }

        val resultList = mutableListOf<Map<String, Any>>()

        for ((packageName, totalTimeMs) in appUsageMap) {
            // Filter launchable user apps
            val launchIntent = pm.getLaunchIntentForPackage(packageName)
            if (launchIntent != null && packageName != context.packageName) {
                val appName = try {
                    val appInfo = pm.getApplicationInfo(packageName, 0)
                    pm.getApplicationLabel(appInfo).toString()
                } catch (e: PackageManager.NameNotFoundException) {
                    packageName
                }
                
                val timeInMinutes = totalTimeMs / (1000 * 60)
                if (timeInMinutes > 0) {
                    resultList.add(
                        mapOf(
                            "appName" to appName,
                            "packageName" to packageName,
                            "totalTimeInMinutes" to timeInMinutes
                        )
                    )
                }
            }
        }

        // Sort descending
        resultList.sortByDescending { (it["totalTimeInMinutes"] as Long) }

        return resultList
    }

    private fun isForegroundEvent(eventType: Int): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED ||
                eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND
        } else {
            eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND
        }
    }

    private fun isBackgroundEvent(eventType: Int): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            eventType == android.app.usage.UsageEvents.Event.ACTIVITY_PAUSED ||
                eventType == android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND
        } else {
            eventType == android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND
        }
    }
}
