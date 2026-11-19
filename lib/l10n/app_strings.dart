import 'package:flutter/widgets.dart';

/// Helper class providing localized strings based on the current active Locale.
/// Defaults to English for all non-Korean locales (ko -> Korean, others -> English).
class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    final loc = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    return AppStrings(loc);
  }

  bool get isKo => locale.languageCode == 'ko';

  // Navigation tabs
  String get tabTasks => isKo ? '할 일' : 'Tasks';
  String get navTimeline => isKo ? '타임라인' : 'Timeline';
  String get navCategory => isKo ? '카테고리' : 'Category';
  String get tabInsights => isKo ? '인사이트' : 'Insights';
  String get tabSettings => isKo ? '설정' : 'Settings';
  String get tabCamera => isKo ? '타임스탬프 카메라' : 'Camera';

  // Common buttons & actions
  String get commonAdd => isKo ? '추가' : 'Add';
  String get commonSave => isKo ? '저장' : 'Save';
  String get commonCancel => isKo ? '취소' : 'Cancel';
  String get commonDelete => isKo ? '삭제' : 'Delete';
  String get commonConfirm => isKo ? '확인' : 'Confirm';
  String get commonDone => isKo ? '완료' : 'Done';
  String get commonEdit => isKo ? '수정' : 'Edit';
  String get commonClose => isKo ? '닫기' : 'Close';
  String get commonRetry => isKo ? '다시 시도' : 'Retry';

  // Pro features
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

  // Cheer developer
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

  // Settings
  String get settingsVersion => isKo ? '버전' : 'Version';
  String get settingsTheme => isKo ? '테마' : 'Theme';
  String get settingsSupport => isKo ? '지원 및 정보' : 'Support & Info';

  // Insights
  String get insightTimeStats => isKo ? '시간 사용 통계' : 'Time Usage Stats';
  String get insightTimeStatsDesc => isKo
      ? '카테고리별 소요 시간과 점유율을 분석합니다'
      : 'Analyze elapsed time and share by category';
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

  // Tasks
  String get todoInputHint => isKo ? '지금 할 일을 입력하세요' : 'What are you doing right now?';
  String get todoEmptyList => isKo
      ? '등록된 할 일이 없습니다. 새로운 할 일을 추가해보세요!'
      : 'No tasks yet. Start by adding one!';
}
