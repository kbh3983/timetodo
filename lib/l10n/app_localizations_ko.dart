// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'TimeTodo';

  @override
  String get tabTasks => '할 일';

  @override
  String get navTimeline => '타임라인';

  @override
  String get navCategory => '카테고리';

  @override
  String get tabInsights => '인사이트';

  @override
  String get tabSettings => '설정';

  @override
  String get tabCamera => '타임스탬프 카메라';

  @override
  String get commonAdd => '추가';

  @override
  String get commonSave => '저장';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonDone => '완료';

  @override
  String get commonEdit => '수정';

  @override
  String get commonClose => '닫기';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get proTitle => 'TimeTodo Pro';

  @override
  String get proSubtitle => '더 쾌적한 광고 없는 Pro 버전이 곧 출시됩니다!';

  @override
  String get proRemoveAds => '광고 완전 제거';

  @override
  String get proRemoveAdsDesc => '상단 배너 및 모든 광고가 완전히 사라집니다.';

  @override
  String get proComingSoonToast =>
      'TimeTodo Pro(광고 제거 버전)가 곧 출시될 예정입니다! 기대해 주세요 🚀';

  @override
  String get cheerDeveloperTitle => '개발자 토닥토닥 응원하기';

  @override
  String get cheerDeveloperSubtitle => '짧은 광고 시청으로 지속적인 업데이트를 응원해주세요';

  @override
  String get cheerThankYouTitle => '따뜻한 응원 감사해요!';

  @override
  String get cheerThankYouSubtitle => '보내주신 소중한 응원,\n더 좋은 앱으로 보답할게요';

  @override
  String get cheerAdLoading => '보상형 광고를 준비 중입니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsSupport => '지원 및 정보';

  @override
  String get insightTimeStats => '시간 사용 통계';

  @override
  String get insightTimeStatsDesc => '카테고리별 소요 시간과 점유율을 분석합니다';

  @override
  String get insight24hPattern => '24시간 활동 패턴';

  @override
  String get insight24hPatternDesc => '언제 가장 활발하게 활동하고 기록하는지 분석합니다';

  @override
  String get insightWeeklyPattern => '요일별 활동 패턴';

  @override
  String get insightWeeklyPatternDesc => '요일별 활동 빈도와 주중/주말 생산성을 비교합니다';

  @override
  String get insightTodoCompletion => 'TODO 달성률';

  @override
  String get insightTodoCompletionDesc => '목표 달성률 및 작업 완료 속도를 분석합니다';

  @override
  String get insightRanking => '활동 시간 랭킹';

  @override
  String get insightRankingDesc => '가장 많은 시간을 투자한 활동 Top 5';

  @override
  String get insightMonthlyTable => '월간 타임 테이블';

  @override
  String get insightMonthlyTableDesc => '세로(날짜 1~31일) × 가로(24시간) 활동 타임라인';

  @override
  String get insightWeeklyTable => '주간 타임 테이블';

  @override
  String get insightWeeklyTableDesc => 'Outlook 스타일 가로(요일) × 세로(시간대) 활동 매트릭스';

  @override
  String get insightCalendar => '활동 캘린더';

  @override
  String get insightCalendarDesc => '월별 활동 일관성 및 날짜별 상세 기록을 확인합니다';

  @override
  String get todoInputHint => '지금 할 일을 입력하세요';

  @override
  String get todoEmptyList => '등록된 할 일이 없습니다. 새로운 할 일을 추가해보세요!';
}
