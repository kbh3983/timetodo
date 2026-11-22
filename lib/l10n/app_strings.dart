import 'package:flutter/widgets.dart';

/// Comprehensive localization provider for TimeTodo.
/// Defaults to English for any non-Korean locale (ko -> Korean, all others -> English).
class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    final loc = Localizations.maybeLocaleOf(context) ??
        WidgetsBinding.instance.platformDispatcher.locale;
    return AppStrings(loc);
  }

  static bool get isCurrentLocaleKo {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return locale.languageCode == 'ko';
  }

  bool get isKo => locale.languageCode == 'ko';

  // --- Dynamic Time Formatting ---
  static String formatDuration(Duration diff, {bool? isKorean}) {
    final bool ko = isKorean ?? isCurrentLocaleKo;
    final totalSec = diff.inSeconds;
    if (totalSec <= 0) return ko ? '0초' : '0s';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add(ko ? '${days}일' : '${days}d');
    if (days > 0 || hours > 0) parts.add(ko ? '${hours}시간' : '${hours}h');
    if (days > 0 || hours > 0 || minutes > 0) parts.add(ko ? '${minutes}분' : '${minutes}m');
    parts.add(ko ? '${seconds}초' : '${seconds}s');
    return parts.join(' ');
  }

  static String formatSeconds(int totalSeconds, {bool? isKorean}) {
    return formatDuration(Duration(seconds: totalSeconds), isKorean: isKorean);
  }

  // --- Navigation & Core Tabs ---
  String get tabTasks => isKo ? '할 일' : 'Tasks';
  String get navTimeline => isKo ? '타임라인' : 'Timeline';
  String get navCategory => isKo ? '카테고리' : 'Category';
  String get tabInsights => isKo ? '인사이트' : 'Insights';
  String get tabSettings => isKo ? '설정' : 'Settings';
  String get tabCamera => isKo ? '타임스탬프 카메라' : 'Camera';

  // --- Common Buttons & Actions ---
  String get commonAdd => isKo ? '추가' : 'Add';
  String get commonSave => isKo ? '저장' : 'Save';
  String get commonCancel => isKo ? '취소' : 'Cancel';
  String get commonDelete => isKo ? '삭제' : 'Delete';
  String get commonConfirm => isKo ? '확인' : 'Confirm';
  String get commonDone => isKo ? '완료' : 'Done';
  String get commonEdit => isKo ? '수정' : 'Edit';
  String get commonClose => isKo ? '닫기' : 'Close';
  String get commonRetry => isKo ? '다시 시도' : 'Retry';
  String get commonSelect => isKo ? '선택' : 'Select';
  String get commonShare => isKo ? '공유' : 'Share';

  // --- Main View & Quick Add ---
  String get quickAddHint => isKo ? '이 순간을 기록해볼까요' : 'What are you doing right now?';
  String get viewTasks => isKo ? 'TODO 모아보기' : 'View Tasks';
  String get viewAll => isKo ? '전체 보기' : 'View All';
  String get swipeGuideText => isKo ? '카드를 왼쪽으로 밀어 삭제할 수 있어요' : 'Swipe left to delete an item';
  String get todoEmptyList => isKo ? '등록된 할 일이 없습니다. 새로운 할 일을 추가해보세요!' : 'No tasks yet. Tap above to add one!';
  String get timelineEmptyList => isKo ? '기록된 타임스탬프가 없습니다.' : 'No timeline records yet.';

  // --- Task Card Actions & Milestones ---
  String get actionStart => isKo ? '착수' : 'Start';
  String get actionPause => isKo ? '일시정지' : 'Pause';
  String get actionResume => isKo ? '계속하기' : 'Resume';
  String get actionDone => isKo ? '완료' : 'Done';
  String get milestoneTitle => isKo ? '작업 기록 이정표' : 'Work Milestones';
  String milestoneLap(int idx) => isKo ? '구간 $idx: ' : 'Lap $idx: ';
  String get milestoneInProgress => isKo ? '진행 중' : 'In Progress';
  String get manualInputBadge => isKo ? '수동 입력' : 'Manual Input';
  String get manualInputDurationLabel => isKo ? '수동 입력 소요 시간: ' : 'Manual Input Duration: ';
  String get totalDurationPrefix => isKo ? '총 ' : 'Total ';
  String get spentDurationSuffix => isKo ? ' 소요' : ' spent';
  String get badgePhoto => isKo ? '사진' : 'Photo';
  String get badgeTodo => 'TODO';

  // --- Complete Task Sheet ---
  String get doneSheetTitle => isKo ? '완료 기록' : 'Complete Task';
  String get doneSheetSubtitle => isKo
      ? '이 챕터를 완료하며 남길 메모나 사진을 추가하세요.'
      : 'Add a note or photo to celebrate this milestone.';
  String get doneNoteHint => isKo ? '어떤 성과를 이루셨나요?' : 'What did you accomplish?';
  String get measuredWorkTime => isKo ? '측정된 작업 소요 시간' : 'Measured Work Time';
  String get manualWorkTimeInput => isKo ? '소요 시간 직접 입력' : 'Manual Time Input';
  String get restoreMeasured => isKo ? '측정값 복원' : 'Restore';
  String get addTime => isKo ? '시간 추가' : 'Add Time';
  String get noMeasuredTime => isKo ? '측정된 시간 없음' : 'No measured time';
  String get inputDurationLabel => isKo ? '입력된 소요 시간: ' : 'Input Duration: ';
  String get unitHour => isKo ? '시간' : 'h';
  String get unitMinute => isKo ? '분' : 'm';
  String get unitSecond => isKo ? '초' : 's';
  String get saveCompletion => isKo ? '완료 기록 저장' : 'Save Completion';

  // --- Entry Edit / Options Sheet ---
  String get editEntryTitle => isKo ? '기록 수정' : 'Edit Entry';
  String get editEntryNoteHint => isKo ? '어떤 순간이었나요?' : 'Describe this moment...';
  String get editEntryNoteHintQuick => isKo ? '지금 무슨 일이 일어나고 있나요?' : 'What is happening right now?';
  String get registerAsTodo => isKo ? 'TODO로 등록' : 'Register as TODO';
  String get dueDate => isKo ? '마감 기한' : 'Due Date';
  String get selectDate => isKo ? '날짜 선택' : 'Select Date';
  String get resetPreset => isKo ? '초기화' : 'Reset';
  String get editEntrySave => isKo ? '기록 수정 완료' : 'Save Changes';
  String get targetDeadline => isKo ? '목표 기한 (D-Day)' : 'Due Date (D-Day)';
  String get targetDeadlineSet => isKo ? '목표 기한 설정' : 'Set Due Date';
  String get targetDeadlineNone => isKo ? '기한 없음' : 'No Due Date';
  String get spentTimeForStats => isKo ? '소요 시간 (통계용)' : 'Duration (For Stats)';
  String get notSet => isKo ? '미설정' : 'Not Set';
  String get deleteConfirmTitle => isKo ? '기록 삭제' : 'Delete Entry';
  String get deleteConfirmDesc => isKo
      ? '이 기록을 정말 삭제하시겠습니까?\n삭제된 내용은 복구할 수 없습니다.'
      : 'Are you sure you want to delete this entry?\nThis cannot be undone.';

  // --- Revert Task ---
  String get revertTodoTitle => isKo ? 'TODO로 되돌리기' : 'Revert to TODO';
  String get revertTodoDesc => isKo
      ? '이 작업을 다시 TODO로 되돌리시겠습니까?\n기존에 기록했던 완료 메모와 완료 시간이 초기화됩니다.'
      : 'Revert this task back to TODO?\nCompleted notes and recorded time will be reset.';
  String get revertConfirm => isKo ? '되돌리기' : 'Revert';

  // --- Category ---
  String get categoryManagement => isKo ? '카테고리 관리' : 'Categories';
  String get categoryAll => isKo ? '전체' : 'All';
  String get categoryGeneral => isKo ? '기본' : 'General';
  String get categoryAddNew => isKo ? '새 카테고리 추가' : 'Add Category';
  String get categoryNameHint => isKo ? '카테고리 이름 입력' : 'Category name';
  String get categoryColorSelect => isKo ? '색상 선택' : 'Select Color';
  String get categoryCustomColor => isKo ? '직접 색상 선택' : 'Custom Color';
  String get categoryDeleteTitle => isKo ? '카테고리 삭제' : 'Delete Category';
  String categoryDeleteDesc(String name) => isKo
      ? '\"$name\" 카테고리를 삭제하시겠습니까?\n해당 카테고리의 기록은 \"기본\" 카테고리로 이동됩니다.'
      : 'Delete \"$name\" category?\nAll entries will be moved to General.';
  String get unitItems => isKo ? '건' : ' items';
  String get durationLabel => isKo ? '소요 시간' : 'Duration';

  // --- Insights & Statistics ---
  String get insightTimeStats => isKo ? '시간 사용 통계' : 'Time Usage Stats';
  String get insightTimeStatsDesc => isKo
      ? '카테고리별 소요 시간과 점유율을 분석합니다'
      : 'Analyze elapsed time and share by category';
  String get filterAll => isKo ? '전체' : 'All';
  String get filterDaily => isKo ? '일간' : 'Daily';
  String get filterWeekly => isKo ? '주간' : 'Weekly';
  String get filterMonthly => isKo ? '월간' : 'Monthly';
  String get filterYearly => isKo ? '연간' : 'Yearly';

  String get metricCompletedTasks => isKo ? '완료된 작업' : 'Completed';
  String get metricPendingTasks => isKo ? '진행 중 TODO' : 'In Progress';
  String get metricTotalTasks => isKo ? '총 TODO 수' : 'Total Tasks';
  String get metricAvgDuration => isKo ? '평균 소요 시간' : 'Avg Duration';
  String get metricShareTime => isKo ? '소요 시간 점유율' : 'Duration Share';
  String get metricShareCount => isKo ? '기록 건수 점유율' : 'Count Share';
  String get noTimeRecorded => isKo ? '기록된 소요 시간이 없습니다' : 'No elapsed time recorded';
  String get noTimeRecordedDesc => isKo
      ? 'TODO를 완료하거나 소요 시간을 입력하면\n카테고리별 시간 점유율이 자동으로 분석됩니다.'
      : 'Complete tasks or enter elapsed time to analyze your category share.';
  String get noTasksForStats => isKo ? '소요 시간이 기록된 활동이 없습니다.' : 'No activities with recorded time.';

  String get insight24hPattern => isKo ? '24시간 활동 패턴' : '24-Hour Activity Pattern';
  String get insight24hPatternDesc => isKo
      ? '언제 가장 활발하게 활동하고 기록하는지 분석합니다'
      : 'See when you are most active throughout the day';
  String get insightWeeklyPattern => isKo ? '요일별 활동 패턴' : 'Weekly Activity Pattern';
  String get insightWeeklyPatternDesc => isKo
      ? '요일별 활동 빈도와 주중/주말 생산성을 비교합니다'
      : 'Compare activity frequency between weekdays and weekends';
  String get insightTodoCompletion => isKo ? 'TODO 달성률' : 'Task Completion Rate';
  String get insightTodoCompletionDesc => isKo
      ? '목표 달성률 및 작업 완료 속도를 분석합니다'
      : 'Track your completion speed and goal achievement';
  String get insightRanking => isKo ? '활동 시간 랭킹' : 'Top Activities';
  String get insightRankingDesc => isKo
      ? '가장 많은 시간을 투자한 활동 Top 5'
      : 'Top 5 activities you invested the most time in';
  String get insightMonthlyTable => isKo ? '월간 타임 테이블' : 'Monthly Timeline';
  String get insightMonthlyTableDesc => isKo
      ? '세로(날짜 1~31일) × 가로(24시간) 활동 타임라인'
      : 'Days (1-31) × 24-hour activity timeline';
  String get insightWeeklyTable => isKo ? '주간 타임 테이블' : 'Weekly Matrix';
  String get insightWeeklyTableDesc => isKo
      ? 'Outlook 스타일 가로(요일) × 세로(시간대) 활동 매트릭스'
      : 'Days of week × time slot activity matrix';
  String get insightCalendar => isKo ? '활동 캘린더' : 'Activity Calendar';
  String get insightCalendarDesc => isKo
      ? '월별 활동 일관성 및 날짜별 상세 기록을 확인합니다'
      : 'Review monthly consistency and daily detailed logs';

  // --- Settings ---
  String get settingsTitle => isKo ? '설정' : 'Settings';
  String get settingsUiScale => isKo ? '글자 및 UI 크기' : 'Font & UI Scale';
  String get settingsUiScaleDesc => isKo
      ? '앱 전체의 텍스트와 레이아웃 크기를 조절합니다'
      : 'Adjust the text and layout scale across the app';
  String get scaleSmall => isKo ? '작게' : 'Small';
  String get scaleNormal => isKo ? '보통' : 'Default';
  String get scaleLarge => isKo ? '크게' : 'Large';
  String get settingsThemeAccent => isKo ? '테마 포인트 색상' : 'Theme Accent Color';
  String get settingsThemeAccentDesc => isKo
      ? '버튼 및 주요 강조 요소의 색상을 변경합니다'
      : 'Change the color of buttons and key highlights';
  String get settingsDarkMode => isKo ? '다크 모드' : 'Dark Mode';
  String get settingsDarkModeDesc => isKo
      ? '어두운 테마로 눈의 피로를 덜어줍니다'
      : 'Reduces eye strain with a dark theme';
  String get settingsCustomColor => isKo ? '직접 색상 지정' : 'Custom Color';
  String get settingsPrivacyPolicy => isKo ? '개인정보처리방침' : 'Privacy Policy';
  String get settingsVersion => isKo ? '버전' : 'Version';
  String get settingsSupport => isKo ? '지원 및 정보' : 'Support & Info';

  // --- Cheer developer & Pro ---
  String get cheerDeveloperTitle => isKo ? '개발자 토닥토닥 응원하기' : 'Cheer the Developer';
  String get cheerDeveloperSubtitle => isKo
      ? '짧은 광고 시청으로 지속적인 업데이트를 응원해주세요'
      : 'Watch a short ad to support ongoing development and updates';
  String get cheerThankYouTitle => isKo ? '따뜻한 응원 감사해요!' : 'Thank you for your warm support!';
  String get cheerThankYouSubtitle => isKo
      ? '보내주신 소중한 응원,\n더 좋은 앱으로 보답할게요'
      : 'Your encouragement keeps us building a better app.';
  String get cheerAdLoading => isKo
      ? '보상형 광고를 준비 중입니다. 잠시 후 다시 시도해 주세요.'
      : 'Preparing reward ad... Please try again in a moment.';
  String get proTitle => 'TimeTodo Pro';
  String get proSubtitle => isKo
      ? '더 쾌적한 광고 없는 Pro 버전이 곧 출시됩니다!'
      : 'An ad-free Pro version is coming soon!';
  String get proRemoveAds => isKo ? '광고 완전 제거' : 'Remove All Ads';
  String get proRemoveAdsDesc => isKo
      ? '상단 배너 및 모든 광고가 완전히 사라집니다.'
      : 'Enjoy an uninterrupted experience with zero ads.';
  String get proComingSoonToast => isKo
      ? 'TimeTodo Pro(광고 제거 버전)가 곧 출시될 예정입니다! 기대해 주세요 🚀'
      : 'TimeTodo Pro (Ad-free version) will be available soon! 🚀';

  // --- Color Picker ---
  String get customColorTitle => isKo ? '커스텀 색상 선택' : 'Custom Color';
  String get colorPalette => isKo ? '색상 팔레트' : 'Palette';
  String get colorHue => isKo ? '색상 (Hue)' : 'Hue';
  String get colorSaturation => isKo ? '채도 (Saturation)' : 'Saturation';
  String get colorBrightness => isKo ? '밝기 (Brightness)' : 'Brightness';
  String get applyColor => isKo ? '색상 적용' : 'Apply';

  // --- Date Picker & Deadline ---
  String get deadlineSettingTitle => isKo ? '마감기한 설정' : 'Set Deadline';
  String get deadlineDueToday => isKo ? '오늘 마감' : 'Due today';
  String get deadlineDueTomorrow => isKo ? '내일 마감' : 'Due tomorrow';
  String deadlineOverdue(int days) => isKo ? 'D+$days (지남)' : '$days d overdue';
  String deadlineDueIn(int days) => isKo ? 'D-$days' : 'D-$days';
  String get quickToday => isKo ? '오늘' : 'Today';
  String get quickTomorrow => isKo ? '내일' : 'Tomorrow';
  String get quickThisWeekend => isKo ? '이번 주말' : 'This Weekend';
  String get quickNextWeek => isKo ? '다음 주' : 'Next Week';
  String get quickPlus2Weeks => isKo ? '+2주' : '+2 Weeks';
  String get quickPlus1Month => isKo ? '+1개월' : '+1 Month';
  String get clearDeadline => isKo ? '마감 해제' : 'Clear Deadline';
  String get doneSetting => isKo ? '설정 완료' : 'Done';

  // --- New Record Modal ---
  String get newRecordTitle => isKo ? '새로운 기록' : 'New Record';
  String get newRecordHint => isKo ? '지금 무슨 일이 일어나고 있나요?' : 'What is happening right now?';
  String get saveRecord => isKo ? '기록 완료' : 'Save';

  // --- Ads & Support ---
  String get adPlaybackError => isKo ? '광고를 재생하는 중 문제가 발생했습니다.' : 'An error occurred while playing the ad.';
  String get adUnavailableCheer => isKo
      ? '현재 표시할 수 있는 응원 광고가 없습니다. 마음만으로도 정말 감사드려요 💛'
      : 'No support ads available right now. Thank you so much for your support! 💛';

  // --- Insight Segments & Navigation ---
  String get segmentNight => isKo ? '🌙 새벽' : '🌙 Night';
  String get segmentMorning => isKo ? '🌅 오전' : '🌅 Morning';
  String get segmentAfternoon => isKo ? '☀️ 오후' : '☀️ Afternoon';
  String get segmentEvening => isKo ? '🌆 저녁' : '🌆 Evening';
  String get btnBackToThisMonth => isKo ? '이번 달로' : 'This Month';
  String get btnBackToThisWeek => isKo ? '이번 주로' : 'This Week';
  String get hintTapDateForRecords => isKo ? '날짜를 탭하면 해당 일의 모든 기록 목록을 열람할 수 있습니다' : 'Tap a date to view all records for that day';
  String get hintTouchTimeBlock => isKo ? '시간 블록을 터치하면 해당 시간대의 상세 활동 내역을 볼 수 있습니다' : 'Tap a time block to view detailed activity';
  String get noRecordsOnDate => isKo ? '이 날짜의 기록이 없습니다' : 'No records on this date';
  String get noDataForSelectedPeriod => isKo ? '선택한 기간에 기록된 데이터가 없습니다.' : 'No data recorded for the selected period.';
  String get noRecordedActivity => isKo ? '기록된 활동 없음' : 'No activity recorded';
  String get completedTodoFilter => isKo ? '처리한 TODO' : 'Completed Tasks';
  String get pendingTodoFilter => isKo ? '남은 TODO' : 'Pending Tasks';
}
