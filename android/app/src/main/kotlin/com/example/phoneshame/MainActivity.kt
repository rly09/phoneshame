package com.example.phoneshame

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UsageStatsPlugin.CHANNEL_NAME
        ).setMethodCallHandler(UsageStatsPlugin(this))

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HomeWidgetBridge.CHANNEL_NAME
        ).setMethodCallHandler(HomeWidgetBridge(this))
    }
}
