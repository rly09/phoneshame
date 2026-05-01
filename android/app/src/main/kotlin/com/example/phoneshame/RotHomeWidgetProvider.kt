package com.example.phoneshame

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class RotHomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, buildRemoteViews(context))
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        HomeWidgetBridge.refreshWidgets(context)

        // Start background worker
        val workRequest = androidx.work.PeriodicWorkRequestBuilder<RotWidgetWorker>(
            15, java.util.concurrent.TimeUnit.MINUTES
        ).build()
        
        androidx.work.WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            "RotWidgetWorker",
            androidx.work.ExistingPeriodicWorkPolicy.UPDATE,
            workRequest
        )
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Optionally cancel the work when the last widget is removed
        androidx.work.WorkManager.getInstance(context).cancelUniqueWork("RotWidgetWorker")
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, RotHomeWidgetProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            widgetIds.forEach { widgetId ->
                manager.updateAppWidget(widgetId, buildRemoteViews(context))
            }
        }

        private fun buildRemoteViews(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(HomeWidgetBridge.PREFS_NAME, Context.MODE_PRIVATE)
            val hasData = prefs.getBoolean(HomeWidgetBridge.KEY_HAS_DATA, false)
            val totalTimeLabel = prefs.getString(HomeWidgetBridge.KEY_TOTAL_TIME_LABEL, "0m") ?: "0m"
            val score = prefs.getInt(HomeWidgetBridge.KEY_SCORE, 0)
            val topApp = prefs.getString(HomeWidgetBridge.KEY_TOP_APP, "No data yet") ?: "No data yet"
            val topTimeLabel = prefs.getString(HomeWidgetBridge.KEY_TOP_TIME_LABEL, "0m") ?: "0m"
            val trackedApps = prefs.getInt(HomeWidgetBridge.KEY_TRACKED_APPS_COUNT, 0)
            val updatedAtMs = prefs.getLong(HomeWidgetBridge.KEY_UPDATED_AT_MS, 0L)

            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val views = RemoteViews(context.packageName, R.layout.rot_home_widget)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            views.setTextViewText(R.id.widget_total_time, totalTimeLabel)
            views.setTextViewText(R.id.widget_score_value, score.toString())
            views.setTextViewText(
                R.id.widget_top_app,
                if (hasData) "$topApp • $topTimeLabel" else "Open the app to sync today's stats"
            )
            views.setTextViewText(
                R.id.widget_footer,
                if (updatedAtMs > 0L) {
                    "Updated ${formatTime(updatedAtMs)} • $trackedApps apps"
                } else {
                    "Waiting for first sync"
                }
            )
            return views
        }

        private fun formatTime(epochMs: Long): String {
            val formatter = SimpleDateFormat("h:mm a", Locale.getDefault())
            return formatter.format(Date(epochMs))
        }
    }
}
