package com.example.phoneshame

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import android.util.Log

class RotWidgetWorker(
    private val appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    companion object {
        const val TAG = "RotWidgetWorker"
    }

    override suspend fun doWork(): Result {
        Log.d(TAG, "Doing periodic native widget update...")
        try {
            val usageData = UsageStatsHelper.getTodayUsage(appContext)
            
            var totalMinutes = 0L
            var topApp = "No data yet"
            var topMinutes = 0L

            for (app in usageData) {
                val mins = app["totalTimeInMinutes"] as Long
                totalMinutes += mins
            }

            if (usageData.isNotEmpty()) {
                topApp = usageData.first()["appName"] as String
                topMinutes = usageData.first()["totalTimeInMinutes"] as Long
            }

            val score = UsageStatsHelper.calculateRotScore(totalMinutes)

            val prefs = appContext.getSharedPreferences(HomeWidgetBridge.PREFS_NAME, Context.MODE_PRIVATE)
            val editor = prefs.edit()

            editor.putInt(HomeWidgetBridge.KEY_TOTAL_MINUTES, totalMinutes.toInt())
            editor.putString(HomeWidgetBridge.KEY_TOTAL_TIME_LABEL, UsageStatsHelper.formatMinutesToHours(totalMinutes))
            editor.putInt(HomeWidgetBridge.KEY_SCORE, score)
            editor.putString(HomeWidgetBridge.KEY_TOP_APP, topApp)
            editor.putInt(HomeWidgetBridge.KEY_TOP_MINUTES, topMinutes.toInt())
            editor.putString(HomeWidgetBridge.KEY_TOP_TIME_LABEL, UsageStatsHelper.formatMinutesToHours(topMinutes))
            editor.putInt(HomeWidgetBridge.KEY_TRACKED_APPS_COUNT, usageData.size)
            editor.putLong(HomeWidgetBridge.KEY_UPDATED_AT_MS, System.currentTimeMillis())
            editor.putBoolean(HomeWidgetBridge.KEY_HAS_DATA, usageData.isNotEmpty())
            editor.apply()

            // Trigger UI update
            RotHomeWidgetProvider.updateAll(appContext)
            try {
                RotHomeWidgetSmallProvider.updateAll(appContext)
            } catch (e: Exception) {
                // Ignore if class not yet implemented
            }

            Log.d(TAG, "Periodic native widget update SUCCESS. Total minutes: \$totalMinutes")
            return Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Periodic native widget update FAILED", e)
            return Result.failure()
        }
    }
}
