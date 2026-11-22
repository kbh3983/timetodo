package com.bebong.timetodo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class LockScreenNotificationReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "LockScreenReceiver"
        const val NOTIFICATION_ID = 7777
        const val CHANNEL_ID = "chronos_lockscreen_silent_v3"
        const val CHANNEL_NAME = "잠금화면 상시 기록"
        const val REMOTE_INPUT_KEY = "key_quick_add_todo"
        const val ACTION_ADD_TODO = "com.bebong.timetodo.ACTION_ADD_TODO"
        const val ACTION_COMPLETE_TODO = "com.bebong.timetodo.ACTION_COMPLETE_TODO"
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val KEY_ENTRIES = "flutter.chronos_entries"
        const val KEY_DEFAULT_CAT = "flutter.chronos_default_category"
        const val KEY_LOCKSCREEN_ENABLED = "flutter.chronos_lockscreen_todo_enabled"

        private var lastPostedSignature: String? = null

        fun ensureChannel(context: Context) {
            val isKo = Locale.getDefault().language == "ko"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                if (manager != null) {
                    try {
                        manager.deleteNotificationChannel("chronos_lockscreen_top_todo")
                        manager.deleteNotificationChannel("chronos_lockscreen_top_todo_v2")
                    } catch (_: Exception) {}

                    if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                        val channel = NotificationChannel(
                            CHANNEL_ID,
                            if (isKo) "잠금화면 상시 기록" else "Lockscreen Todo",
                            NotificationManager.IMPORTANCE_LOW
                        ).apply {
                            description = if (isKo) "핸드폰 잠금화면에 최우선 할 일 및 빠른 입력을 고정 표시합니다." else "Displays top priority tasks and quick input on lockscreen."
                            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                            setSound(null, null)
                            enableVibration(false)
                            enableLights(false)
                            setShowBadge(false)
                        }
                        manager.createNotificationChannel(channel)
                    }
                }
            }
        }

        fun updateNotification(context: Context, force: Boolean = false) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val enabled = prefs.getBoolean(KEY_LOCKSCREEN_ENABLED, true)
                if (!enabled) {
                    NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
                    lastPostedSignature = null
                    return
                }

                val entriesJson = prefs.getString(KEY_ENTRIES, "[]") ?: "[]"
                val array = JSONArray(entriesJson)

                var topTodo: JSONObject? = null
                var pendingCount = 0
                var earliestDeadline = Long.MAX_VALUE

                for (i in 0 until array.length()) {
                    val item = array.optJSONObject(i) ?: continue
                    if ("todo" == item.optString("status")) {
                        pendingCount++
                        val targetDate = item.optLong("targetDate", 0L)
                        if (targetDate > 0) {
                            if (targetDate < earliestDeadline) {
                                earliestDeadline = targetDate
                                topTodo = item
                            }
                        } else if (topTodo == null) {
                            topTodo = item
                        }
                    }
                }

                // 중복 알림 방지 서명 검사: 내용이 달라지지 않았으면 재발행하지 않음!
                val currentSignature = if (pendingCount == 0 || topTodo == null) {
                    "EMPTY_0"
                } else {
                    "${topTodo.optString("id")}_${topTodo.optString("note")}_${pendingCount}"
                }

                if (!force && currentSignature == lastPostedSignature) {
                    Log.d(TAG, "Notification content unchanged, skipping notify()")
                    return
                }
                lastPostedSignature = currentSignature

                ensureChannel(context)

                val immFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val mutFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent(context, MainActivity::class.java)
                val contentPendingIntent = PendingIntent.getActivity(context, 100, launchIntent, immFlags)

                val isKo = Locale.getDefault().language == "ko"
                // Direct Reply Action (+ 빠른 기록)
                val remoteInput = RemoteInput.Builder(REMOTE_INPUT_KEY)
                    .setLabel(if (isKo) "지금 이 순간을 기록해보세요..." else "Record what is happening...")
                    .build()

                val addIntent = Intent(context, LockScreenNotificationReceiver::class.java).apply {
                    action = ACTION_ADD_TODO
                }
                val addPendingIntent = PendingIntent.getBroadcast(context, 101, addIntent, mutFlags)

                val addAction = NotificationCompat.Action.Builder(
                    android.R.drawable.ic_input_add,
                    if (isKo) "+ 빠른 기록" else "+ Quick Record",
                    addPendingIntent
                ).addRemoteInput(remoteInput)
                 .setShowsUserInterface(false)
                 .build()

                val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setPriority(NotificationCompat.PRIORITY_LOW)
                    .setOngoing(true)
                    .setAutoCancel(false)
                    .setSilent(true)
                    .setOnlyAlertOnce(true)
                    .setLocalOnly(true)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setContentIntent(contentPendingIntent)
                    .addAction(addAction)

                if (pendingCount == 0 || topTodo == null) {
                    // Always stay visible on lock screen even with 0 todos!
                    val title = if (isKo) "🌿 잠시 여유가 있다면," else "🌿 Take a moment,"
                    val body = if (isKo) "스치는 생각이나 지금 이 순간을 가볍게 남겨보세요." else "Record your thoughts or current moments."
                    builder.setContentTitle(title)
                        .setContentText(body)
                        .setStyle(
                            NotificationCompat.BigTextStyle()
                                .bigText(if (isKo) "잠시 여유가 있다면, 지금 떠오르는 생각이나 순간을 아래 [+ 빠른 기록]으로 가볍게 남겨보세요." else "Take a breath and capture your thoughts with [+ Quick Record] below.")
                                .setBigContentTitle(title)
                        )
                } else {
                    val category = topTodo.optString("category", "General")
                    val note = topTodo.optString("note", if (isKo) "할 일" else "Task")
                    val targetDate = topTodo.optLong("targetDate", 0L)

                    var subtitle = ""
                    if (targetDate > 0) {
                        val calNow = Calendar.getInstance().apply {
                            set(Calendar.HOUR_OF_DAY, 0)
                            set(Calendar.MINUTE, 0)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }
                        val calTarget = Calendar.getInstance().apply {
                            timeInMillis = targetDate
                            set(Calendar.HOUR_OF_DAY, 0)
                            set(Calendar.MINUTE, 0)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }
                        val diffDays = ((calTarget.timeInMillis - calNow.timeInMillis) / (24 * 3600 * 1000L)).toInt()
                        val sdf = SimpleDateFormat("M/d HH:mm", if (isKo) Locale.KOREA else Locale.US)
                        val timeFormat = SimpleDateFormat("HH:mm", if (isKo) Locale.KOREA else Locale.US)

                        subtitle = if (targetDate < System.currentTimeMillis()) {
                            if (isKo) "🚨 기한 지남 (${sdf.format(Date(targetDate))})" else "🚨 Overdue (${sdf.format(Date(targetDate))})"
                        } else if (diffDays == 0) {
                            if (isKo) "⏰ 오늘 마감 (${timeFormat.format(Date(targetDate))})" else "⏰ Due Today (${timeFormat.format(Date(targetDate))})"
                        } else if (diffDays == 1) {
                            if (isKo) "⏳ 내일 마감 (D-1) (${timeFormat.format(Date(targetDate))})" else "⏳ Due Tomorrow (D-1) (${timeFormat.format(Date(targetDate))})"
                        } else {
                            if (isKo) "⏳ 마감 D-$diffDays (${sdf.format(Date(targetDate))})" else "⏳ Due in $diffDays d (${sdf.format(Date(targetDate))})"
                        }
                    }

                    var body = note
                    if (subtitle.isNotEmpty()) {
                        body = "$body\n$subtitle"
                    }
                    if (pendingCount > 1) {
                        body = if (isKo) "$body (남은 TODO: ${pendingCount - 1}개)" else "$body (${pendingCount - 1} more tasks)"
                    }

                    val doneIntent = Intent(context, LockScreenNotificationReceiver::class.java).apply {
                        action = ACTION_COMPLETE_TODO
                    }
                    val donePendingIntent = PendingIntent.getBroadcast(context, 102, doneIntent, mutFlags)

                    val doneAction = NotificationCompat.Action.Builder(
                        android.R.drawable.checkbox_on_background,
                        if (isKo) "✓ 완료" else "✓ Done",
                        donePendingIntent
                    ).setShowsUserInterface(false)
                     .build()

                    val title = if (isKo) "📌 [$category] 최우선 할 일" else "📌 [$category] Top Task"
                    builder.setContentTitle(title)
                        .setContentText(body)
                        .setStyle(
                            NotificationCompat.BigTextStyle()
                                .bigText(body)
                                .setBigContentTitle(title)
                                .setSummaryText(if (isKo) (if (pendingCount > 1) "${pendingCount}개 TODO 대기 중" else "1개 TODO 대기 중") else (if (pendingCount > 1) "$pendingCount tasks pending" else "1 task pending"))
                        )
                        .addAction(doneAction)
                }

                NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, builder.build())
                Log.d(TAG, "Notification successfully posted! (pending=$pendingCount)")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update lockscreen notification", e)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return
        Log.d(TAG, "onReceive action=${intent.action}")

        when (intent.action) {
            ACTION_ADD_TODO -> {
                val remoteInput = RemoteInput.getResultsFromIntent(intent)
                val inputText = remoteInput?.getCharSequence(REMOTE_INPUT_KEY)?.toString()?.trim()
                Log.d(TAG, "ACTION_ADD_TODO received text=$inputText")
                if (!inputText.isNullOrEmpty()) {
                    addNewTodo(context, inputText)
                } else {
                    updateNotification(context, force = true)
                }
            }
            ACTION_COMPLETE_TODO -> {
                Log.d(TAG, "ACTION_COMPLETE_TODO received")
                completeTopTodo(context)
            }
        }
    }

    private fun addNewTodo(context: Context, note: String) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val entriesJson = prefs.getString(KEY_ENTRIES, "[]") ?: "[]"
            val array = JSONArray(entriesJson)

            val defaultCategory = prefs.getString(KEY_DEFAULT_CAT, "General") ?: "General"
            val now = System.currentTimeMillis()

            var targetCategory = defaultCategory
            var cleanNote = note.trim()

            // 스마트 카테고리 태깅: #카테고리명 내용 (예: #운동 헬스장)
            if (cleanNote.startsWith("#")) {
                val spaceIndex = cleanNote.indexOf(' ')
                if (spaceIndex > 1) {
                    val candidateCat = cleanNote.substring(1, spaceIndex).trim()
                    if (candidateCat.isNotEmpty()) {
                        targetCategory = candidateCat
                        cleanNote = cleanNote.substring(spaceIndex + 1).trim()
                    }
                }
            }

            val newEntry = JSONObject().apply {
                put("id", now.toString())
                put("timestamp", now)
                put("note", cleanNote)
                put("category", targetCategory)
                put("status", "none") // 기본적으로 TODO가 아닌 일반 기록으로 생성
            }

            // Prepend new TODO at index 0
            val newArray = JSONArray().apply {
                put(newEntry)
                for (i in 0 until array.length()) {
                    put(array.get(i))
                }
            }

            prefs.edit().putString(KEY_ENTRIES, newArray.toString()).commit()
            Log.d(TAG, "Saved new TODO to SharedPreferences: $note")

            // Re-post notification immediately -> IMMEDIATELY STOPS SPINNER!
            updateNotification(context, force = true)

            // Notify running app to update UI in real-time without delay
            val updateIntent = Intent("com.bebong.timetodo.ACTION_ENTRIES_UPDATED").apply {
                setPackage(context.packageName)
            }
            context.sendBroadcast(updateIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add new TODO", e)
        }
    }

    private fun completeTopTodo(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val entriesJson = prefs.getString(KEY_ENTRIES, "[]") ?: "[]"
            val array = JSONArray(entriesJson)

            var topIndex = -1
            var topTodo: JSONObject? = null
            var earliestDeadline = Long.MAX_VALUE

            for (i in 0 until array.length()) {
                val item = array.optJSONObject(i) ?: continue
                if ("todo" == item.optString("status")) {
                    val targetDate = item.optLong("targetDate", 0L)
                    if (targetDate > 0) {
                        if (targetDate < earliestDeadline) {
                            earliestDeadline = targetDate
                            topIndex = i
                            topTodo = item
                        }
                    } else if (topTodo == null) {
                        topIndex = i
                        topTodo = item
                    }
                }
            }

            if (topIndex != -1 && topTodo != null) {
                topTodo.put("status", "done")
                topTodo.put("doneTimestamp", System.currentTimeMillis())
                array.put(topIndex, topTodo)

                prefs.edit().putString(KEY_ENTRIES, array.toString()).commit()
                Log.d(TAG, "Completed top TODO at index $topIndex")

                updateNotification(context, force = true)

                val updateIntent = Intent("com.bebong.timetodo.ACTION_ENTRIES_UPDATED").apply {
                    setPackage(context.packageName)
                }
                context.sendBroadcast(updateIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to complete top TODO", e)
        }
    }
}

