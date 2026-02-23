package com.example.simple_calendar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.view.WindowManager.LayoutParams

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 🛡️ [우주 최고 보안] 화면 캡처 방지 및 최근 앱 목록(백그라운드) 블라인드 처리
        window.addFlags(LayoutParams.FLAG_SECURE)
    }
}