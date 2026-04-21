package com.example.phoneshame

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
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

        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val appUsageMap = mutableMapOf<String, Long>()

        if (usageStatsList != null) {
            for (stats in usageStatsList) {
                val timeInForeground = stats.totalTimeInForeground
                if (timeInForeground > 0) {
                    val packageName = stats.packageName
                    appUsageMap[packageName] = (appUsageMap[packageName] ?: 0L) + timeInForeground
                }
            }
        }

        val resultList = mutableListOf<Map<String, Any>>()

        for ((packageName, totalTimeMs) in appUsageMap) {
            // Filter launchable user apps
            val launchIntent = pm.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
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
}
