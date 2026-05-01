package com.example.phoneshame

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Build
import android.util.Log
import java.util.Calendar

object UsageStatsHelper {
    private const val TAG = "PhoneShameHelper"
    private const val EVENT_ACTIVITY_STOPPED         = 23
    private const val EVENT_DEVICE_SHUTDOWN          = 26
    private const val EVENT_FOREGROUND_SERVICE_START = 19
    private const val EVENT_FOREGROUND_SERVICE_STOP  = 20

    fun getTodayUsage(context: Context): List<Map<String, Any>> {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm  = context.packageManager
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0);      set(Calendar.MILLISECOND, 0)
        }
        val startTime    = calendar.timeInMillis
        val endTime      = System.currentTimeMillis()
        val homePackages = getHomePackages(pm)

        val usageMap = buildUsageMap(usm, startTime, endTime, homePackages)

        val result = mutableListOf<Map<String, Any>>()
        for ((pkg, ms) in usageMap) {
            if (ms < 1_000L) continue
            result.add(mapOf(
                "appName"            to getAppLabel(pm, pkg),
                "packageName"        to pkg,
                "totalTimeInMinutes" to (ms / 60_000L)
            ))
        }
        result.sortByDescending { it["totalTimeInMinutes"] as Long }
        return result
    }

    fun calculateRotScore(totalMinutes: Long): Int {
        return when {
            totalMinutes <= 120 -> ((totalMinutes / 120.0) * 200).toInt()
            totalMinutes <= 240 -> {
                val additional = totalMinutes - 120
                200 + ((additional / 120.0) * 300).toInt()
            }
            totalMinutes <= 360 -> {
                val additional = totalMinutes - 240
                500 + ((additional / 120.0) * 300).toInt()
            }
            else -> {
                val additional = totalMinutes - 360
                val score = 800 + ((additional / 120.0) * 200).toInt()
                if (score > 1000) 1000 else score
            }
        }
    }

    fun formatMinutesToHours(totalMinutes: Long): String {
        if (totalMinutes < 60) return "${totalMinutes}m"
        val h = totalMinutes / 60
        val m = totalMinutes % 60
        return if (m == 0L) "${h}h" else "${h}h ${m}m"
    }

    private fun buildUsageMap(
        usm: UsageStatsManager,
        startTime: Long,
        endTime: Long,
        homePackages: Set<String>
    ): Map<String, Long> {
        val activityUsage  = mutableMapOf<String, Long>()
        val activityStarts = mutableMapOf<String, Long>()

        val screenOnIntervals = mutableListOf<Pair<Long, Long>>()
        var screenOnStart = startTime
        var screenOn      = true

        val events = usm.queryEvents(startTime, endTime)
        val event  = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val t   = event.timeStamp
            val pkg = event.packageName

            when (event.eventType) {
                UsageEvents.Event.SCREEN_NON_INTERACTIVE,
                EVENT_DEVICE_SHUTDOWN -> {
                    if (screenOn) {
                        screenOn = false
                        closeAll(activityStarts, activityUsage, t)
                        if (t > screenOnStart) screenOnIntervals += Pair(screenOnStart, t)
                    }
                }
                UsageEvents.Event.SCREEN_INTERACTIVE -> {
                    if (!screenOn) {
                        screenOn      = true
                        screenOnStart = t
                    }
                }
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    if (pkg != null && isTrackableApp(pkg, homePackages)) {
                        if (!screenOn) { screenOn = true; screenOnStart = t }
                        activityStarts.putIfAbsent(pkg, t)
                    }
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND,
                EVENT_ACTIVITY_STOPPED -> {
                    if (pkg != null) closeOne(pkg, activityStarts, activityUsage, t)
                }
            }
        }

        if (screenOn) {
            closeAll(activityStarts, activityUsage, endTime)
            screenOnIntervals += Pair(screenOnStart, endTime)
        }

        return activityUsage
    }

    private fun closeOne(pkg: String, starts: MutableMap<String, Long>,
                          usage: MutableMap<String, Long>, at: Long) {
        val s = starts.remove(pkg) ?: return
        if (at > s) usage[pkg] = (usage[pkg] ?: 0L) + (at - s)
    }

    private fun closeAll(starts: MutableMap<String, Long>,
                          usage: MutableMap<String, Long>, at: Long) {
        for ((pkg, s) in starts) if (at > s) usage[pkg] = (usage[pkg] ?: 0L) + (at - s)
        starts.clear()
    }

    private fun getAppLabel(pm: PackageManager, pkg: String): String = try {
        val ai = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            pm.getApplicationInfo(pkg, PackageManager.ApplicationInfoFlags.of(
                PackageManager.MATCH_UNINSTALLED_PACKAGES.toLong()))
        else @Suppress("DEPRECATION")
            pm.getApplicationInfo(pkg, PackageManager.MATCH_UNINSTALLED_PACKAGES)
        pm.getApplicationLabel(ai).toString()
    } catch (e: PackageManager.NameNotFoundException) {
        pkg.substringAfterLast('.').replaceFirstChar { it.uppercase() }.ifEmpty { pkg }
    }

    private fun getHomePackages(pm: PackageManager): Set<String> {
        val intent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_HOME) }
        val list: List<ResolveInfo> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
        else @Suppress("DEPRECATION") pm.queryIntentActivities(intent, 0)
        return list.mapNotNull { it.activityInfo?.packageName }.toSet()
    }

    private fun isTrackableApp(pkg: String, homePackages: Set<String>): Boolean {
        if (homePackages.contains(pkg)) return false
        val blocked = listOf("android", "com.android.systemui", "com.android.phone",
            "com.android.server", "com.android.launcher",
            "com.google.android.inputmethod", "com.google.android.gms",
            "com.google.android.gsf", "com.google.android.ext",
            "com.samsung.android.honeyboard", "com.samsung.android.app.cocktailbarservice",
            "com.samsung.android.app.spage", "com.sec.android.inputmethod",
            "com.miui.securitycenter", "com.miui.daemon", "com.qualcomm.location")
        return blocked.none { pkg == it || pkg.startsWith("$it.") }
    }
}
