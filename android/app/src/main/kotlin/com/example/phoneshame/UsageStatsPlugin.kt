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
        Log.d(TAG, "Final app count: ${usageMap.size}")
        usageMap.forEach { (pkg, ms) -> Log.d(TAG, "  $pkg → ${ms/60000} min") }

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

    /**
     * Builds usage map by replaying events.
     *
     * Two parallel trackers:
     *  1. activityUsage — MOVE_TO_FOREGROUND / MOVE_TO_BACKGROUND sessions.
     *     Sessions are closed on SCREEN_NON_INTERACTIVE to prevent screen-off inflation.
     *
     *  2. serviceUsage — FOREGROUND_SERVICE_START / STOP sessions, intersected with
     *     screen-on intervals. This captures apps like Prime Video that move their
     *     activity to background immediately but run video in a foreground service.
     *
     * Final per-app time = max(activityUsage, serviceUsage).
     */
    private fun buildUsageMap(
        usm: UsageStatsManager,
        startTime: Long,
        endTime: Long,
        homePackages: Set<String>
    ): Map<String, Long> {
        // ── State ─────────────────────────────────────────────────────────────
        val activityUsage  = mutableMapOf<String, Long>()
        val activityStarts = mutableMapOf<String, Long>()

        // service sessions: pkg → list of (sessionStart, sessionEnd)
        val serviceSessions = mutableMapOf<String, MutableList<Pair<Long, Long>>>()
        val serviceStarts   = mutableMapOf<String, Long>()

        // screen-on intervals
        val screenOnIntervals = mutableListOf<Pair<Long, Long>>()
        var screenOnStart = startTime   // assume screen starts on at day start
        var screenOn      = true

        // ── Replay events ─────────────────────────────────────────────────────
        val events = usm.queryEvents(startTime, endTime)
        val event  = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val t   = event.timeStamp
            val pkg = event.packageName

            when (event.eventType) {

                // Screen off — close activity sessions + record screen-on interval
                UsageEvents.Event.SCREEN_NON_INTERACTIVE,
                EVENT_DEVICE_SHUTDOWN -> {
                    if (screenOn) {
                        screenOn = false
                        closeAll(activityStarts, activityUsage, t)
                        if (t > screenOnStart) screenOnIntervals += Pair(screenOnStart, t)
                    }
                }

                // Screen on — mark start of new screen-on interval
                UsageEvents.Event.SCREEN_INTERACTIVE -> {
                    if (!screenOn) {
                        screenOn      = true
                        screenOnStart = t
                    }
                }

                // Activity foreground
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    if (pkg != null && isTrackableApp(pkg, homePackages)) {
                        if (!screenOn) { screenOn = true; screenOnStart = t }
                        activityStarts.putIfAbsent(pkg, t)
                    }
                }

                // Activity background
                UsageEvents.Event.MOVE_TO_BACKGROUND,
                EVENT_ACTIVITY_STOPPED -> {
                    if (pkg != null) closeOne(pkg, activityStarts, activityUsage, t)
                }

                // Foreground service started (e.g. Prime Video video player)
                EVENT_FOREGROUND_SERVICE_START -> {
                    if (pkg != null && isTrackableApp(pkg, homePackages)) {
                        serviceStarts.putIfAbsent(pkg, t)
                    }
                }

                // Foreground service stopped
                EVENT_FOREGROUND_SERVICE_STOP -> {
                    if (pkg != null) {
                        val start = serviceStarts.remove(pkg)
                        if (start != null) {
                            serviceSessions.getOrPut(pkg) { mutableListOf() } += Pair(start, t)
                        }
                    }
                }
            }
        }

        // Close still-open activity sessions
        if (screenOn) {
            closeAll(activityStarts, activityUsage, endTime)
            screenOnIntervals += Pair(screenOnStart, endTime)
        }

        // Close still-running services
        for ((pkg, start) in serviceStarts) {
            serviceSessions.getOrPut(pkg) { mutableListOf() } += Pair(start, endTime)
        }

        // ── Compute visible service time ───────────────────────────────────────
        // Intersect each service session with screen-on intervals so we only
        // count time the user was actually looking at the screen.
        val serviceUsage = mutableMapOf<String, Long>()
        for ((pkg, sessions) in serviceSessions) {
            var total = 0L
            for ((sStart, sEnd) in sessions) {
                for ((scrStart, scrEnd) in screenOnIntervals) {
                    val lo = maxOf(sStart, scrStart)
                    val hi = minOf(sEnd,   scrEnd)
                    if (hi > lo) total += hi - lo
                }
            }
            if (total > 0) serviceUsage[pkg] = total
        }

        Log.d(TAG, "Activity tracked: ${activityUsage.size}, Service tracked: ${serviceUsage.size}")

        // ── Merge: per-app = max(activity, service) ───────────────────────────
        val merged = mutableMapOf<String, Long>()
        for (pkg in activityUsage.keys + serviceUsage.keys) {
            merged[pkg] = maxOf(activityUsage[pkg] ?: 0L, serviceUsage[pkg] ?: 0L)
        }
        return merged
    }

    // ── Session helpers ───────────────────────────────────────────────────────

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

    // ── Misc ─────────────────────────────────────────────────────────────────

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
