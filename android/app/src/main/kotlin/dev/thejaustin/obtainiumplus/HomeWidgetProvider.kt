package dev.thejaustin.obtainiumplus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider as HomeWidgetProviderBase
import android.app.PendingIntent
import android.content.Intent

class HomeWidgetProvider : HomeWidgetProviderBase() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val pendingUpdates = widgetData.getInt("pending_updates_count", 0)
                setTextViewText(R.id.pending_updates_count, pendingUpdates.toString())

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("obtainium://widget")
                )
                setOnClickPendingIntent(R.id.quick_action_button, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
