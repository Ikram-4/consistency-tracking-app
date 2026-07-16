package com.example.phantom

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

class PhantomWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        
        // home_widget package writes both strings and booleans depending on platform versions,
        // so we check both string representation and actual boolean.
        val hasData = prefs.getBoolean("has_data", false) || 
                      prefs.getString("has_data", "false") == "true"
        
        val standing = prefs.getString("standing", "0 / 0 on track")
        val behindPractice = prefs.getString("behind_practice", "")
        val lastLog = prefs.getString("last_log", "No logs yet")

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.phantom_widget)

            if (hasData) {
                // Show content, hide placeholder
                views.setViewVisibility(R.id.widget_empty_state, View.GONE)
                views.setViewVisibility(R.id.widget_content_layout, View.VISIBLE)

                views.setTextViewText(R.id.widget_standing, standing)
                views.setTextViewText(R.id.widget_last_log, lastLog)

                if (!behindPractice.isNullOrEmpty()) {
                    views.setViewVisibility(R.id.widget_behind_layout, View.VISIBLE)
                    views.setTextViewText(R.id.widget_behind_practice, "⚠ $behindPractice needs attention")
                } else {
                    views.setViewVisibility(R.id.widget_behind_layout, View.GONE)
                }
            } else {
                // Show placeholder, hide content
                views.setViewVisibility(R.id.widget_empty_state, View.VISIBLE)
                views.setViewVisibility(R.id.widget_content_layout, View.GONE)
            }

            // Launch app on tap
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
