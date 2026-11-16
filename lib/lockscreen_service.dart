import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await LockScreenNotificationService.handleNotificationResponse(response);
}

class LockScreenNotificationService {
  static final LockScreenNotificationService instance =
      LockScreenNotificationService._();
  LockScreenNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  static const int kNotificationId = 7777;
  static const int kDeadlineAlertBaseId = 20000;
  static const String kActionAddTodo = 'action_add_todo';
  static const String kActionCompleteTopTodo = 'action_complete_top_todo';
  static const String kCategoryTodoActions = 'chronos_todo_actions';

  final Set<int> _activeDeadlineIds = {};

  /// Callback invoked when entries are added or modified via notification actions while app is active
  static VoidCallback? onEntriesUpdatedExternally;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final darwinCategory = DarwinNotificationCategory(
      kCategoryTodoActions,
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.text(
          kActionAddTodo,
          '+ 빠른 추가',
          buttonTitle: '추가',
          placeholder: '새로운 할 일 입력...',
        ),
        DarwinNotificationAction.plain(
          kActionCompleteTopTodo,
          '✓ 완료',
        ),
      ],
    );

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [darwinCategory],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        handleNotificationResponse(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request notification permission on Android 13+
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}

    _isInitialized = true;
  }

  /// Direct Reply 및 알림 액션 처리
  static Future<void> handleNotificationResponse(
      NotificationResponse response) async {
    final actionId = response.actionId;
    if (actionId == kActionAddTodo) {
      final input = response.input;
      if (input != null && input.trim().isNotEmpty) {
        await addTodoFromNotification(input.trim());
      }
    } else if (actionId == kActionCompleteTopTodo) {
      await completeTopTodoFromNotification();
    }
  }

  /// 잠금화면 알림에서 직접 입력받은 텍스트를 새로운 TODO로 등록
  static Future<void> addTodoFromNotification(String note) async {
    final prefs = await SharedPreferences.getInstance();
    final String? entriesJson = prefs.getString('chronos_entries');
    List<TimestampEntry> entries = [];
    if (entriesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(entriesJson);
        entries = decoded.map((item) => TimestampEntry.fromJson(item)).toList();
      } catch (_) {}
    }

    final String defaultCategory =
        prefs.getString('chronos_default_category') ?? 'General';

    String targetCategory = defaultCategory;
    String cleanNote = note.trim();
    if (cleanNote.startsWith('#')) {
      final spaceIndex = cleanNote.indexOf(' ');
      if (spaceIndex > 1) {
        final candidateCat = cleanNote.substring(1, spaceIndex).trim();
        if (candidateCat.isNotEmpty) {
          targetCategory = candidateCat;
          cleanNote = cleanNote.substring(spaceIndex + 1).trim();
        }
      }
    }

    if (cleanNote.isEmpty) return;

    final newEntry = TimestampEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      note: cleanNote,
      category: targetCategory,
      status: 'none', // 기본적으로 일반(none) 항목으로 생성
    );

    entries.insert(0, newEntry);

    final String encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString('chronos_entries', encoded);

    // 포그라운드에 앱이 켜져있다면 상태 갱신 트리거
    try {
      onEntriesUpdatedExternally?.call();
    } catch (_) {}

    // 잠금화면 알림 즉시 갱신
    final bool lockScreenEnabled =
        prefs.getBool('chronos_lockscreen_todo_enabled') ?? true;
    final bool deadlineEnabled =
        prefs.getBool('chronos_deadline_alerts_enabled') ?? true;
    await LockScreenNotificationService.instance.updateTopTodo(
      entries,
      enabled: lockScreenEnabled,
      deadlineAlertsEnabled: deadlineEnabled,
    );
  }

  /// 잠금화면 알림에서 최우선 TODO 완료 처리
  static Future<void> completeTopTodoFromNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final String? entriesJson = prefs.getString('chronos_entries');
    if (entriesJson == null) return;

    List<TimestampEntry> entries = [];
    try {
      final List<dynamic> decoded = jsonDecode(entriesJson);
      entries = decoded.map((item) => TimestampEntry.fromJson(item)).toList();
    } catch (_) {
      return;
    }

    final pendingTodos = entries.where((e) => e.status == 'todo').toList();
    if (pendingTodos.isEmpty) return;

    pendingTodos.sort((a, b) {
      if (a.targetDate != null && b.targetDate != null) {
        return a.targetDate!.compareTo(b.targetDate!);
      }
      if (a.targetDate != null) return -1;
      if (b.targetDate != null) return 1;
      return a.timestamp.compareTo(b.timestamp);
    });

    final top = pendingTodos.first;
    final index = entries.indexWhere((e) => e.id == top.id);
    if (index != -1) {
      entries[index] = entries[index].copyWith(
        status: 'done',
        doneTimestamp: DateTime.now(),
      );

      final String encoded =
          jsonEncode(entries.map((e) => e.toJson()).toList());
      await prefs.setString('chronos_entries', encoded);

      try {
        onEntriesUpdatedExternally?.call();
      } catch (_) {}

      final bool lockScreenEnabled =
          prefs.getBool('chronos_lockscreen_todo_enabled') ?? true;
      final bool deadlineEnabled =
          prefs.getBool('chronos_deadline_alerts_enabled') ?? true;
      await LockScreenNotificationService.instance.updateTopTodo(
        entries,
        enabled: lockScreenEnabled,
        deadlineAlertsEnabled: deadlineEnabled,
      );
    }
  }

  /// 마감일이 D-3 이내 (또는 기한 초과)인 TODO 항목들을 푸시 알림 및 잠금화면에 표시합니다.
  Future<void> checkAndNotifyDeadlines(
    List<TimestampEntry> entries, {
    bool enabled = true,
  }) async {
    await init();

    if (!enabled) {
      for (final id in _activeDeadlineIds) {
        try {
          await _plugin.cancel(id);
        } catch (_) {}
      }
      _activeDeadlineIds.clear();
      return;
    }

    final now = DateTime.now();
    // 마감일이 있는 미완료 TODO 중 D-3일 이내 (72시간 이내)이거나 이미 기한이 지난 항목 추출
    final pendingWithDeadline = entries.where((e) {
      if (e.status != 'todo' || e.targetDate == null) return false;
      final diff = e.targetDate!.difference(now);
      return diff.inSeconds <= 3 * 24 * 3600;
    }).toList();

    final currentIds = <int>{};

    for (final item in pendingWithDeadline) {
      final notifId = kDeadlineAlertBaseId + (item.id.hashCode.abs() % 10000);
      currentIds.add(notifId);

      final diff = item.targetDate!.difference(now);
      String title;
      String body;

      if (diff.isNegative) {
        title = '🚨 [마감 경과] ${item.category} TODO';
        body =
            '${item.note.isEmpty ? "할 일" : item.note}\n마감 기한이 지났습니다! (${DateFormat('M월 d일 HH:mm').format(item.targetDate!)})';
      } else if (diff.inHours < 24) {
        title = '⏰ [오늘 마감!] ${item.category} TODO';
        body =
            '${item.note.isEmpty ? "할 일" : item.note}\n오늘 ${DateFormat('HH:mm').format(item.targetDate!)} 마감 예정입니다!';
      } else {
        final days = (diff.inHours / 24).ceil();
        title = '⏳ [마감 D-$days] ${item.category} TODO';
        body =
            '${item.note.isEmpty ? "할 일" : item.note}\n마감일시: ${DateFormat('M월 d일 HH:mm').format(item.targetDate!)} ($days일 남음)';
      }

      final androidDetails = AndroidNotificationDetails(
        'chronos_deadline_alerts',
        '마감 임박 TODO 알림',
        channelDescription: '마감일이 3일 이내인 TODO의 푸시 알림 및 잠금화면 표시',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        onlyAlertOnce: true, // 데이터 갱신 시 반복 소리/진동 알림 방지
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      await _plugin.show(
        notifId,
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        ),
      );
    }

    // 이미 완료되었거나 삭제되어 더 이상 마감 대상이 아닌 알림 정리
    final toRemove = _activeDeadlineIds.difference(currentIds);
    for (final id in toRemove) {
      try {
        await _plugin.cancel(id);
      } catch (_) {}
    }
    _activeDeadlineIds
      ..clear()
      ..addAll(currentIds);
  }

  Future<void> updateTopTodo(
    List<TimestampEntry> entries, {
    bool enabled = true,
    bool deadlineAlertsEnabled = true,
  }) async {
    // 1. 마감 D-3 푸시 알림 확인 및 발송
    await checkAndNotifyDeadlines(entries, enabled: deadlineAlertsEnabled);

    // 2. 잠금화면 최우선 TODO 고정 알림 (Android에서는 완벽한 RemoteInput 응답을 위해 네이티브 채널 호출)
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.example.todonow/lockscreen');
        if (enabled) {
          await platform.invokeMethod('updateLockScreenTodo');
        } else {
          await platform.invokeMethod('clearLockScreenTodo');
        }
        return;
      } catch (e) {
        debugPrint('Error calling native lockscreen method: $e');
      }
    }

    if (!enabled) {
      await clearTopTodo();
      return;
    }

    await init();

    final pendingTodos = entries.where((e) => e.status == 'todo').toList();

    // 대기 중인 TODO가 없을 때도 잠금화면에서 바로 [+ 빠른 추가] 할 수 있도록 상시 알림 유지
    if (pendingTodos.isEmpty) {
      final List<AndroidNotificationAction> emptyActions = [
        const AndroidNotificationAction(
          kActionAddTodo,
          '+ 빠른 추가',
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: '새로운 할 일 입력...',
              allowFreeFormInput: true,
            ),
          ],
          cancelNotification: false,
          showsUserInterface: false,
        ),
      ];

      final androidDetails = AndroidNotificationDetails(
        'chronos_lockscreen_top_todo',
        '잠금화면 최우선 TODO',
        channelDescription: '핸드폰 잠금화면에 가장 중요한 TODO를 고정 표시합니다.',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        showWhen: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        actions: emptyActions,
        styleInformation: const BigTextStyleInformation(
          '모든 할 일을 마쳤습니다! 새로운 할 일이 생기면 아래 [+ 빠른 추가]를 눌러 바로 입력하세요.',
          contentTitle: '✨ 모든 TODO 완료',
        ),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: kCategoryTodoActions,
      );

      await _plugin.show(
        kNotificationId,
        '✨ 모든 TODO 완료',
        '새로운 할 일이 생기면 아래 [+ 빠른 추가]를 눌러 바로 입력하세요.',
        NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        ),
      );
      return;
    }

    // 우선순위 정렬:
    // 1. 가장 가까운 마감일자 (earliest deadline first)
    // 2. 마감일자 있는 항목 우선
    // 3. 오래된 등록 시간 순
    pendingTodos.sort((a, b) {
      if (a.targetDate != null && b.targetDate != null) {
        return a.targetDate!.compareTo(b.targetDate!);
      }
      if (a.targetDate != null) return -1;
      if (b.targetDate != null) return 1;
      return a.timestamp.compareTo(b.timestamp);
    });

    final top = pendingTodos.first;
    final totalPending = pendingTodos.length;

    String subtitle = '';
    if (top.targetDate != null) {
      final now = DateTime.now();
      final diff = top.targetDate!.difference(now);
      if (diff.isNegative) {
        subtitle =
            '🚨 기한 지남 (${DateFormat('M/d HH:mm').format(top.targetDate!)})';
      } else if (diff.inHours < 24) {
        subtitle = '⏰ 마감: 오늘 ${DateFormat('HH:mm').format(top.targetDate!)}';
      } else {
        subtitle =
            '📅 마감: ${DateFormat('M월 d일 HH:mm').format(top.targetDate!)}';
      }
    }

    String bodyText = top.note.isEmpty ? '할 일' : top.note;
    if (subtitle.isNotEmpty) {
      bodyText = '$bodyText\n$subtitle';
    }
    if (totalPending > 1) {
      bodyText = '$bodyText (남은 TODO: ${totalPending - 1}개)';
    }

    final List<AndroidNotificationAction> actions = [
      const AndroidNotificationAction(
        kActionAddTodo,
        '+ 빠른 추가',
        inputs: <AndroidNotificationActionInput>[
          AndroidNotificationActionInput(
            label: '새로운 할 일 입력...',
            allowFreeFormInput: true,
          ),
        ],
        cancelNotification: false,
        showsUserInterface: false,
      ),
      const AndroidNotificationAction(
        kActionCompleteTopTodo,
        '✓ 완료',
        cancelNotification: false,
        showsUserInterface: false,
      ),
    ];

    final androidDetails = AndroidNotificationDetails(
      'chronos_lockscreen_top_todo',
      '잠금화면 최우선 TODO',
      channelDescription: '핸드폰 잠금화면에 가장 중요한 TODO를 고정 표시합니다.',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Pinned sticky notification on lockscreen & shade
      autoCancel: false,
      showWhen: true,
      visibility:
          NotificationVisibility.public, // Visible on secure lock screen!
      category: AndroidNotificationCategory.reminder,
      actions: actions,
      styleInformation: BigTextStyleInformation(
        bodyText,
        contentTitle: '📌 [${top.category}] 최우선 할 일',
        summaryText:
            totalPending > 1 ? '$totalPending개 TODO 대기 중' : '1개 TODO 대기 중',
      ),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
      interruptionLevel: InterruptionLevel.active,
      categoryIdentifier: kCategoryTodoActions,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      kNotificationId,
      '📌 [${top.category}] 최우선 할 일',
      bodyText,
      details,
    );
  }

  Future<void> clearTopTodo() async {
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.example.todonow/lockscreen');
        await platform.invokeMethod('clearLockScreenTodo');
      } catch (_) {}
    }
    try {
      await _plugin.cancel(kNotificationId);
    } catch (_) {}
  }

  Future<void> clear() async {
    await clearTopTodo();
    for (final id in _activeDeadlineIds) {
      try {
        await _plugin.cancel(id);
      } catch (_) {}
    }
    _activeDeadlineIds.clear();
  }
}
