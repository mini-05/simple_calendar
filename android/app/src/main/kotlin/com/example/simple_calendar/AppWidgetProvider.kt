package com.example.simple_calendar // 본인의 패키지명과 동일해야 합니다

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AppWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // 플러터 앱에서 쏜 데이터를 여기서 받아서 XML에 세팅합니다
                val title = widgetData.getString("today_date", "오늘의 일정")
                val description = widgetData.getString("today_events", "일정이 없습니다.")
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_description, description)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}