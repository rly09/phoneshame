package com.example.phoneshame

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class HomeWidgetBridge(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "com.phoneshame/home_widget"
        const val PREFS_NAME = "rot_home_widget"
        const val KEY_TOTAL_MINUTES = "total_minutes"
        const val KEY_TOTAL_TIME_LABEL = "total_time_label"
        const val KEY_SCORE = "score"
        const val KEY_TOP_APP = "top_app"
        const val KEY_TOP_MINUTES = "top_minutes"
        const val KEY_TOP_TIME_LABEL = "top_time_label"
        const val KEY_TRACKED_APPS_COUNT = "tracked_apps_count"
        const val KEY_UPDATED_AT_MS = "updated_at_epoch_ms"
        const val KEY_HAS_DATA = "has_data"

        fun refreshWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, RotHomeWidgetProvider::class.java)
            val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (widgetIds.isEmpty()) return

            val updateIntent = Intent(context, RotHomeWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
            }
            context.sendBroadcast(updateIntent)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveWidgetData" -> {
                saveWidgetData(call.arguments as? Map<*, *>)
                result.success(null)
            }

            "refreshWidgets" -> {
                refreshWidgets(context)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun saveWidgetData(arguments: Map<*, *>?) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()

        editor.putInt(KEY_TOTAL_MINUTES, (arguments?.get("totalMinutes") as? Number)?.toInt() ?: 0)
        editor.putString(KEY_TOTAL_TIME_LABEL, arguments?.get("totalTimeLabel") as? String ?: "0m")
        editor.putInt(KEY_SCORE, (arguments?.get("score") as? Number)?.toInt() ?: 0)
        editor.putString(KEY_TOP_APP, arguments?.get("topApp") as? String ?: "No data yet")
        editor.putInt(KEY_TOP_MINUTES, (arguments?.get("topMinutes") as? Number)?.toInt() ?: 0)
        editor.putString(KEY_TOP_TIME_LABEL, arguments?.get("topTimeLabel") as? String ?: "0m")
        editor.putInt(
            KEY_TRACKED_APPS_COUNT,
            (arguments?.get("trackedAppsCount") as? Number)?.toInt() ?: 0
        )
        editor.putLong(
            KEY_UPDATED_AT_MS,
            (arguments?.get("updatedAtEpochMs") as? Number)?.toLong() ?: System.currentTimeMillis()
        )
        editor.putBoolean(KEY_HAS_DATA, arguments?.get("hasData") as? Boolean ?: false)
        editor.apply()
    }
}
