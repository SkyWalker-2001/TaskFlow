package com.example.taskflow

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TaskflowWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.taskflow_widget).apply {
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, launchIntent)

                val listName = widgetData.getString("widget_list_name", "My Tasks")
                val total = widgetData.getInt("widget_total", 0)
                val done = widgetData.getInt("widget_done", 0)
                val active = widgetData.getInt("widget_active", 0)
                val tasksText = widgetData.getString("widget_tasks_text", "No tasks in this list")

                setTextViewText(R.id.widget_list_name, listName)
                setTextViewText(R.id.widget_summary, "$done/$total done • $active active")
                setTextViewText(R.id.widget_tasks, tasksText)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
