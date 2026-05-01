package com.example.phoneshame

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class RotHomeWidgetSmallProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, buildRemoteViews(context))
        }
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, RotHomeWidgetSmallProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            widgetIds.forEach { widgetId ->
                manager.updateAppWidget(widgetId, buildRemoteViews(context))
            }
        }

        private fun buildRemoteViews(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(HomeWidgetBridge.PREFS_NAME, Context.MODE_PRIVATE)
            val totalTimeLabel = prefs.getString(HomeWidgetBridge.KEY_TOTAL_TIME_LABEL, "0m") ?: "0m"
            val score = prefs.getInt(HomeWidgetBridge.KEY_SCORE, 0)

            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val views = RemoteViews(context.packageName, R.layout.rot_home_widget_small)
            views.setOnClickPendingIntent(R.id.widget_root_small, pendingIntent)
            views.setTextViewText(R.id.widget_score_value_small, score.toString())
            views.setTextViewText(R.id.widget_total_time_small, totalTimeLabel)
            
            return views
        }
    }
}
