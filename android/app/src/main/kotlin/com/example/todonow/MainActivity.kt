package com.example.todonow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.app.NotificationManagerCompat

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.todonow/lockscreen"
    private var methodChannel: MethodChannel? = null

    private val entriesUpdateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            methodChannel?.invokeMethod("onEntriesUpdatedExternally", null)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val filter = IntentFilter("com.example.todonow.ACTION_ENTRIES_UPDATED")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(entriesUpdateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(entriesUpdateReceiver, filter)
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(entriesUpdateReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateLockScreenTodo" -> {
                    LockScreenNotificationReceiver.updateNotification(context)
                    result.success(true)
                }
                "clearLockScreenTodo" -> {
                    NotificationManagerCompat.from(context)
                        .cancel(LockScreenNotificationReceiver.NOTIFICATION_ID)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
