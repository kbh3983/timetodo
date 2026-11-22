import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'camera_page.dart';
import 'lockscreen_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_strings.dart';
import 'l10n/app_localizations.dart';
import 'app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('ko', null);
    await initializeDateFormatting('en', null);
  } catch (_) {}
  await ThemeController.instance.init();
  await LockScreenNotificationService.instance.init();
  if (!kIsProVersion) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds initialization error: $e');
    }
  }
  runApp(const ChronosApp());
}

/// 앱 버전 설정 (lib/app_config.dart 에서 설정)
/// - false: 무료 버전 (광고 포함)
/// - true: 유료 Pro 버전 (광고 완전 제거)
const bool kIsProVersion = AppConfig.isProVersion;

/// 유료 Pro 버전 스토어 링크 (설정에서 연결될 URL)
const String kProAppStoreUrl = 'https://play.google.com/store/apps/details?id=com.bebong.timetodo.pro';

class AppTheme {
  final String id;
  final String name;
  final Color scaffoldBg;
  final Color cardBg;
  final Color surfaceBg;
  final Color accent;
  final bool isDark;

  const AppTheme({
    required this.id,
    required this.name,
    required this.scaffoldBg,
    required this.cardBg,
    required this.surfaceBg,
    required this.accent,
    this.isDark = true,
  });

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0F172A);
  Color get textSecondary => isDark ? Colors.white70 : const Color(0xFF475569);
  Color get textTertiary => isDark ? Colors.white38 : const Color(0xFF94A3B8);
  Color get textColor => textPrimary;
  Color get cardBorder =>
      isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
}

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  static const List<AppTheme> themes = [
    // Dark Themes
    AppTheme(
      id: 'navy',
      name: 'Deep Navy',
      scaffoldBg: Color(0xFF080D1A),
      cardBg: Color(0xFF0F172A),
      surfaceBg: Color(0xFF1E293B),
      accent: Color(0xFF38BDF8),
      isDark: true,
    ),
    AppTheme(
      id: 'obsidian',
      name: 'Obsidian Dark',
      scaffoldBg: Color(0xFF0D0F14),
      cardBg: Color(0xFF161922),
      surfaceBg: Color(0xFF232832),
      accent: Color(0xFF6366F1),
      isDark: true,
    ),
    AppTheme(
      id: 'oled',
      name: 'Midnight OLED',
      scaffoldBg: Color(0xFF000000),
      cardBg: Color(0xFF0E0E12),
      surfaceBg: Color(0xFF1A1A22),
      accent: Color(0xFF6366F1),
      isDark: true,
    ),
    AppTheme(
      id: 'forest',
      name: 'Forest Charcoal',
      scaffoldBg: Color(0xFF0A130E),
      cardBg: Color(0xFF112217),
      surfaceBg: Color(0xFF1B3325),
      accent: Color(0xFF10B981),
      isDark: true,
    ),
    AppTheme(
      id: 'purple',
      name: 'Cyber Violet',
      scaffoldBg: Color(0xFF120D1D),
      cardBg: Color(0xFF1E152F),
      surfaceBg: Color(0xFF2E2047),
      accent: Color(0xFFA855F7),
      isDark: true,
    ),

    // Light Themes
    AppTheme(
      id: 'clean_white',
      name: 'Clean White',
      scaffoldBg: Color(0xFFF8FAFC),
      cardBg: Color(0xFFFFFFFF),
      surfaceBg: Color(0xFFF1F5F9),
      accent: Color(0xFF4F46E5),
      isDark: false,
    ),
    AppTheme(
      id: 'warm_cream',
      name: 'Warm Cream',
      scaffoldBg: Color(0xFFFDFBF7),
      cardBg: Color(0xFFFFFFFF),
      surfaceBg: Color(0xFFF5EFE6),
      accent: Color(0xFFD97706),
      isDark: false,
    ),
    AppTheme(
      id: 'nordic_frost',
      name: 'Nordic Frost',
      scaffoldBg: Color(0xFFF0F4F8),
      cardBg: Color(0xFFFFFFFF),
      surfaceBg: Color(0xFFE2E8F0),
      accent: Color(0xFF0284C7),
      isDark: false,
    ),
    AppTheme(
      id: 'soft_rose',
      name: 'Soft Rose',
      scaffoldBg: Color(0xFFFFF5F7),
      cardBg: Color(0xFFFFFFFF),
      surfaceBg: Color(0xFFFFE4E8),
      accent: Color(0xFFE11D48),
      isDark: false,
    ),
  ];

  String _currentThemeId = 'navy';
  String get currentThemeId => _currentThemeId;

  int? _customAccentValue;
  Color? get customAccent =>
      _customAccentValue != null ? Color(_customAccentValue!) : null;

  double _gradientIntensity = 0.28;
  double get gradientIntensity => _gradientIntensity;

  AppTheme get currentTheme {
    final base = themes.firstWhere(
      (t) => t.id == _currentThemeId,
      orElse: () => themes.first,
    );
    if (_customAccentValue != null) {
      return AppTheme(
        id: base.id,
        name: base.name,
        scaffoldBg: base.scaffoldBg,
        cardBg: base.cardBg,
        surfaceBg: base.surfaceBg,
        accent: Color(_customAccentValue!),
        isDark: base.isDark,
      );
    }
    return base;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('chronos_theme_id');
    if (saved != null && themes.any((t) => t.id == saved)) {
      _currentThemeId = saved;
    } else {
      _currentThemeId = 'navy';
    }
    _customAccentValue = prefs.getInt('chronos_custom_accent');
    _gradientIntensity = prefs.getDouble('chronos_gradient_intensity') ?? 0.28;
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    if (_currentThemeId == id) return;
    _currentThemeId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chronos_theme_id', id);
  }

  Future<void> setCustomAccent(Color? color) async {
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      _customAccentValue = null;
      await prefs.remove('chronos_custom_accent');
    } else {
      _customAccentValue = color.value;
      await prefs.setInt('chronos_custom_accent', color.value);
    }
    notifyListeners();
  }

  Future<void> setGradientIntensity(double intensity) async {
    _gradientIntensity = intensity.clamp(0.0, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('chronos_gradient_intensity', _gradientIntensity);
  }
}

AppTheme get appTheme => ThemeController.instance.currentTheme;
bool get isAppDark => ThemeController.instance.currentTheme.isDark;
Color get appText => isAppDark ? Colors.white : const Color(0xFF0F172A);
Color get appTextSecondary =>
    isAppDark ? Colors.white.withOpacity(0.65) : const Color(0xFF475569);
Color get appTextTertiary =>
    isAppDark ? Colors.white.withOpacity(0.4) : const Color(0xFF94A3B8);
Color get appCardBg => ThemeController.instance.currentTheme.cardBg;
Color get appSubtleBg =>
    isAppDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
Color get appBorder =>
    isAppDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.08);

class ChronosApp extends StatelessWidget {
  const ChronosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.currentTheme;
        final isDark = theme.isDark;
        return MaterialApp(
          title: 'TimeTodo',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko'),
          ],
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale != null && deviceLocale.languageCode == 'ko') {
              return const Locale('ko');
            }
            return const Locale('en'); // Default to English for all non-Korean locales!
          },
          theme: ThemeData(
            useMaterial3: true,
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: theme.scaffoldBg,
            cardColor: theme.cardBg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.accent,
              brightness: isDark ? Brightness.dark : Brightness.light,
              surface: theme.cardBg,
              primary: theme.accent,
            ),
            textTheme: GoogleFonts.interTextTheme(
              isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
            ),
          ),
          home: const MainNavigation(),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  final GlobalKey<_HomePageState> _homePageKey = GlobalKey<_HomePageState>();
  int _selectedIndex = 0;
  List<TimestampEntry> _entries = [];
  double _uiScale = 1.0; // Default to 1.0 ('보통')
  late ValueNotifier<List<TimestampEntry>> _entriesNotifier;
  final ImagePicker _picker = ImagePicker();

  Map<String, Color> _categoryIndicatorColors = {
    'General': const Color(0xFF6366F1),
  };
  String _defaultCategory = 'General';
  bool _isLoadingRewardedAd = false;

  List<String> get _categories => _categoryIndicatorColors.keys.toList();

  Color _getCategoryColor(String category) {
    return _categoryIndicatorColors[category] ?? const Color(0xFF64748B);
  }

  bool _lockScreenTodoEnabled = true;
  bool _deadlineAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LockScreenNotificationService.onEntriesUpdatedExternally = () {
      if (mounted) {
        _loadEntries();
      }
    };

    // 잠금화면 알림 실시간 동기화 브로드캐스트 수신
    if (Platform.isAndroid) {
      const platform = MethodChannel('com.bebong.timetodo/lockscreen');
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onEntriesUpdatedExternally') {
          if (mounted) {
            _loadEntries();
          }
        }
      });
    }

    _entriesNotifier = ValueNotifier<List<TimestampEntry>>([]);
    _loadCategories().then((_) => _loadEntries());
    _loadUiScale();
    _loadLockScreenSetting();
    ThemeController.instance.addListener(_onThemeChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadEntries();
      _loadLockScreenSetting();
    }
  }

  Future<void> _loadLockScreenSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _lockScreenTodoEnabled =
        prefs.getBool('chronos_lockscreen_todo_enabled') ?? true;
    _deadlineAlertsEnabled =
        prefs.getBool('chronos_deadline_alerts_enabled') ?? true;
    _updateLockScreenNotification();
  }

  Timer? _notificationDebounceTimer;

  void _updateLockScreenNotification() {
    _notificationDebounceTimer?.cancel();
    _notificationDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      LockScreenNotificationService.instance.updateTopTodo(
        _entries,
        enabled: _lockScreenTodoEnabled,
        deadlineAlertsEnabled: _deadlineAlertsEnabled,
      );
    });
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? catsJson = prefs.getString('chronos_categories');
    final String? savedDefault = prefs.getString('chronos_default_category');
    if (catsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(catsJson);
      final Map<String, Color> loaded = decoded.map(
        (key, value) => MapEntry(key, Color(value as int)),
      );
      setState(() {
        _categoryIndicatorColors = loaded.isNotEmpty
            ? loaded
            : {'General': const Color(0xFF6366F1)};
        if (savedDefault != null && _categoryIndicatorColors.containsKey(savedDefault)) {
          _defaultCategory = savedDefault;
        } else {
          _defaultCategory = _categoryIndicatorColors.keys.first;
        }
      });
    } else {
      setState(() {
        _categoryIndicatorColors = {
          'General': const Color(0xFF6366F1),
        };
        _defaultCategory = 'General';
      });
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> encoded = _categoryIndicatorColors.map(
      (key, value) => MapEntry(key, value.value),
    );
    await prefs.setString('chronos_categories', jsonEncode(encoded));
    await prefs.setString('chronos_default_category', _defaultCategory);
  }

  void _addCategory(String name, Color color) {
    setState(() {
      _categoryIndicatorColors[name] = color;
    });
    _saveCategories();
  }

  void _updateCategoryColor(String name, Color newColor) {
    setState(() {
      _categoryIndicatorColors[name] = newColor;
    });
    _saveCategories();
  }

  void _setDefaultCategory(String category) {
    if (!_categoryIndicatorColors.containsKey(category)) return;
    setState(() {
      _defaultCategory = category;
    });
    _saveCategories();
  }

  void _reorderCategories(int oldIndex, int newIndex) {
    final keys = _categoryIndicatorColors.keys.toList();
    if (oldIndex < 0 || oldIndex >= keys.length) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (newIndex < 0 || newIndex >= keys.length) return;
    final item = keys.removeAt(oldIndex);
    keys.insert(newIndex, item);

    final Map<String, Color> newMap = {};
    for (final k in keys) {
      newMap[k] = _categoryIndicatorColors[k]!;
    }
    setState(() {
      _categoryIndicatorColors = newMap;
    });
    _saveCategories();
  }

  bool _renameCategory(String oldName, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return false;
    if (_categoryIndicatorColors.containsKey(trimmed)) return false;

    final color = _categoryIndicatorColors[oldName] ?? const Color(0xFF6366F1);
    final Map<String, Color> newColors = {};
    for (final entry in _categoryIndicatorColors.entries) {
      if (entry.key == oldName) {
        newColors[trimmed] = color;
      } else {
        newColors[entry.key] = entry.value;
      }
    }

    setState(() {
      _categoryIndicatorColors = newColors;
      if (_defaultCategory == oldName) {
        _defaultCategory = trimmed;
      }
      _entries = _entries.map((e) {
        if (e.category == oldName) {
          return e.copyWith(category: trimmed);
        }
        return e;
      }).toList();
      _entriesNotifier.value = List.from(_entries);
    });
    _saveCategories();
    _saveEntries();
    return true;
  }

  void _deleteCategory(String category) {
    if (category == 'General') return;
    setState(() {
      _categoryIndicatorColors.remove(category);
      if (_defaultCategory == category) {
        _defaultCategory = _categoryIndicatorColors.keys.isNotEmpty
            ? _categoryIndicatorColors.keys.first
            : 'General';
      }
      _entries.removeWhere((e) => e.category == category);
      _entriesNotifier.value = List.from(_entries);
    });
    _saveCategories();
    _saveEntries();
  }

  Future<void> _loadUiScale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _uiScale = prefs.getDouble('ui_scale') ?? 1.0;
    });
  }

  Future<void> _saveUiScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ui_scale', scale);
    setState(() {
      _uiScale = scale;
    });
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedBuilder(
          animation: ThemeController.instance,
          builder: (context, _) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                final currentTheme = ThemeController.instance.currentTheme;
                final strings = AppStrings.of(context);
                final isDark = currentTheme.isDark;
                final bottomPadding = MediaQuery.of(context).padding.bottom;

            Widget buildSectionHeader(String title, {bool isFirst = false}) {
              return Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8, top: isFirst ? 0 : 20),
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              );
            }

            Widget buildGroupCard({required List<Widget> children}) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < children.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                        ),
                      children[i],
                    ],
                  ],
                ),
              );
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: currentTheme.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 드래그 핸들 (아래로 쓸어내리면 닫힘)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta! > 6) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Compact Header (Identical to + button Add Sheet)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: currentTheme.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: currentTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.settingsTitle,
                            style: GoogleFonts.inter(
                              fontSize: 18 * _uiScale,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: currentTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: currentTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is OverscrollNotification &&
                              notification.overscroll < -15) {
                            Navigator.pop(context);
                            return true;
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 28 + bottomPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!kIsProVersion) ...[
                                // ------------------------------------------
                                // 0. 유료 Pro 버전 업그레이드 배너
                                // ------------------------------------------
                                InkWell(
                                  onTap: () {
                                    _showProVersionSheet(context);
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                            : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B).withOpacity(0.4),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFF59E0B).withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.workspace_premium_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'TimeTodo Pro',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: -0.2,
                                                      color: currentTheme.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF59E0B),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'PRO',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                strings.proSubtitle,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: currentTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: const Color(0xFFF59E0B),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],

                              // ------------------------------------------
                              // 1. 화면 스타일
                              // ------------------------------------------
                              buildSectionHeader(strings.isKo ? '화면 스타일' : 'Screen Style', isFirst: true),
                              buildGroupCard(
                                children: [
                                  // 테마 선택 가로 스크롤
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Row(
                                        children: ThemeController.themes.map((theme) {
                                          final isSelected = ThemeController.instance.currentThemeId == theme.id;
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 10),
                                            child: InkWell(
                                              onTap: () {
                                                ThemeController.instance.setTheme(theme.id);
                                                setSheetState(() {});
                                              },
                                              borderRadius: BorderRadius.circular(14),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 180),
                                                width: 108,
                                                height: 66,
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: theme.scaffoldBg,
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? theme.accent
                                                        : (theme.isDark
                                                            ? Colors.white.withOpacity(0.08)
                                                            : Colors.black.withOpacity(0.08)),
                                                    width: isSelected ? 2.0 : 1.0,
                                                  ),
                                                  boxShadow: isSelected
                                                      ? [
                                                          BoxShadow(
                                                            color: theme.accent.withOpacity(0.3),
                                                            blurRadius: 6,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Container(
                                                          width: 14,
                                                          height: 14,
                                                          decoration: BoxDecoration(
                                                            color: theme.accent,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        if (isSelected)
                                                          Icon(
                                                            Icons.check_circle_rounded,
                                                            size: 15,
                                                            color: theme.accent,
                                                          )
                                                        else
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 4, vertical: 1.5),
                                                            decoration: BoxDecoration(
                                                              color: theme.isDark
                                                                  ? Colors.white.withOpacity(0.08)
                                                                  : Colors.black.withOpacity(0.06),
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: Text(
                                                              theme.isDark ? 'DARK' : 'LIGHT',
                                                              style: GoogleFonts.jetBrainsMono(
                                                                fontSize: 8,
                                                                fontWeight: FontWeight.w700,
                                                                color: theme.isDark
                                                                    ? Colors.white60
                                                                    : const Color(0xFF64748B),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    Text(
                                                      theme.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            isSelected ? FontWeight.w800 : FontWeight.w600,
                                                        color: theme.isDark
                                                            ? Colors.white
                                                            : const Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),

                                  // 테마 포인트 색상
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: currentTheme.accent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? Colors.white30 : Colors.black12,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: currentTheme.accent.withOpacity(0.35),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            strings.isKo ? '포인트 색상' : 'Accent Color',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: currentTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (ThemeController.instance.customAccent != null) ...[
                                          TextButton(
                                            onPressed: () {
                                              ThemeController.instance.setCustomAccent(null);
                                              setSheetState(() {});
                                            },
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              strings.resetPreset,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: currentTheme.textTertiary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        InkWell(
                                          onTap: () async {
                                            final picked = await showCustomColorPickerDialog(
                                              context,
                                              initialColor: currentTheme.accent,
                                            );
                                            if (picked != null) {
                                              await ThemeController.instance.setCustomAccent(picked);
                                              setSheetState(() {});
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: currentTheme.accent.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: currentTheme.accent.withOpacity(0.25),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.colorize_rounded,
                                                  size: 13,
                                                  color: currentTheme.accent,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  strings.isKo ? '색상 변경' : 'Change',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: currentTheme.accent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 배경 그라데이션
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              strings.isKo ? '배경 그라데이션' : 'Background Gradient',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: currentTheme.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              '${(ThemeController.instance.gradientIntensity * 100).round()}%',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: currentTheme.accent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            _buildGradientIntensityChip(context, 'OFF', 0.0, setSheetState),
                                            const SizedBox(width: 6),
                                            _buildGradientIntensityChip(context, strings.isKo ? '은은하게' : 'Subtle', 0.15, setSheetState),
                                            const SizedBox(width: 6),
                                            _buildGradientIntensityChip(context, strings.scaleNormal, 0.28, setSheetState),
                                            const SizedBox(width: 6),
                                            _buildGradientIntensityChip(context, strings.isKo ? '선명하게' : 'Vivid', 0.45, setSheetState),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // ------------------------------------------
                              // 2. 화면 및 글자 크기
                              // ------------------------------------------
                              buildSectionHeader(strings.settingsUiScale),
                              buildGroupCard(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              strings.settingsUiScale,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: currentTheme.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              '${(_uiScale * 100).toInt()}%',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: currentTheme.accent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            _buildScaleSegment(context, strings.scaleSmall, 0.8, setSheetState),
                                            const SizedBox(width: 6),
                                            _buildScaleSegment(context, strings.isKo ? '조금 작게' : 'Compact', 0.9, setSheetState),
                                            const SizedBox(width: 6),
                                            _buildScaleSegment(context, strings.scaleNormal, 1.0, setSheetState),
                                            const SizedBox(width: 6),
                                            _buildScaleSegment(context, strings.scaleLarge, 1.1, setSheetState),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // ------------------------------------------
                              // 3. 알림 및 잠금화면
                              // ------------------------------------------
                              buildSectionHeader(strings.isKo ? '알림 및 잠금화면' : 'Notifications & Lockscreen'),
                              buildGroupCard(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.lock_clock_outlined,
                                          size: 20,
                                          color: currentTheme.accent,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            strings.isKo ? '잠금화면 최우선 TODO' : 'Lockscreen Top TODO',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: currentTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: _lockScreenTodoEnabled,
                                          activeColor: currentTheme.accent,
                                          onChanged: (val) async {
                                            setState(() {
                                              _lockScreenTodoEnabled = val;
                                            });
                                            setSheetState(() {});
                                            final prefs = await SharedPreferences.getInstance();
                                            await prefs.setBool('chronos_lockscreen_todo_enabled', val);
                                            _updateLockScreenNotification();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.notifications_active_outlined,
                                          size: 20,
                                          color: currentTheme.accent,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            strings.isKo ? '마감 알림 (D-3 ~ 마감일)' : 'Deadline Alerts (D-3 ~ Due Date)',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: currentTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: _deadlineAlertsEnabled,
                                          activeColor: currentTheme.accent,
                                          onChanged: (val) async {
                                            setState(() {
                                              _deadlineAlertsEnabled = val;
                                            });
                                            setSheetState(() {});
                                            final prefs = await SharedPreferences.getInstance();
                                            await prefs.setBool('chronos_deadline_alerts_enabled', val);
                                            _updateLockScreenNotification();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // ------------------------------------------
                              // 4. 지원 및 정보
                              // ------------------------------------------
                              buildSectionHeader(strings.settingsSupport),
                              buildGroupCard(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      _showSupportRewardedAd(context);
                                    },
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.favorite_rounded,
                                            color: Color(0xFFEF4444),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              strings.cheerDeveloperTitle,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: currentTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 20,
                                            color: currentTheme.textTertiary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 19,
                                          color: currentTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            strings.settingsVersion,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: currentTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '1.0.0',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: currentTheme.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
              },
            );
          },
        );
      },
    );
  }

  void _showProVersionSheet(BuildContext parentContext) {
    final theme = ThemeController.instance.currentTheme;
    final isDark = theme.isDark;

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: theme.cardBg,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! > 7) {
                      Navigator.pop(context);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'TimeTodo Pro',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    AppStrings.of(parentContext).proSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildProBenefitRow(
                        Icons.block_rounded,
                        AppStrings.of(parentContext).proRemoveAds,
                        AppStrings.of(parentContext).proRemoveAdsDesc,
                        const Color(0xFFEF4444),
                        theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppStrings.of(parentContext).proComingSoonToast,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFFF59E0B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      AppStrings.of(parentContext).isKo ? '곧 출시될 예정이에요' : 'Coming Soon',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProBenefitRow(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    AppTheme theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCheerThankYouSheet(BuildContext sheetContext) {
    if (!mounted) return;
    final theme = ThemeController.instance.currentTheme;
    final isDark = theme.isDark;
    final targetContext = mounted ? this.context : sheetContext;
    final strings = AppStrings.of(targetContext);

    showModalBottomSheet(
      context: targetContext,
      backgroundColor: theme.cardBg,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 14, 24, 24 + bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Heart badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFEF4444),
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  strings.cheerThankYouTitle,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: theme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  strings.cheerThankYouSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: theme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: theme.accent.computeLuminance() > 0.6 ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      strings.isKo ? '마음이 잘 전달되었어요' : 'You are wonderful!',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSupportRewardedAd(BuildContext context) {
    if (kIsProVersion) {
      _showCheerThankYouSheet(context);
      return;
    }
    if (_isLoadingRewardedAd) return;
    _isLoadingRewardedAd = true;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final strings = AppStrings.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              strings.cheerAdLoading,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final adUnitId = AdHelper.rewardedAdUnitId;
    if (adUnitId.isEmpty) {
      _isLoadingRewardedAd = false;
      return;
    }

    bool userEarnedReward = false;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _isLoadingRewardedAd = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              // 광고 화면이 닫히고 플러터 화면으로 복귀한 직후 하단 팝업 띄우기
              if (userEarnedReward) {
                _showCheerThankYouSheet(context);
              }
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    strings.adPlaybackError,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          );

          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              userEarnedReward = true;
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoadingRewardedAd = false;
          debugPrint('RewardedAd failed to load: $error');
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                strings.adUnavailableCheer,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF64748B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScaleSegment(
    BuildContext context,
    String label,
    double scale,
    StateSetter setSheetState,
  ) {
    bool isSelected = (_uiScale - scale).abs() < 0.01;
    final currentTheme = ThemeController.instance.currentTheme;
    final isDark = currentTheme.isDark;
    return Expanded(
      child: InkWell(
        onTap: () {
          _saveUiScale(scale);
          setSheetState(() {});
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? currentTheme.accent
                : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? currentTheme.accent
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08)),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (currentTheme.accent.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white)
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaleOption(BuildContext context, String label, double scale) {
    bool isSelected = (_uiScale - scale).abs() < 0.01;
    final isDark = ThemeController.instance.currentTheme.isDark;
    return GestureDetector(
      onTap: () {
        _saveUiScale(scale);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : (isDark ? const Color(0xFF232832) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : (isDark ? Colors.transparent : Colors.black.withOpacity(0.06)),
              ),
            ),
            child: Text(
              '${(scale * 100).toInt()}%',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF475569)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? Colors.white.withOpacity(0.3) : const Color(0xFF94A3B8)),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientIntensityChip(
    BuildContext context,
    String label,
    double value,
    StateSetter setSheetState,
  ) {
    final currentTheme = ThemeController.instance.currentTheme;
    final isSelected =
        (ThemeController.instance.gradientIntensity - value).abs() < 0.05;
    final isDark = currentTheme.isDark;
    return Expanded(
      child: InkWell(
        onTap: () {
          ThemeController.instance.setGradientIntensity(value);
          setSheetState(() {});
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? currentTheme.accent
                : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? currentTheme.accent
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08)),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (currentTheme.accent.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white)
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationDebounceTimer?.cancel();
    ThemeController.instance.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    LockScreenNotificationService.onEntriesUpdatedExternally = null;
    _entriesNotifier.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final String? entriesJson = prefs.getString('chronos_entries');
    if (entriesJson != null) {
      final List<dynamic> decoded = jsonDecode(entriesJson);
      setState(() {
        _entries = decoded
            .map((item) => TimestampEntry.fromJson(item))
            .toList();
        _entriesNotifier.value = _entries;
      });
      _updateLockScreenNotification();
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString('chronos_entries', encoded);
  }

  void _onEntriesChanged(List<TimestampEntry> newEntries) {
    setState(() {
      _entries = newEntries;
      _entriesNotifier.value = _entries;
    });
    _saveEntries();
    _updateLockScreenNotification();
  }

  Future<String?> _saveImage(File? image) async {
    if (image == null) return null;
    final directory = await getApplicationDocumentsDirectory();
    final fileName = path.basename(image.path);
    final savedImage = await image.copy('${directory.path}/$fileName');
    return savedImage.path;
  }

  void _deleteEntry(String id) {
    final updatedEntries = List<TimestampEntry>.from(_entries);
    updatedEntries.removeWhere((e) => e.id == id);
    _onEntriesChanged(updatedEntries);
  }

  void _clearCategory(String category) {
    final updatedEntries = List<TimestampEntry>.from(_entries);
    updatedEntries.removeWhere((e) => e.category == category);
    _onEntriesChanged(updatedEntries);
  }

  Future<void> _showDoneCompletionSheet(TimestampEntry entry) async {
    final TextEditingController doneNoteController = TextEditingController();
    File? doneImage;

    final now = DateTime.now();
    final previewSessions = List<TimeSegment>.from(entry.workSessions);
    if (previewSessions.isNotEmpty && previewSessions.last.end == null) {
      previewSessions[previewSessions.length - 1] = previewSessions.last.copyWith(end: now);
    } else if (entry.isInProgress) {
      final start = entry.lastResumedTimestamp ?? entry.startedTimestamp ?? now;
      previewSessions.add(TimeSegment(start: start, end: now));
    }
    int totalSec = 0;
    for (final s in previewSessions) {
      if (s.end != null) totalSec += s.end!.difference(s.start).inSeconds;
    }
    if (totalSec == 0 && entry.totalActiveSeconds > 0) {
      totalSec = entry.totalActiveSeconds;
    }
    int initialMinutes = (totalSec / 60).round();
    if (initialMinutes == 0 && totalSec > 0) {
      initialMinutes = 1;
    } else if (initialMinutes == 0 && entry.manualDurationMinutes != null) {
      initialMinutes = entry.manualDurationMinutes!;
    }

    bool isManualMode = entry.isManualDuration;
    int manualHours = 0;
    int manualMinutes = 0;
    int manualSeconds = 0;

    if (entry.manualDurationSeconds != null && entry.manualDurationSeconds! > 0) {
      final ms = entry.manualDurationSeconds!;
      manualHours = ms ~/ 3600;
      manualMinutes = (ms % 3600) ~/ 60;
      manualSeconds = ms % 60;
    } else if (entry.manualDurationMinutes != null && entry.manualDurationMinutes! > 0) {
      final mm = entry.manualDurationMinutes!;
      manualHours = mm ~/ 60;
      manualMinutes = mm % 60;
      manualSeconds = 0;
    } else if (totalSec > 0) {
      manualHours = totalSec ~/ 3600;
      manualMinutes = (totalSec % 3600) ~/ 60;
      manualSeconds = totalSec % 60;
    } else if (initialMinutes > 0) {
      manualHours = initialMinutes ~/ 60;
      manualMinutes = initialMinutes % 60;
      manualSeconds = 0;
    }

    final TextEditingController manualHoursController =
        TextEditingController(text: manualHours > 0 ? manualHours.toString() : '');
    final TextEditingController manualMinutesController =
        TextEditingController(text: manualMinutes > 0 ? manualMinutes.toString() : '');
    final TextEditingController manualSecondsController =
        TextEditingController(text: manualSeconds > 0 ? manualSeconds.toString() : '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final s = AppStrings.of(context);
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
          final double effectiveBottom =
              bottomInset > 0 ? bottomInset + 10 : (bottomPadding > 0 ? bottomPadding + 6 : 14.0);
          final categoryColor = _getCategoryColor(entry.category);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: appCardBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // iOS Style Handle Bar with swipe-down to dismiss
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 7) {
                        Navigator.pop(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isAppDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo is OverscrollNotification && scrollInfo.overscroll < -15) {
                          Navigator.pop(context);
                          return true;
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20, 0, 20, effectiveBottom),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                      // Compact Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.task_alt_rounded,
                              size: 16,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.of(context).doneSheetTitle,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: appText,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: appSubtleBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: appTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.of(context).doneSheetSubtitle,
                        style: GoogleFonts.inter(
                          color: appTextTertiary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Image Preview
                      if (doneImage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  doneImage!,
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => doneImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Note Input (Compact)
                      TextField(
                        controller: doneNoteController,
                        autofocus: true,
                        maxLines: 4,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        style: GoogleFonts.inter(fontSize: 14, color: appText),
                        decoration: InputDecoration(
                          hintText: AppStrings.of(context).doneNoteHint,
                          hintStyle: GoogleFonts.inter(fontSize: 13.5, color: appTextTertiary),
                          filled: true,
                          fillColor: appSubtleBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.camera_alt_outlined, size: 19),
                                color: categoryColor,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  final String? captured = await Navigator.push<String>(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CameraPage()),
                                  );
                                  if (captured != null) {
                                    setSheetState(() => doneImage = File(captured));
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.photo_library_outlined, size: 19),
                                color: categoryColor,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
                                  if (img != null) setSheetState(() => doneImage = File(img.path));
                                },
                              ),
                              const SizedBox(width: 6),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Duration Section: Measured or Manual input
                      if (!isManualMode)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setSheetState(() => isManualMode = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: categoryColor.withOpacity(0.2),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 16, color: categoryColor),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.of(context).measuredWorkTime,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: appTextSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  (totalSec > 0 || initialMinutes > 0)
                                      ? formatSecondsKo(totalSec > 0 ? totalSec : initialMinutes * 60)
                                      : AppStrings.of(context).addTime,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: (totalSec > 0 || initialMinutes > 0) ? categoryColor : appTextTertiary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 15,
                                  color: categoryColor.withOpacity(0.85),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: categoryColor.withOpacity(0.35),
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.edit_note_rounded, size: 16, color: categoryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.of(context).manualWorkTimeInput,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: appTextSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (totalSec > 0 || initialMinutes > 0)
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        setSheetState(() {
                                          isManualMode = false;
                                          if (totalSec > 0) {
                                            manualHours = totalSec ~/ 3600;
                                            manualMinutes = (totalSec % 3600) ~/ 60;
                                            manualSeconds = totalSec % 60;
                                          } else if (initialMinutes > 0) {
                                            manualHours = initialMinutes ~/ 60;
                                            manualMinutes = initialMinutes % 60;
                                            manualSeconds = 0;
                                          }
                                          manualHoursController.text = manualHours > 0 ? manualHours.toString() : '';
                                          manualMinutesController.text = manualMinutes > 0 ? manualMinutes.toString() : '';
                                          manualSecondsController.text = manualSeconds > 0 ? manualSeconds.toString() : '';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isAppDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.restart_alt_rounded, size: 12, color: appTextSecondary),
                                            const SizedBox(width: 3),
                                            Text(
                                              AppStrings.of(context).restoreMeasured,
                                              style: GoogleFonts.inter(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: appTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  // Hours
                                  Expanded(
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isAppDark ? Colors.white.withOpacity(0.04) : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: appBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: manualHoursController,
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 13,
                                                color: appText,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: '0',
                                                hintStyle: TextStyle(color: appTextTertiary),
                                                border: InputBorder.none,
                                                isDense: true,
                                              ),
                                              onChanged: (val) {
                                                final p = int.tryParse(val) ?? 0;
                                                setSheetState(() => manualHours = p.clamp(0, 999));
                                              },
                                            ),
                                          ),
                                          Text(AppStrings.of(context).unitHour, style: GoogleFonts.inter(fontSize: 11, color: appTextTertiary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Minutes
                                  Expanded(
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isAppDark ? Colors.white.withOpacity(0.04) : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: appBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: manualMinutesController,
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 13,
                                                color: appText,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: '0',
                                                hintStyle: TextStyle(color: appTextTertiary),
                                                border: InputBorder.none,
                                                isDense: true,
                                              ),
                                              onChanged: (val) {
                                                final p = int.tryParse(val) ?? 0;
                                                setSheetState(() => manualMinutes = p.clamp(0, 59));
                                              },
                                            ),
                                          ),
                                          Text(AppStrings.of(context).unitMinute, style: GoogleFonts.inter(fontSize: 11, color: appTextTertiary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Seconds
                                  Expanded(
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isAppDark ? Colors.white.withOpacity(0.04) : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: appBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: manualSecondsController,
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 13,
                                                color: appText,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: '0',
                                                hintStyle: TextStyle(color: appTextTertiary),
                                                border: InputBorder.none,
                                                isDense: true,
                                              ),
                                              onChanged: (val) {
                                                final p = int.tryParse(val) ?? 0;
                                                setSheetState(() => manualSeconds = p.clamp(0, 59));
                                              },
                                            ),
                                          ),
                                          Text(AppStrings.of(context).unitSecond, style: GoogleFonts.inter(fontSize: 11, color: appTextTertiary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    AppStrings.of(context).inputDurationLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: appTextTertiary,
                                    ),
                                  ),
                                  Text(
                                    formatSecondsKo((manualHours * 3600) + (manualMinutes * 60) + manualSeconds),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Action Buttons Row (Compact Cancel + Wide Main Button)
                      Row(
                        children: [
                          SizedBox(
                            width: 76,
                            height: 46,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                backgroundColor: appSubtleBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                AppStrings.of(context).commonCancel,
                                style: GoogleFonts.inter(
                                  color: appTextSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final String? savedPath = await _saveImage(doneImage);
                                  final updatedEntries = List<TimestampEntry>.from(_entries);
                                  final index = updatedEntries.indexWhere((e) => e.id == entry.id);
                                  if (index != -1) {
                                    final saveTime = DateTime.now();
                                    final finalSessions = List<TimeSegment>.from(entry.workSessions);
                                    if (finalSessions.isNotEmpty && finalSessions.last.end == null) {
                                      finalSessions[finalSessions.length - 1] =
                                          finalSessions.last.copyWith(end: saveTime);
                                    } else if (entry.isInProgress) {
                                      final start = entry.lastResumedTimestamp ?? entry.startedTimestamp ?? saveTime;
                                      finalSessions.add(TimeSegment(start: start, end: saveTime));
                                    }
                                    int finalActiveSec = 0;
                                    for (final s in finalSessions) {
                                      if (s.end != null) {
                                        finalActiveSec += s.end!.difference(s.start).inSeconds;
                                      }
                                    }
                                    if (finalActiveSec == 0 && entry.totalActiveSeconds > 0) {
                                      finalActiveSec = entry.totalActiveSeconds;
                                    }

                                    int? manualDurationSec;
                                    if (isManualMode) {
                                      final calcSec = (manualHours * 3600) + (manualMinutes * 60) + manualSeconds;
                                      if (calcSec > 0) {
                                        manualDurationSec = calcSec;
                                      }
                                    }

                                    updatedEntries[index] = entry.copyWith(
                                      status: 'done',
                                      doneTimestamp: saveTime,
                                      doneNote: doneNoteController.text.trim(),
                                      doneImagePath: savedPath,
                                      workSessions: finalSessions,
                                      totalActiveSeconds: finalActiveSec,
                                      manualDurationSeconds: manualDurationSec,
                                      manualDurationMinutes: manualDurationSec != null ? (manualDurationSec / 60).round() : null,
                                      clearManualDuration: !isManualMode || manualDurationSec == null,
                                      clearLastResumedTimestamp: true,
                                    );
                                    _onEntriesChanged(updatedEntries);
                                  }
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: categoryColor,
                                  foregroundColor: categoryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(
                                  AppStrings.of(context).saveCompletion,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
      ),
    );
  }

  Future<void> _showRevertConfirmSheet(TimestampEntry entry) async {
    final categoryColor = _getCategoryColor(entry.category);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        return Container(
          decoration: BoxDecoration(
            color: appCardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // iOS Handle Bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isAppDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.replay_rounded,
                          size: 18,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.of(context).revertTodoTitle,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: appText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppStrings.of(context).revertTodoDesc,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: appTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 76,
                        height: 46,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: appSubtleBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            AppStrings.of(context).commonCancel,
                            style: GoogleFonts.inter(
                              color: appTextSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              final updatedEntries = List<TimestampEntry>.from(_entries);
                              final index = updatedEntries.indexWhere((e) => e.id == entry.id);
                              if (index != -1) {
                                updatedEntries[index] = entry.copyWith(
                                  status: 'todo',
                                  clearDoneTimestamp: true,
                                  clearDoneNote: true,
                                  clearDoneImage: true,
                                  clearManualDuration: true,
                                  clearLastResumedTimestamp: true,
                                  clearStartedTimestamp: true,
                                  totalActiveSeconds: 0,
                                );
                                _onEntriesChanged(updatedEntries);
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: categoryColor,
                              foregroundColor: categoryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              AppStrings.of(context).revertConfirm,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleEntryStatus(String id) {
    final updatedEntries = List<TimestampEntry>.from(_entries);
    final index = updatedEntries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final entry = updatedEntries[index];
      if (entry.isPendingTodo) {
        _showDoneCompletionSheet(entry);
      } else if (entry.status == 'done') {
        _showRevertConfirmSheet(entry);
      } else {
        // 일반 항목(none) -> TODO로 전환
        updatedEntries[index] = entry.copyWith(
          status: 'todo',
          clearDoneTimestamp: true,
          clearDoneNote: true,
          clearDoneImage: true,
        );
        _onEntriesChanged(updatedEntries);
      }
    }
  }

  void _updateEntry(TimestampEntry updatedEntry) {
    final updatedEntries = List<TimestampEntry>.from(_entries);
    final index = updatedEntries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      updatedEntries[index] = updatedEntry;
      _onEntriesChanged(updatedEntries);
    }
  }

  void _onCenterAddPressed() {
    HapticFeedback.mediumImpact();
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homePageKey.currentState?.showAddEntrySheet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomePage(
        key: _homePageKey,
        entries: _entriesNotifier.value,
        onEntriesChanged: _onEntriesChanged,
        onDelete: _deleteEntry,
        onToggle: _toggleEntryStatus,
        getCategoryColor: _getCategoryColor,
        saveImage: _saveImage,
        uiScale: _uiScale,
        categories: _categories,
        defaultCategory: _defaultCategory,
        onAddCategory: _addCategory,
      ),
      CategoryView(
        entriesNotifier: _entriesNotifier,
        onDelete: _deleteEntry,
        onToggle: _toggleEntryStatus,
        onClearCategory: _clearCategory,
        onDeleteCategory: _deleteCategory,
        onUpdateEntry: _updateEntry,
        uiScale: _uiScale,
        categories: _categories,
        categoryColors: _categoryIndicatorColors,
        defaultCategory: _defaultCategory,
        onAddCategory: _addCategory,
        onReorderCategories: _reorderCategories,
        onSetDefaultCategory: _setDefaultCategory,
        onUpdateCategoryColor: _updateCategoryColor,
        onRenameCategory: _renameCategory,
      ),
      InsightView(
        entriesNotifier: _entriesNotifier,
        uiScale: _uiScale,
        categoryColors: _categoryIndicatorColors,
        onDelete: _deleteEntry,
        onToggle: _toggleEntryStatus,
        onUpdate: _updateEntry,
        categories: _categories,
      ),
    ];

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final currentTheme = ThemeController.instance.currentTheme;
        final gradientIntensity = ThemeController.instance.gradientIntensity;
        final isDark = currentTheme.isDark;
        final effectiveIntensity = isDark ? gradientIntensity : gradientIntensity * 0.35;
        return Scaffold(
          extendBody: true,
          backgroundColor: currentTheme.scaffoldBg,
          body: Container(
            decoration: BoxDecoration(
              color: currentTheme.scaffoldBg,
              gradient: effectiveIntensity > 0
                  ? LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        currentTheme.accent.withOpacity(effectiveIntensity),
                        currentTheme.scaffoldBg.withOpacity(0.85),
                        currentTheme.scaffoldBg,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    )
                  : null,
            ),
            child: screens[_selectedIndex],
          ),
          bottomNavigationBar: _buildIosBottomNav(context, currentTheme),
        );
      },
    );
  }

  Widget _buildIosBottomNav(BuildContext context, AppTheme currentTheme) {
    final strings = AppStrings.of(context);
    final isDark = currentTheme.isDark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 라이트 모드에서 포인트 색상이 너무 밝거나 흰색일 경우 고대비 색상으로 안전하게 렌더링
    final effectiveAccent = (!isDark && currentTheme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : currentTheme.accent;

    const double barHeight = 58.0;
    const double centerBtnDiameter = 58.0;
    const double protrusion = 22.0;
    final double totalHeight = barHeight + bottomPadding + protrusion;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. 하단 바 본체 (맑은 투명 글래스모피즘 + 윗부분 원형 경계선 및 은은한 그림자)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomPadding,
            child: ClipPath(
              clipper: NotchedBarClipper(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: CustomPaint(
                  painter: NotchedTopBorderPainter(
                    color: isDark
                        ? Colors.white.withOpacity(0.32)
                        : Colors.black.withOpacity(0.22),
                    strokeWidth: 1.0,
                    isDark: isDark,
                  ),
                  child: Container(
                    color: Colors.transparent,
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 좌측 1: 타임라인
                        _buildNavItem(
                          icon: Icons.schedule_rounded,
                          label: strings.navTimeline,
                          isSelected: _selectedIndex == 0,
                          accentColor: effectiveAccent,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedIndex = 0);
                          },
                        ),
                        // 좌측 2: 카테고리
                        _buildNavItem(
                          icon: Icons.grid_view_rounded,
                          label: strings.navCategory,
                          isSelected: _selectedIndex == 1,
                          accentColor: effectiveAccent,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedIndex = 1);
                          },
                        ),
                        // 중앙 여백 (중앙 원형 버튼 자리)
                        const SizedBox(width: 82),
                        // 우측 1: 인사이트
                        _buildNavItem(
                          icon: Icons.insights_rounded,
                          label: strings.tabInsights,
                          isSelected: _selectedIndex == 2,
                          accentColor: effectiveAccent,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedIndex = 2);
                          },
                        ),
                        // 우측 2: 설정
                        _buildNavItem(
                          icon: Icons.tune_rounded,
                          label: strings.tabSettings,
                          isSelected: false,
                          accentColor: effectiveAccent,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showSettingsMenu(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. 중앙 원형 + 버튼 (투명 배경 + 하단 바에 쏙 안착된 위치)
          Positioned(
            bottom: barHeight + bottomPadding - (centerBtnDiameter / 2) - 6.0,
            child: GestureDetector(
              onTap: _onCenterAddPressed,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: centerBtnDiameter,
                height: centerBtnDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: effectiveAccent,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveAccent.withOpacity(0.28),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 32,
                    color: effectiveAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? accentColor
                    : (isDark
                        ? Colors.white.withOpacity(0.38)
                        : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                  color: isSelected
                      ? accentColor
                      : (isDark
                          ? Colors.white.withOpacity(0.4)
                          : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 하단 내비게이션 바의 글래스모피즘 블러 및 배경을 중앙 Notch 홈에 맞춰 완벽하게 클리핑
class NotchedBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double cx = w / 2;

    const double cy = 6.0;
    const double notchRadius = 35.5;
    const double filletRadius = 14.0;

    final double dy = filletRadius - cy;
    final double hyp = notchRadius + filletRadius;
    final double xF = math.sqrt(hyp * hyp - dy * dy);
    final double ux = xF / hyp;
    final double uy = dy / hyp;
    final double xT = ux * notchRadius;
    final double yT = cy + uy * notchRadius;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(cx - xF, 0);

    // 좌측 필렛 (볼록 곡선: 수평선에서 매끄럽게 Notch로 하강)
    path.arcToPoint(
      Offset(cx - xT, yT),
      radius: const Radius.circular(filletRadius),
      clockwise: true,
    );

    // 중앙 원호 (오목 곡선: + 버튼을 일정한 간격으로 완벽하게 감쌈)
    path.arcToPoint(
      Offset(cx + xT, yT),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    // 우측 필렛 (볼록 곡선: Notch에서 매끄럽게 수평선으로 복귀)
    path.arcToPoint(
      Offset(cx + xF, 0),
      radius: const Radius.circular(filletRadius),
      clockwise: true,
    );

    path.lineTo(w, 0);
    path.lineTo(w, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class NotchedTopBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isDark;

  NotchedTopBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double cx = w / 2;

    // + 버튼 중심 (cy): 6.0, 외곽 반지름 약 30.75
    // Notch 원호 반지름: 35.5 => 4.75px 균일 간격 형성
    // 필렛 반지름: 14.0 => 수평선과 Notch 사이를 C1 접선 연속으로 부드럽게 연결
    const double cy = 6.0;
    const double notchRadius = 35.5;
    const double filletRadius = 14.0;

    final double dy = filletRadius - cy;
    final double hyp = notchRadius + filletRadius;
    final double xF = math.sqrt(hyp * hyp - dy * dy);
    final double ux = xF / hyp;
    final double uy = dy / hyp;
    final double xT = ux * notchRadius;
    final double yT = cy + uy * notchRadius;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(cx - xF, 0);

    // 1. 좌측 볼록 어깨 곡선
    path.arcToPoint(
      Offset(cx - xT, yT),
      radius: const Radius.circular(filletRadius),
      clockwise: true,
    );

    // 2. 중앙 오목 원호
    path.arcToPoint(
      Offset(cx + xT, yT),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    // 3. 우측 볼록 어깨 곡선
    path.arcToPoint(
      Offset(cx + xF, 0),
      radius: const Radius.circular(filletRadius),
      clockwise: true,
    );

    path.lineTo(w, 0);

    // 하단 바의 반투명 배경 (맑고 투명한 글래스모피즘 배경)
    final bgPath = Path.from(path)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();

    final bgPaint = Paint()
      ..color = isDark
          ? Colors.black.withOpacity(0.38)
          : Colors.white.withOpacity(0.48)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bgPath, bgPaint);

    // 1. 은은한 단일 섀도우 (테두리 곡선을 따라 은은하게 안착)
    final shadowPaint = Paint()
      ..color = isDark
          ? Colors.black.withOpacity(0.32)
          : Colors.black.withOpacity(0.10)
      ..strokeWidth = strokeWidth + 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.save();
    canvas.translate(0, 1.0);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 2. 경계선 본체 (깨끗하고 세련된 1.0px 실선)
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant NotchedTopBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isDark != isDark;
  }
}

class TimeSegment {
  final DateTime start;
  final DateTime? end;

  const TimeSegment({
    required this.start,
    this.end,
  });

  int get durationInSeconds {
    final finish = end ?? DateTime.now();
    final diff = finish.difference(start).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toJson() => {
    'start': start.millisecondsSinceEpoch,
    'end': end?.millisecondsSinceEpoch,
  };

  factory TimeSegment.fromJson(Map<String, dynamic> json) => TimeSegment(
    start: DateTime.fromMillisecondsSinceEpoch(json['start']),
    end: json['end'] != null ? DateTime.fromMillisecondsSinceEpoch(json['end']) : null,
  );

  TimeSegment copyWith({DateTime? start, DateTime? end}) => TimeSegment(
    start: start ?? this.start,
    end: end ?? this.end,
  );
}

/// 한국어 및 영어 동적 지원 시간 포맷터 (비한국어는 영어가 디폴트)
String formatDurationKo(Duration diff) => AppStrings.formatDuration(diff);

String formatSecondsKo(int totalSeconds) => AppStrings.formatSeconds(totalSeconds);

class TimestampEntry {
  final String id;
  final DateTime timestamp;
  final String note;
  final String category;
  final String? imagePath;
  final String status; // 'none', 'todo', 'in_progress', 'paused', 'done'
  final DateTime? doneTimestamp;
  final String? doneNote;
  final String? doneImagePath;
  final DateTime? targetDate;
  final int? manualDurationMinutes;
  final int? manualDurationSeconds;

  // Work tracking fields (이정표 기반 구간 기록)
  final DateTime? startedTimestamp;
  final DateTime? lastResumedTimestamp;
  final int totalActiveSeconds;
  final List<TimeSegment> workSessions;

  String get text => note;

  bool get isTodo => status == 'todo';
  bool get isInProgress => status == 'in_progress';
  bool get isPaused => status == 'paused';
  bool get isDone => status == 'done';
  bool get isPendingTodo => status == 'todo' || status == 'in_progress' || status == 'paused';
  bool get isAnyTodo => isPendingTodo || isDone;
  bool get isManualDuration =>
      (manualDurationSeconds != null && manualDurationSeconds! > 0) ||
      (manualDurationMinutes != null && manualDurationMinutes! > 0);

  int get currentElapsedSeconds {
    if (workSessions.isNotEmpty) {
      int total = 0;
      for (final s in workSessions) {
        if (s.end != null) {
          total += s.end!.difference(s.start).inSeconds;
        } else if (isInProgress) {
          total += DateTime.now().difference(s.start).inSeconds;
        }
      }
      return total;
    }
    if (isInProgress && lastResumedTimestamp != null) {
      final additional = DateTime.now().difference(lastResumedTimestamp!).inSeconds;
      return totalActiveSeconds + (additional > 0 ? additional : 0);
    }
    return totalActiveSeconds;
  }

  int? get computedDurationSeconds {
    if (manualDurationSeconds != null && manualDurationSeconds! > 0) {
      return manualDurationSeconds;
    }
    if (manualDurationMinutes != null && manualDurationMinutes! > 0) {
      return manualDurationMinutes! * 60;
    }
    if (status == 'done') {
      if (workSessions.isNotEmpty) {
        int total = 0;
        for (final s in workSessions) {
          if (s.end != null) {
            total += s.end!.difference(s.start).inSeconds;
          }
        }
        if (total > 0) return total;
      }
      if (totalActiveSeconds > 0) {
        return totalActiveSeconds;
      }
      if (startedTimestamp != null && doneTimestamp != null) {
        final diff = doneTimestamp!.difference(startedTimestamp!).inSeconds;
        return diff >= 0 ? diff : 0;
      }
      if (doneTimestamp != null) {
        final diff = doneTimestamp!.difference(timestamp).inSeconds;
        return (diff > 0 && diff <= 720 * 60) ? diff : 0;
      }
    }
    return null;
  }

  int get effectiveDurationSeconds {
    final computed = computedDurationSeconds;
    if (computed != null && computed > 0) return computed;
    if (isPendingTodo) return currentElapsedSeconds;
    return 0;
  }

  int get effectiveDurationMinutes => (effectiveDurationSeconds / 60).round();

  int? get computedDurationMinutes {
    final sec = computedDurationSeconds;
    if (sec != null) return (sec / 60).round();
    return null;
  }

  TimestampEntry({
    required this.id,
    required this.timestamp,
    required this.note,
    required this.category,
    this.imagePath,
    this.status = 'none',
    this.doneTimestamp,
    this.doneNote,
    this.doneImagePath,
    this.targetDate,
    this.manualDurationMinutes,
    this.manualDurationSeconds,
    this.startedTimestamp,
    this.lastResumedTimestamp,
    this.totalActiveSeconds = 0,
    this.workSessions = const [],
  });

  TimestampEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? note,
    String? category,
    String? imagePath,
    bool clearImage = false,
    String? status,
    DateTime? doneTimestamp,
    bool clearDoneTimestamp = false,
    String? doneNote,
    bool clearDoneNote = false,
    String? doneImagePath,
    bool clearDoneImage = false,
    DateTime? targetDate,
    bool clearTargetDate = false,
    int? manualDurationMinutes,
    int? manualDurationSeconds,
    bool clearManualDuration = false,
    DateTime? startedTimestamp,
    bool clearStartedTimestamp = false,
    DateTime? lastResumedTimestamp,
    bool clearLastResumedTimestamp = false,
    int? totalActiveSeconds,
    List<TimeSegment>? workSessions,
  }) {
    return TimestampEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      category: category ?? this.category,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      status: status ?? this.status,
      doneTimestamp: clearDoneTimestamp ? null : (doneTimestamp ?? this.doneTimestamp),
      doneNote: clearDoneNote ? null : (doneNote ?? this.doneNote),
      doneImagePath: clearDoneImage ? null : (doneImagePath ?? this.doneImagePath),
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      manualDurationMinutes: clearManualDuration
          ? null
          : (manualDurationMinutes ?? this.manualDurationMinutes),
      manualDurationSeconds: clearManualDuration
          ? null
          : (manualDurationSeconds ?? this.manualDurationSeconds),
      startedTimestamp: clearStartedTimestamp
          ? null
          : (startedTimestamp ?? this.startedTimestamp),
      lastResumedTimestamp: clearLastResumedTimestamp
          ? null
          : (lastResumedTimestamp ?? this.lastResumedTimestamp),
      totalActiveSeconds: totalActiveSeconds ?? this.totalActiveSeconds,
      workSessions: workSessions ?? this.workSessions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'note': note,
    'category': category,
    'imagePath': imagePath,
    'status': status,
    'doneTimestamp': doneTimestamp?.millisecondsSinceEpoch,
    'doneNote': doneNote,
    'doneImagePath': doneImagePath,
    'targetDate': targetDate?.millisecondsSinceEpoch,
    'manualDurationMinutes': manualDurationMinutes ?? (manualDurationSeconds != null ? (manualDurationSeconds! / 60).round() : null),
    'manualDurationSeconds': manualDurationSeconds,
    'startedTimestamp': startedTimestamp?.millisecondsSinceEpoch,
    'lastResumedTimestamp': lastResumedTimestamp?.millisecondsSinceEpoch,
    'totalActiveSeconds': totalActiveSeconds,
    'workSessions': workSessions.map((s) => s.toJson()).toList(),
  };

  factory TimestampEntry.fromJson(Map<String, dynamic> json) => TimestampEntry(
    id: json['id'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    note: json['note'] ?? "",
    category: json['category'] ?? "General",
    imagePath: json['imagePath'],
    status: json['status'] ?? "none",
    doneTimestamp: json['doneTimestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['doneTimestamp'])
        : null,
    doneNote: json['doneNote'],
    doneImagePath: json['doneImagePath'],
    targetDate: json['targetDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['targetDate'])
        : null,
    manualDurationMinutes: json['manualDurationMinutes'],
    manualDurationSeconds: json['manualDurationSeconds'] ??
        (json['manualDurationMinutes'] != null
            ? (json['manualDurationMinutes'] as int) * 60
            : null),
    startedTimestamp: json['startedTimestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['startedTimestamp'])
        : null,
    lastResumedTimestamp: json['lastResumedTimestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastResumedTimestamp'])
        : null,
    totalActiveSeconds: json['totalActiveSeconds'] ?? 0,
    workSessions: json['workSessions'] != null
        ? (json['workSessions'] as List)
            .map((s) => TimeSegment.fromJson(s as Map<String, dynamic>))
            .toList()
        : const [],
  );
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  _MarqueeTextState createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimation();
    });
  }

  void _startAnimation() async {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) break;
      
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: (maxScroll * 40).toInt()),
        curve: Curves.linear,
      );
      
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) break;

      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  final Color color;
  const _BlinkingDot({required this.color});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5 * _animation.value),
                blurRadius: 10 * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAddHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onTap;
  final Color categoryColor;
  final double uiScale;
  final AppTheme theme;

  _QuickAddHeaderDelegate({
    required this.onTap,
    required this.categoryColor,
    required this.uiScale,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = theme.isDark;

    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E2330), const Color(0xFF161922)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.accent.withOpacity(isDark ? 0.45 : 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                if (isDark)
                  BoxShadow(
                    color: theme.accent.withOpacity(0.15),
                    blurRadius: 14,
                    spreadRadius: -1,
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _BlinkingDot(color: theme.accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.of(context).quickAddHint,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF0F172A),
                          fontSize: 13.5 * uiScale,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.of(context).isKo
                            ? '당신을 채우는 작은 조각들을 더해보세요'
                            : 'Capture your moments and milestones',
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white.withOpacity(0.45) : const Color(0xFF64748B),
                          fontSize: 10.5 * uiScale,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.accent.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: theme.accent.computeLuminance() > 0.6 ? Colors.black : Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 88 * uiScale;

  @override
  double get minExtent => 88 * uiScale;

  @override
  bool shouldRebuild(covariant _QuickAddHeaderDelegate oldDelegate) {
    return oldDelegate.categoryColor != categoryColor ||
        oldDelegate.uiScale != uiScale ||
        oldDelegate.theme.id != theme.id ||
        oldDelegate.theme.isDark != theme.isDark;
  }
}

Future<Color?> showCustomColorPickerDialog(
  BuildContext context, {
  Color? initialColor,
}) {
  Color currentColor = initialColor ?? const Color(0xFF6366F1);
  HSVColor hsvColor = HSVColor.fromColor(currentColor);

  final List<Color> quickPalette = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF14B8A6), // Teal
    const Color(0xFF10B981), // Emerald
    const Color(0xFF22C55E), // Green
    const Color(0xFF84CC16), // Lime
    const Color(0xFFEAB308), // Yellow
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFF97316), // Orange
    const Color(0xFFEF4444), // Red
    const Color(0xFFF43F5E), // Rose
    const Color(0xFFEC4899), // Pink
    const Color(0xFFD946EF), // Fuchsia
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFA855F7), // Violet
    const Color(0xFF64748B), // Slate
  ];

  return showModalBottomSheet<Color>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setPickerState) {
        final s = AppStrings.of(context);
        final Color displayColor = hsvColor.toColor();
        final String hexString =
            '#${displayColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: appCardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: appBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들 (아래로 쓸어내리면 팝업 닫힘)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! > 6) {
                    Navigator.pop(dialogCtx);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isAppDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Compact Header (Identical to + button Add Sheet)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: displayColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.palette_rounded,
                        size: 16,
                        color: displayColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.customColorTitle,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: appText,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: appSubtleBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: appTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Flexible(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is OverscrollNotification &&
                        notification.overscroll < -15) {
                      Navigator.pop(dialogCtx);
                      return true;
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 14 + MediaQuery.of(context).padding.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Color preview bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: appSubtleBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: appBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: displayColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: displayColor.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hexString,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: appText,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'RGB(${displayColor.red}, ${displayColor.green}, ${displayColor.blue})',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: appTextTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.colorPalette,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: appTextTertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: quickPalette.map((pColor) {
                            final bool isSel = displayColor.value == pColor.value;
                            return GestureDetector(
                              onTap: () {
                                setPickerState(() {
                                  hsvColor = HSVColor.fromColor(pColor);
                                });
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: pColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? (isAppDark ? Colors.white : Colors.black) : (isAppDark ? Colors.white12 : Colors.black12),
                                    width: isSel ? 2.5 : 1,
                                  ),
                                ),
                                child: isSel
                                    ? Icon(
                                        Icons.check,
                                        size: 16,
                                        color: pColor.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        // Hue Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.colorHue,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: appTextSecondary,
                              ),
                            ),
                            Text(
                              '${hsvColor.hue.round()}°',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: appTextTertiary,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 12,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                            thumbColor: isAppDark ? Colors.white : const Color(0xFF0F172A),
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 12,
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF0000),
                                      Color(0xFFFFFF00),
                                      Color(0xFF00FF00),
                                      Color(0xFF00FFFF),
                                      Color(0xFF0000FF),
                                      Color(0xFFFF00FF),
                                      Color(0xFFFF0000),
                                    ],
                                  ),
                                ),
                              ),
                              Slider(
                                value: hsvColor.hue,
                                min: 0,
                                max: 360,
                                onChanged: (val) {
                                  setPickerState(() {
                                    hsvColor = hsvColor.withHue(val);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        // Saturation Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.colorSaturation,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: appTextSecondary,
                              ),
                            ),
                            Text(
                              '${(hsvColor.saturation * 100).round()}%',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: appTextTertiary,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 12,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                            thumbColor: isAppDark ? Colors.white : const Color(0xFF0F172A),
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 12,
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: LinearGradient(
                                    colors: [
                                      HSVColor.fromAHSV(1.0, hsvColor.hue, 0.0, hsvColor.value).toColor(),
                                      HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, hsvColor.value).toColor(),
                                    ],
                                  ),
                                ),
                              ),
                              Slider(
                                value: hsvColor.saturation,
                                min: 0,
                                max: 1.0,
                                onChanged: (val) {
                                  setPickerState(() {
                                    hsvColor = hsvColor.withSaturation(val);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        // Brightness Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.colorBrightness,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: appTextSecondary,
                              ),
                            ),
                            Text(
                              '${(hsvColor.value * 100).round()}%',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: appTextTertiary,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 12,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                            thumbColor: isAppDark ? Colors.white : const Color(0xFF0F172A),
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 12,
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black,
                                      HSVColor.fromAHSV(1.0, hsvColor.hue, hsvColor.saturation, 1.0).toColor(),
                                    ],
                                  ),
                                ),
                              ),
                              Slider(
                                value: hsvColor.value,
                                min: 0.1,
                                max: 1.0,
                                onChanged: (val) {
                                  setPickerState(() {
                                    hsvColor = hsvColor.withValue(val);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Action Buttons Row (Compact Cancel + Wide Main Button)
                        Row(
                          children: [
                            SizedBox(
                              width: 76,
                              height: 46,
                              child: TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                style: TextButton.styleFrom(
                                  backgroundColor: appSubtleBg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  s.commonCancel,
                                  style: GoogleFonts.inter(
                                    color: appTextSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogCtx, displayColor);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: displayColor,
                                    foregroundColor: displayColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    s.applyColor,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

final DateTime kClearedDateSentinel = DateTime(1970, 1, 1);

Future<DateTime?> showDeadlineDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  Color? accentColor,
  bool canClear = false,
  String? title,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime selectedDate = initialDate != null
      ? DateTime(initialDate.year, initialDate.month, initialDate.day)
      : today;
  DateTime currentMonth = DateTime(selectedDate.year, selectedDate.month, 1);

  final minDate = firstDate != null
      ? DateTime(firstDate.year, firstDate.month, firstDate.day)
      : null;
  final maxDate = lastDate != null
      ? DateTime(lastDate.year, lastDate.month, lastDate.day)
      : null;

  DateTime getThisWeekend(DateTime base) {
    if (base.weekday == 6 || base.weekday == 7) return base;
    return base.add(Duration(days: 6 - base.weekday));
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  return showModalBottomSheet<DateTime>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (context, setPickerState) {
        final s = AppStrings.of(context);
        final isKo = s.isKo;
        final weekdays = isKo
            ? const ['일', '월', '화', '수', '목', '금', '토']
            : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
        final resolvedTitle = title ?? s.deadlineSettingTitle;
        final theme = ThemeController.instance.currentTheme;
        final isDark = theme.isDark;
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom;
        final effectiveAccent = accentColor ?? theme.accent;
        final bool isAccentBright = effectiveAccent.computeLuminance() > 0.6;

        final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
        final daysInMonth =
            DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
        final leadingSpaces = firstDayOfMonth.weekday % 7;
        final totalSlots = leadingSpaces + daysInMonth;
        final rowCount = (totalSlots / 7).ceil();

        final diffDays = DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
            .difference(today)
            .inDays;
        String dDayText;
        if (diffDays == 0) {
          dDayText = s.deadlineDueToday;
        } else if (diffDays == 1) {
          dDayText = s.deadlineDueTomorrow;
        } else if (diffDays > 1) {
          dDayText = s.deadlineDueIn(diffDays);
        } else {
          dDayText = s.deadlineOverdue(diffDays.abs());
        }

        Widget buildQuickChip(String label, DateTime targetDate) {
          final isSelected = isSameDay(selectedDate, targetDate);
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setPickerState(() {
                  selectedDate = targetDate;
                  currentMonth = DateTime(targetDate.year, targetDate.month, 1);
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? effectiveAccent.withOpacity(isDark ? 0.25 : 0.15)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? effectiveAccent : appBorder,
                    width: isSelected ? 1.2 : 0.8,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? effectiveAccent : appTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: appCardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: appBorder),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Top Header Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolvedTitle,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: appText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                isKo
                                    ? '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일 (${weekdays[selectedDate.weekday % 7]})'
                                    : DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: appTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: effectiveAccent.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: effectiveAccent.withOpacity(0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  dDayText,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: effectiveAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: appTextSecondary,
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Preset Chips (오늘, 내일, 주말, 다음주 월, +2주, +1달)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      buildQuickChip(s.quickToday, today),
                      buildQuickChip(s.quickTomorrow, today.add(const Duration(days: 1))),
                      buildQuickChip(s.quickThisWeekend, getThisWeekend(today)),
                      buildQuickChip(
                        s.quickNextWeek,
                        today.add(Duration(days: ((8 - today.weekday) % 7 == 0 ? 7 : (8 - today.weekday) % 7))),
                      ),
                      buildQuickChip(s.quickPlus2Weeks, today.add(const Duration(days: 14))),
                      buildQuickChip(
                        s.quickPlus1Month,
                        DateTime(today.year, today.month + 1, today.day),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Month Switcher Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setPickerState(() {
                            currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
                          });
                        },
                        icon: const Icon(Icons.chevron_left_rounded, size: 22),
                        color: appTextSecondary,
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      Text(
                        isKo
                            ? '${currentMonth.year}년 ${currentMonth.month}월'
                            : DateFormat('MMMM yyyy').format(currentMonth),
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: appText,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setPickerState(() {
                            currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
                          });
                        },
                        icon: const Icon(Icons.chevron_right_rounded, size: 22),
                        color: appTextSecondary,
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ),
                ),

                // Weekday Labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: List.generate(7, (i) {
                      final isSun = i == 0;
                      final isSat = i == 6;
                      Color dayColor;
                      if (isSun) {
                        dayColor = const Color(0xFFEF4444);
                      } else if (isSat) {
                        dayColor = const Color(0xFF3B82F6);
                      } else {
                        dayColor = appTextTertiary;
                      }
                      return Expanded(
                        child: Center(
                          child: Text(
                            weekdays[i],
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: dayColor,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Calendar Days Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(rowCount, (row) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: List.generate(7, (col) {
                            final slotIndex = row * 7 + col;
                            final dayNumber = slotIndex - leadingSpaces + 1;
                            if (dayNumber < 1 || dayNumber > daysInMonth) {
                              return const Expanded(child: SizedBox(height: 38));
                            }
                            final cellDate = DateTime(currentMonth.year, currentMonth.month, dayNumber);
                            final isSelected = isSameDay(cellDate, selectedDate);
                            final isTodayCell = isSameDay(cellDate, today);
                            final isPast = cellDate.isBefore(today);

                            final bool isDisabled = (minDate != null && cellDate.isBefore(minDate)) ||
                                (maxDate != null && cellDate.isAfter(maxDate));

                            final isSun = col == 0;
                            final isSat = col == 6;

                            Color textColor;
                            if (isSelected) {
                              textColor = isAccentBright ? Colors.black : Colors.white;
                            } else if (isDisabled) {
                              textColor = appTextTertiary.withOpacity(0.3);
                            } else if (isPast) {
                              textColor = appTextTertiary.withOpacity(0.5);
                            } else if (isSun) {
                              textColor = const Color(0xFFEF4444);
                            } else if (isSat) {
                              textColor = const Color(0xFF3B82F6);
                            } else {
                              textColor = appText;
                            }

                            return Expanded(
                              child: InkWell(
                                onTap: isDisabled
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        setPickerState(() => selectedDate = cellDate);
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? effectiveAccent : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isTodayCell && !isSelected
                                        ? Border.all(color: effectiveAccent.withOpacity(0.5), width: 1.2)
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$dayNumber',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: isSelected || isTodayCell
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                      if (isTodayCell && !isSelected)
                                        Container(
                                          width: 3.5,
                                          height: 3.5,
                                          margin: const EdgeInsets.only(top: 1),
                                          decoration: BoxDecoration(
                                            color: effectiveAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom Action Buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomPadding),
                  child: Row(
                    children: [
                      if (canClear) ...[
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(sheetCtx, kClearedDateSentinel);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: appTextSecondary,
                                side: BorderSide(color: appBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                s.clearDeadline,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: appTextSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(sheetCtx, selectedDate);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: effectiveAccent,
                              foregroundColor: isAccentBright ? Colors.black : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              s.doneSetting,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isAccentBright ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}


void showAddCategoryModal(
  BuildContext context, {
  required Function(String, Color) onAddCategory,
  Function(String)? onCategoryCreated,
}) {
  final TextEditingController controller = TextEditingController();
  final themeAccent = ThemeController.instance.currentTheme.accent;
  Color selectedColor = themeAccent;
  final List<Color> basePresets = [
    const Color(0xFF6366F1),
    const Color(0xFF10B981),
    const Color(0xFFEF4444),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF06B6D4),
    const Color(0xFF3B82F6),
    const Color(0xFF14B8A6),
    const Color(0xFFF97316),
  ];
  final List<Color> presetColors = [
    if (!basePresets.any((c) => c.value == themeAccent.value)) themeAccent,
    ...basePresets,
  ];

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        final double effectiveBottom =
            bottomInset > 0 ? bottomInset + 12 : (bottomPadding > 0 ? bottomPadding + 8 : 16);

        final bool canSubmit = controller.text.trim().isNotEmpty;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: appCardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: appBorder),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 12, 20, effectiveBottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // iOS Style Drag Handle
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 7) {
                        Navigator.pop(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isAppDark
                                ? Colors.white.withOpacity(0.18)
                                : Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: selectedColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          size: 18,
                          color: selectedColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.of(context).categoryAddNew,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: appText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppStrings.of(context).isKo ? '주제별로 분류하여 기록을 정리하세요' : 'Organize records by category',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: appTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isAppDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: appTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Name Input
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.inter(
                      color: appText,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (_) => setSheetState(() {}),
                    onSubmitted: (val) {
                      final name = val.trim();
                      if (name.isNotEmpty) {
                        HapticFeedback.mediumImpact();
                        onAddCategory(name, selectedColor);
                        Navigator.pop(context);
                        if (onCategoryCreated != null) {
                          onCategoryCreated(name);
                        }
                      }
                    },
                    decoration: InputDecoration(
                      hintText: AppStrings.of(context).categoryNameHint,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: appTextTertiary,
                      ),
                      filled: true,
                      fillColor: isAppDark
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      prefixIcon: Icon(
                        Icons.tag_rounded,
                        size: 18,
                        color: selectedColor,
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                controller.clear();
                                setSheetState(() {});
                              },
                              child: Icon(
                                Icons.cancel_rounded,
                                size: 18,
                                color: appTextTertiary,
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: appBorder, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: appBorder, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: selectedColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Color Picker Section Header
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 14, color: appTextSecondary),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.of(context).categoryColorSelect,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: appTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: selectedColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedColor.withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: selectedColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selectedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Color Swatches Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ...presetColors.map((color) {
                          final bool isSelected = selectedColor.value == color.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setSheetState(() => selectedColor = color);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? (isAppDark ? Colors.white : Colors.black87)
                                        : (isAppDark
                                            ? Colors.white.withOpacity(0.12)
                                            : Colors.black.withOpacity(0.08)),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: color.withOpacity(isAppDark ? 0.5 : 0.28),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 20,
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black87
                                            : Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            final custom = await showCustomColorPickerDialog(
                              context,
                              initialColor: selectedColor,
                            );
                            if (custom != null) {
                              setSheetState(() {
                                if (!presetColors.any((c) => c.value == custom.value)) {
                                  presetColors.add(custom);
                                }
                                selectedColor = custom;
                              });
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isAppDark
                                  ? Colors.white.withOpacity(0.06)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: appBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              Icons.colorize_rounded,
                              color: appTextSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons Row (Compact Cancel + Wide Main Button)
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: appSubtleBg,
                            foregroundColor: appTextSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: appBorder, width: 0.8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            AppStrings.of(context).commonCancel,
                            style: GoogleFonts.inter(
                              color: appTextSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: canSubmit
                                ? () {
                                    HapticFeedback.mediumImpact();
                                    final name = controller.text.trim();
                                    if (name.isNotEmpty) {
                                      onAddCategory(name, selectedColor);
                                      Navigator.pop(context);
                                      if (onCategoryCreated != null) {
                                        onCategoryCreated(name);
                                      }
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedColor,
                              disabledBackgroundColor: isAppDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.06),
                              foregroundColor: selectedColor.computeLuminance() > 0.5
                                  ? Colors.black87
                                  : Colors.white,
                              disabledForegroundColor: appTextTertiary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              AppStrings.of(context).isKo ? '카테고리 생성' : 'Create Category',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: canSubmit
                                    ? (selectedColor.computeLuminance() > 0.5
                                        ? Colors.black87
                                        : Colors.white)
                                    : appTextTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'ca-app-pub-6846113246046890/2198693356';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'ca-app-pub-6846113246046890/2863414473';
    }
    return '';
  }
}

class TopBannerAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry? margin;

  const TopBannerAdWidget({super.key, this.margin});

  @override
  State<TopBannerAdWidget> createState() => _TopBannerAdWidgetState();
}

typedef BannerAdWidget = TopBannerAdWidget;

class _TopBannerAdWidgetState extends State<TopBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (kIsProVersion) return;
    final adUnitId = AdHelper.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('TopBannerAd failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsProVersion) return const SizedBox.shrink();
    if (_isLoaded && _bannerAd != null) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        margin: widget.margin ?? const EdgeInsets.only(bottom: 12),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
}

class HomePage extends StatefulWidget {
  final List<TimestampEntry> entries;
  final Function(List<TimestampEntry>) onEntriesChanged;
  final Function(String) onDelete;
  final Function(String) onToggle;
  final Color Function(String) getCategoryColor;
  final Future<String?> Function(File?) saveImage;
  final double uiScale;
  final List<String> categories;
  final String defaultCategory;
  final Function(String, Color) onAddCategory;

  const HomePage({
    super.key,
    required this.entries,
    required this.onEntriesChanged,
    required this.onDelete,
    required this.onToggle,
    required this.getCategoryColor,
    required this.saveImage,
    required this.uiScale,
    required this.categories,
    required this.defaultCategory,
    required this.onAddCategory,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _currentTime;
  late String _currentDate;
  late Timer _timer;
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isTodo = false;
  DateTime? _targetDate;
  bool _showOnlyTodo = false;
  bool _showSwipeGuide = false;
  int _displayedItemCount = 30;

  String _selectedCategory = 'General';

  Color _getCategoryColor(String category) {
    return widget.getCategoryColor(category);
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.defaultCategory;
    _updateTime();
    _loadSwipeGuideState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateTime(),
    );
  }

  Future<void> _loadSwipeGuideState() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeen = prefs.getBool('has_seen_swipe_guide') ?? false;
    if (!hasSeen && mounted) {
      setState(() {
        _showSwipeGuide = true;
      });
    }
  }

  Future<void> _dismissSwipeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_swipe_guide', true);
    if (mounted) {
      setState(() {
        _showSwipeGuide = false;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm:ss').format(now);
        _currentDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
      });
    }
  }

  void _showAddCategoryDialog({Function(String)? onCategoryCreated}) {
    showAddCategoryModal(
      context,
      onAddCategory: widget.onAddCategory,
      onCategoryCreated: (name) {
        setState(() => _selectedCategory = name);
        if (onCategoryCreated != null) {
          onCategoryCreated(name);
        }
      },
    );
  }

  Future<String?> _saveImage(File? image) async {
    if (image == null) return null;
    final directory = await getApplicationDocumentsDirectory();
    final fileName = path.basename(image.path);
    final savedImage = await image.copy('${directory.path}/$fileName');
    return savedImage.path;
  }

  Future<void> _pickImage(ImageSource source, {StateSetter? setSheetState}) async {
    if (source == ImageSource.camera) {
      final String? path = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const CameraPage()),
      );
      if (path != null) {
        setState(() {
          _selectedImage = File(path);
        });
        if (setSheetState != null) setSheetState(() {});
      }
    } else {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        if (setSheetState != null) setSheetState(() {});
      }
    }
  }

  void showAddEntrySheet() => _showAddEntrySheet();

  void _showAddEntrySheet() {
    if (widget.categories.contains(widget.defaultCategory)) {
      _selectedCategory = widget.defaultCategory;
    } else if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
    final List<String> sheetCategories = List<String>.from(widget.categories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final s = AppStrings.of(context);
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
          final double effectiveBottom =
              bottomInset > 0 ? bottomInset + 10 : bottomPadding + 14;
          final accentColor = ThemeController.instance.currentTheme.accent;

          for (final c in widget.categories) {
            if (!sheetCategories.contains(c)) {
              sheetCategories.add(c);
            }
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: appCardBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 12, 20, effectiveBottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // iOS Style Handle Bar
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta! > 7) {
                          Navigator.pop(context);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isAppDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Compact Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                        ),
                          const SizedBox(width: 8),
                          Text(
                            s.newRecordTitle,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: appText,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: appSubtleBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: appTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Category Chips (Compact iOS style)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            ...sheetCategories.map((cat) {
                              final bool isSelected = _selectedCategory == cat;
                              final bool isDefault = cat == widget.defaultCategory;
                              final catColor = widget.getCategoryColor(cat);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedCategory = cat);
                                    setSheetState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? catColor.withOpacity(isAppDark ? 0.22 : 0.15)
                                          : (isAppDark ? const Color(0xFF20242F) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? catColor
                                            : appBorder,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isDefault) ...[
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 13,
                                            color: Color(0xFFF59E0B),
                                          ),
                                          const SizedBox(width: 4),
                                        ] else ...[
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: catColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          cat,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5 * widget.uiScale,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? (isAppDark ? Colors.white : catColor) : appTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            GestureDetector(
                              onTap: () {
                                _showAddCategoryDialog(
                                  onCategoryCreated: (newCat) {
                                    if (!sheetCategories.contains(newCat)) {
                                      sheetCategories.add(newCat);
                                    }
                                    _selectedCategory = newCat;
                                    setSheetState(() {});
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: appSubtleBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: appTextTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // TODO Switch (Compact)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: appSubtleBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: appBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 16,
                              color: _isTodo ? accentColor : appTextTertiary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              s.registerAsTodo,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isTodo ? appText : appTextTertiary,
                              ),
                            ),
                            const Spacer(),
                            Transform.scale(
                              scale: 0.75,
                              child: Switch(
                                value: _isTodo,
                                onChanged: (val) {
                                  setState(() => _isTodo = val);
                                  setSheetState(() {});
                                },
                                activeColor: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_isTodo) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDeadlineDatePicker(
                              context: context,
                              initialDate: _targetDate,
                              accentColor: accentColor,
                              canClear: true,
                            );
                            if (picked != null) {
                              setState(() {
                                if (picked.year == 1970) {
                                  _targetDate = null;
                                } else {
                                  _targetDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
                                }
                              });
                              setSheetState(() {});
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: appSubtleBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: appBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 14, color: appTextTertiary),
                                const SizedBox(width: 8),
                                Text(
                                  s.dueDate,
                                  style: GoogleFonts.inter(fontSize: 12.5, color: appTextSecondary),
                                ),
                                const Spacer(),
                                Text(
                                  _targetDate == null ? s.selectDate : DateFormat('yyyy.MM.dd').format(_targetDate!),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _targetDate != null ? accentColor : appTextTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Image Preview
                      if (_selectedImage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedImage = null);
                                    setSheetState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Note Input (Left aligned, vertically centered with icons)
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        minLines: 1,
                        autofocus: true,
                        textAlign: TextAlign.start,
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (_) => setSheetState(() {}),
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: appText,
                        ),
                        decoration: InputDecoration(
                          hintText: s.newRecordHint,
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: appTextTertiary,
                          ),
                          filled: true,
                          fillColor: isAppDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: appBorder, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: appBorder, width: 1),
                          ),
                          suffixIconConstraints: const BoxConstraints(minHeight: 40),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                                  color: appTextTertiary,
                                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _pickImage(ImageSource.camera, setSheetState: setSheetState),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                                  color: appTextTertiary,
                                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _pickImage(ImageSource.gallery, setSheetState: setSheetState),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons Row (Compact Cancel + Wide Main Button)
                      Builder(
                        builder: (context) {
                          final bool canSubmit = _noteController.text.trim().isNotEmpty || _selectedImage != null;
                          return Row(
                            children: [
                              SizedBox(
                                width: 76,
                                height: 46,
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    backgroundColor: appSubtleBg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    s.commonCancel,
                                    style: GoogleFonts.inter(
                                      color: appTextSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: canSubmit
                                        ? () {
                                            _addTimestamp();
                                            Navigator.pop(context);
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canSubmit
                                          ? accentColor
                                          : (isAppDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                                      foregroundColor: canSubmit
                                          ? (accentColor.computeLuminance() > 0.6 ? Colors.black : Colors.white)
                                          : (isAppDark ? Colors.white30 : Colors.black26),
                                      disabledBackgroundColor: isAppDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                                      disabledForegroundColor: isAppDark ? Colors.white30 : Colors.black26,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: Text(
                                      s.saveRecord,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

  Future<void> _addTimestamp() async {
    final noteText = _noteController.text.trim();
    if (noteText.isEmpty && _selectedImage == null) {
      return;
    }
    final imagePath = await _saveImage(_selectedImage);
    final newEntry = TimestampEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      note: noteText,
      category: _selectedCategory,
      imagePath: imagePath,
      status: _isTodo ? 'todo' : 'none',
      targetDate: _isTodo ? _targetDate : null,
    );

    final updatedEntries = List<TimestampEntry>.from(widget.entries);
    updatedEntries.insert(0, newEntry);
    widget.onEntriesChanged(updatedEntries);

    setState(() {
      _noteController.clear();
      _selectedImage = null;
      _isTodo = false;
      _targetDate = null;
    });
  }

  void _deleteEntry(String id) {
    if (_showSwipeGuide) {
      _dismissSwipeGuide();
    }
    widget.onDelete(id);
  }

  void _toggleEntryStatus(String id) {
    widget.onToggle(id);
  }

  void _updateEntry(TimestampEntry updatedEntry) {
    final updatedEntries = List<TimestampEntry>.from(widget.entries);
    final idx = updatedEntries.indexWhere((e) => e.id == updatedEntry.id);
    if (idx != -1) {
      updatedEntries[idx] = updatedEntry;
      widget.onEntriesChanged(updatedEntries);
    }
  }

  Widget _buildUrgentCountdown() {
    final now = DateTime.now();

    TimestampEntry? selectedTodo;

    // 1. Separate TODOs into categories
    List<TimestampEntry> inProgressTodos = [];
    List<TimestampEntry> todayTodos = [];
    List<TimestampEntry> futureTodos = [];
    List<TimestampEntry> overdueTodos = [];
    List<TimestampEntry> noDeadlineTodos = [];

    for (var entry in widget.entries) {
      if (entry.isPendingTodo) {
        if (entry.isInProgress) {
          inProgressTodos.add(entry);
        } else if (entry.targetDate == null) {
          noDeadlineTodos.add(entry);
        } else {
          if (entry.targetDate!.year == now.year &&
              entry.targetDate!.month == now.month &&
              entry.targetDate!.day == now.day) {
            todayTodos.add(entry);
          } else if (entry.targetDate!.isAfter(now)) {
            futureTodos.add(entry);
          } else {
            overdueTodos.add(entry);
          }
        }
      }
    }

    // 2. Sorting Logic
    inProgressTodos.sort((a, b) => b.currentElapsedSeconds.compareTo(a.currentElapsedSeconds));
    todayTodos.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Future: Closest target date first, then earliest creation timestamp
    futureTodos.sort((a, b) {
      int dateCompare = a.targetDate!.compareTo(b.targetDate!);
      if (dateCompare != 0) return dateCompare;
      return a.timestamp.compareTo(b.timestamp);
    });

    overdueTodos.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    noDeadlineTodos.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 3. Selection Priority (In Progress tasks have top priority)
    if (inProgressTodos.isNotEmpty) {
      selectedTodo = inProgressTodos.first;
    } else if (todayTodos.isNotEmpty) {
      selectedTodo = todayTodos.first;
    } else if (futureTodos.isNotEmpty) {
      selectedTodo = futureTodos.first;
    } else if (overdueTodos.isNotEmpty) {
      selectedTodo = overdueTodos.first;
    } else if (noDeadlineTodos.isNotEmpty) {
      selectedTodo = noDeadlineTodos.first;
    }

    if (selectedTodo == null) {
      // --- Quote Banner ---
      final quotes = [
        "Lost time is never found again.",
        "Your time is limited, don't waste it.",
        "Time is what we want most, but use worst.",
        "The way we spend our time defines who we are.",
        "Punctuality is the soul of business.",
        "Time is money.",
        "Better late than never, but never late is better.",
        "Time flies like an arrow.",
        "Master your time, master your life.",
        "Chronos watches over your moments.",
      ];
      // Rotate every 10 seconds
      final quoteIndex = (now.millisecondsSinceEpoch ~/ 10000) % quotes.length;

      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isAppDark ? Colors.white.withOpacity(0.3) : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            quotes[quoteIndex].toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9 * widget.uiScale,
              color: isAppDark ? Colors.white.withOpacity(0.4) : const Color(0xFF64748B),
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    final isKo = AppStrings.of(context).isKo;
    final bool hasDeadline = selectedTodo.targetDate != null;
    final diff = hasDeadline
        ? selectedTodo.targetDate!.difference(now)
        : Duration.zero;
    final isOverdue = hasDeadline && diff.isNegative;
    final absDuration = diff.abs();

    final h = absDuration.inHours;
    final m = absDuration.inMinutes % 60;
    final s = absDuration.inSeconds % 60;

    final timeStr = hasDeadline
        ? (isKo
            ? '${h > 0 ? '$h시간 ' : ''}${m}분 ${s}초'
            : '${h > 0 ? '${h}h ' : ''}${m}m ${s}s')
        : (isKo ? '기한 없음' : 'No deadline');

    final statusText = !hasDeadline
        ? 'TODO'
        : isOverdue
        ? (isKo ? '마감 지남' : 'OVERDUE')
        : (isKo ? '마감 임박' : 'DUE SOON');

    final noteText = selectedTodo.note.isNotEmpty
        ? selectedTodo.note
        : (isKo ? '이름 없는 TODO' : 'Untitled task');

    final mainColor = !hasDeadline
        ? widget.getCategoryColor(selectedTodo.category).withOpacity(0.5)
        : isOverdue
        ? const Color(0xFFEF4444)
        : widget.getCategoryColor(selectedTodo.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: mainColor,
                shape: BoxShape.circle,
                boxShadow: [
                  if (hasDeadline)
                    BoxShadow(color: mainColor.withOpacity(0.5), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _MarqueeText(
                text: '$statusText: $noteText',
                style: GoogleFonts.inter(
                  fontSize: 12 * widget.uiScale,
                  color: mainColor,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          hasDeadline
              ? (isOverdue
                  ? (isKo ? '$timeStr 지남' : '$timeStr overdue')
                  : (isKo ? '$timeStr 남음' : '$timeStr left'))
              : (isKo ? '기한 없음' : 'No deadline'),
          style: GoogleFonts.inter(
            fontSize: 10 * widget.uiScale,
            color: isAppDark ? Colors.white.withOpacity(0.4) : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ThemeController.instance.currentTheme;
    final themeAccent = currentTheme.accent;
    final filteredEntries = _showOnlyTodo
        ? widget.entries.where((e) => e.isPendingTodo).toList()
        : widget.entries;
    final int itemCount = filteredEntries.length.clamp(0, _displayedItemCount);
    final bottomInset = 150.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 400) {
              if (_displayedItemCount < filteredEntries.length) {
                setState(() {
                  _displayedItemCount = (_displayedItemCount + 30).clamp(0, filteredEntries.length);
                });
              }
            }
            return false;
          },
          child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 유료(Pro) 버전: 명언 및 긴급 카운트다운 문구 노출
                    // 무료 버전: 바뀌는 문구 제거 및 애드몹 배너 광고 노출
                    if (kIsProVersion) ...[
                      _buildUrgentCountdown(),
                      const SizedBox(height: 16),
                    ] else ...[
                      const TopBannerAdWidget(),
                    ],

                    // Header (Compact)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            _currentTime,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 46 * widget.uiScale,
                              fontWeight: FontWeight.w800,
                              color: ThemeController.instance.currentTheme.isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -2,
                            ),
                          ),
                          Text(
                            _currentDate.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: ThemeController.instance.currentTheme.isDark
                                  ? Colors.white.withOpacity(0.35)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w800,
                              fontSize: 10 * widget.uiScale,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            
            // Pinned Quick Add Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _QuickAddHeaderDelegate(
                onTap: _showAddEntrySheet,
                categoryColor: widget.getCategoryColor(_selectedCategory),
                uiScale: widget.uiScale,
                theme: ThemeController.instance.currentTheme,
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _showOnlyTodo = !_showOnlyTodo;
                      _displayedItemCount = 30;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _showOnlyTodo
                            ? themeAccent.withOpacity(0.14)
                            : themeAccent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _showOnlyTodo
                              ? themeAccent.withOpacity(0.45)
                              : themeAccent.withOpacity(0.22),
                          width: _showOnlyTodo ? 1.2 : 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showOnlyTodo
                                ? Icons.filter_list_rounded
                                : Icons.checklist_rounded,
                            size: 14 * widget.uiScale,
                            color: _showOnlyTodo
                                ? themeAccent
                                : themeAccent.withOpacity(0.85),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.of(context).viewTasks,
                            style: GoogleFonts.inter(
                              fontSize: 9.5 * widget.uiScale,
                              fontWeight: _showOnlyTodo
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _showOnlyTodo
                                  ? themeAccent
                                  : (currentTheme.isDark
                                      ? Colors.white.withOpacity(0.9)
                                      : const Color(0xFF1E293B)),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_showSwipeGuide && widget.entries.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: appCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: appBorder,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isAppDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.getCategoryColor(_selectedCategory).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.swipe_left_rounded,
                            size: 16,
                            color: widget.getCategoryColor(_selectedCategory),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.of(context).swipeGuideText,
                            style: GoogleFonts.inter(
                              color: appText,
                              fontSize: 12 * widget.uiScale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _dismissSwipeGuide,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: appTextTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 48,
                        color: appTextTertiary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.of(context).isKo ? '기록된 순간이 없습니다' : 'No entries recorded yet',
                        style: GoogleFonts.inter(
                          color: appTextTertiary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_showOnlyTodo &&
                !widget.entries.any((e) => e.isPendingTodo))
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off_rounded,
                        size: 48,
                        color: appTextTertiary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.of(context).isKo ? '대기 중인 TODO가 없습니다' : 'No pending tasks',
                        style: GoogleFonts.inter(
                          color: appTextTertiary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, bottomInset),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= itemCount) return null;
                      final entry = filteredEntries[index];
                      return TimestampListItem(
                        entry: entry,
                        categoryColor: _getCategoryColor(entry.category),
                        onDelete: () => _deleteEntry(entry.id),
                        onStatusToggle: () => _toggleEntryStatus(entry.id),
                        onUpdate: _updateEntry,
                        categories: widget.categories,
                        getCategoryColor: _getCategoryColor,
                        uiScale: widget.uiScale,
                      );
                    },
                    childCount: itemCount,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }
}

class TimestampListItem extends StatefulWidget {
  final TimestampEntry entry;
  final Color categoryColor;
  final VoidCallback onDelete;
  final VoidCallback onStatusToggle;
  final ValueChanged<TimestampEntry>? onUpdate;
  final List<String>? categories;
  final Color Function(String)? getCategoryColor;
  final double uiScale;
  final bool initialExpanded;
  final bool readOnly;

  const TimestampListItem({
    super.key,
    required this.entry,
    required this.categoryColor,
    required this.onDelete,
    required this.onStatusToggle,
    this.onUpdate,
    this.categories,
    this.getCategoryColor,
    required this.uiScale,
    this.initialExpanded = false,
    this.readOnly = false,
  });

  @override
  State<TimestampListItem> createState() => _TimestampListItemState();
}

void _showFullScreenImagePreview(BuildContext context, String imagePath) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.92),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 둥근 직사각형 점선 테두리 페인터
class DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double phase; // 0.0 ~ 1.0 (흐르는 애니메이션)

  const DashedRRectPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 20.0,
    this.dashWidth = 5.0,
    this.dashGap = 3.5,
    this.phase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color.opacity == 0 || strokeWidth <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final halfStroke = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        halfStroke,
        halfStroke,
        math.max(0.0, size.width - strokeWidth),
        math.max(0.0, size.height - strokeWidth),
      ),
      Radius.circular(math.max(0.0, radius - halfStroke)),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();
    final cycle = dashWidth + dashGap;
    if (cycle <= 0) return;

    final offset = (phase * cycle) % cycle;

    for (final metric in path.computeMetrics()) {
      double distance = offset - cycle;
      while (distance < metric.length) {
        final start = math.max(0.0, distance);
        final end = math.min(metric.length, distance + dashWidth);
        if (start < end) {
          dashedPath.addPath(
            metric.extractPath(start, end),
            Offset.zero,
          );
        }
        distance += cycle;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        radius != oldDelegate.radius ||
        dashWidth != oldDelegate.dashWidth ||
        dashGap != oldDelegate.dashGap ||
        phase != oldDelegate.phase;
  }
}

class _TimestampListItemState extends State<TimestampListItem> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  bool _isTimelineExpanded = true;
  late AnimationController _borderFlowController;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _borderFlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.entry.isInProgress) {
      _borderFlowController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TimestampListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialExpanded != oldWidget.initialExpanded) {
      _isExpanded = widget.initialExpanded;
    }
    if (widget.entry.isInProgress && !_borderFlowController.isAnimating) {
      _borderFlowController.repeat();
    } else if (!widget.entry.isInProgress && _borderFlowController.isAnimating) {
      _borderFlowController.stop();
    }
  }

  @override
  void dispose() {
    _borderFlowController.dispose();
    super.dispose();
  }

  void _startProgress() {
    HapticFeedback.mediumImpact();
    _borderFlowController.repeat();
    final now = DateTime.now();
    final updatedSessions = List<TimeSegment>.from(widget.entry.workSessions)
      ..add(TimeSegment(start: now));
    final updated = widget.entry.copyWith(
      status: 'in_progress',
      startedTimestamp: widget.entry.startedTimestamp ?? now,
      lastResumedTimestamp: now,
      workSessions: updatedSessions,
    );
    widget.onUpdate?.call(updated);
  }

  void _pauseProgress() {
    HapticFeedback.lightImpact();
    _borderFlowController.stop();
    final now = DateTime.now();
    final updatedSessions = List<TimeSegment>.from(widget.entry.workSessions);
    if (updatedSessions.isNotEmpty && updatedSessions.last.end == null) {
      updatedSessions[updatedSessions.length - 1] =
          updatedSessions.last.copyWith(end: now);
    } else {
      final start = widget.entry.lastResumedTimestamp ?? widget.entry.startedTimestamp ?? now;
      updatedSessions.add(TimeSegment(start: start, end: now));
    }
    int totalSec = 0;
    for (final s in updatedSessions) {
      if (s.end != null) totalSec += s.end!.difference(s.start).inSeconds;
    }
    final updated = widget.entry.copyWith(
      status: 'paused',
      totalActiveSeconds: totalSec,
      workSessions: updatedSessions,
      clearLastResumedTimestamp: true,
    );
    widget.onUpdate?.call(updated);
  }

  void _resumeProgress() {
    HapticFeedback.mediumImpact();
    _borderFlowController.repeat();
    final now = DateTime.now();
    final updatedSessions = List<TimeSegment>.from(widget.entry.workSessions)
      ..add(TimeSegment(start: now));
    final updated = widget.entry.copyWith(
      status: 'in_progress',
      lastResumedTimestamp: now,
      workSessions: updatedSessions,
    );
    widget.onUpdate?.call(updated);
  }

  Widget _buildWorkSessionsTimeline(Color color, bool isDark) {
    if (widget.entry.workSessions.isEmpty && !widget.entry.isManualDuration) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _isTimelineExpanded = !_isTimelineExpanded),
              child: Row(
                children: [
                  Icon(Icons.timeline_rounded, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.of(context).milestoneTitle,
                    style: GoogleFonts.inter(
                      fontSize: 10 * widget.uiScale,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (widget.entry.isManualDuration) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
                      ),
                      child: Text(
                        AppStrings.of(context).manualInputBadge,
                        style: GoogleFonts.inter(
                          fontSize: 8.5 * widget.uiScale,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                  if (widget.entry.effectiveDurationSeconds > 0) ...[
                    const Spacer(),
                    Text(
                      '${AppStrings.of(context).totalDurationPrefix}${formatSecondsKo(widget.entry.effectiveDurationSeconds)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5 * widget.uiScale,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ] else ...[
                    const Spacer(),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    _isTimelineExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14 * widget.uiScale,
                    color: color.withOpacity(0.8),
                  ),
                ],
              ),
            ),
            if (_isTimelineExpanded) ...[
              const SizedBox(height: 5),
              ...widget.entry.workSessions.asMap().entries.map((item) {
                final idx = item.key + 1;
                final seg = item.value;
                final sameDay = seg.end == null ||
                    (seg.start.year == seg.end!.year &&
                        seg.start.month == seg.end!.month &&
                        seg.start.day == seg.end!.day);
                final startStr = sameDay
                    ? DateFormat('HH:mm:ss').format(seg.start)
                    : DateFormat('M/d HH:mm:ss').format(seg.start);
                final endStr = seg.end != null
                    ? (sameDay
                        ? DateFormat('HH:mm:ss').format(seg.end!)
                        : DateFormat('M/d HH:mm:ss').format(seg.end!))
                    : AppStrings.of(context).milestoneInProgress;
                final durationDiff = seg.end != null ? seg.end!.difference(seg.start) : null;
                final durStr = durationDiff != null ? ' (${formatDurationKo(durationDiff)})' : '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.of(context).milestoneLap(idx),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5 * widget.uiScale,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$startStr ~ $endStr$durStr',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5 * widget.uiScale,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (widget.entry.isManualDuration)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 11 * widget.uiScale, color: color),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.of(context).manualInputDurationLabel,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5 * widget.uiScale,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          formatSecondsKo(widget.entry.effectiveDurationSeconds),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5 * widget.uiScale,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDurationString(DateTime start, DateTime end) {
    final diff = end.difference(start);
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return '${diff.inSeconds}s';
  }

  String _formatDurationMinutes(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Color _getAdjustedColor() {
    if (widget.entry.status == 'done') {
      final hsl = HSLColor.fromColor(widget.categoryColor);
      return hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();
    }
    return widget.categoryColor;
  }

  Widget _buildDDayBadge(DateTime targetDate, Color categoryColor, {bool compact = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final diff = target.difference(today).inDays;

    String text;
    Color badgeColor;

    if (diff > 0) {
      text = 'D-$diff';
      badgeColor = categoryColor;
    } else if (diff == 0) {
      text = 'D-Day';
      badgeColor = categoryColor;
    } else {
      text = 'D+${diff.abs()}';
      badgeColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 1.5 : 2.5,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withOpacity(diff <= 0 ? 0.6 : 0.35),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: (compact ? 8.5 : 10) * widget.uiScale,
          fontWeight: FontWeight.w800,
          color: badgeColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = widget.entry.imagePath != null || widget.entry.doneImagePath != null;
    final bool hasLongText = widget.entry.note.contains('\n') || widget.entry.note.length > 30;
    final bool hasDoneExtra = widget.entry.doneNote != null && widget.entry.doneNote!.isNotEmpty;
    final bool hasWorkSessions = widget.entry.workSessions.isNotEmpty || widget.entry.isManualDuration;
    final bool isExpandable = hasImage || hasLongText || hasDoneExtra || hasWorkSessions;

    final currentTheme = ThemeController.instance.currentTheme;
    final isDark = currentTheme.isDark;
    final adjustedColor = _getAdjustedColor();
    final isDone = widget.entry.status == 'done';
    final isTodo = widget.entry.status == 'todo';
    final isInProgress = widget.entry.isInProgress;
    final isPaused = widget.entry.isPaused;
    final isPendingTodo = widget.entry.isPendingTodo;
    final isNormal = widget.entry.status == 'none';
    final bool showStartPrefix = isPendingTodo || isDone || widget.entry.computedDurationMinutes != null;

    return Dismissible(
      key: ValueKey(widget.entry.id),
      direction: widget.readOnly ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmSheet(context);
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 12 * widget.uiScale),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text(
              AppStrings.of(context).commonDelete,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: GestureDetector(
        onTap: isExpandable ? () => setState(() => _isExpanded = !_isExpanded) : null,
        child: AnimatedBuilder(
          animation: _borderFlowController,
          builder: (context, child) {
            final isDashed = isInProgress || isPaused;
            return Container(
              margin: EdgeInsets.only(bottom: 10 * widget.uiScale),
              child: CustomPaint(
                foregroundPainter: isDashed
                    ? DashedRRectPainter(
                        color: adjustedColor.withOpacity(isDark ? 0.8 : 0.9),
                        strokeWidth: 1.6,
                        radius: 20,
                        dashWidth: 7.5,
                        dashGap: 4.5,
                        phase: isInProgress ? _borderFlowController.value : 0.0,
                      )
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 13 * widget.uiScale,
                    vertical: 10 * widget.uiScale,
                  ),
                  decoration: BoxDecoration(
                    color: currentTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: isDashed
                        ? null
                        : Border.all(
                            color: isDone
                                ? adjustedColor.withOpacity(isDark ? 0.42 : 0.6)
                                : (isDark ? adjustedColor.withOpacity(0.24) : const Color(0xFFE2E8F0)),
                            width: 1.2,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: adjustedColor.withOpacity(isDone ? 0.08 : (isInProgress ? 0.08 : 0.04)),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Full-width Category & Date Header Row (Right to the edge!)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: Center(
                          child: isExpandable
                              ? GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                                  child: AnimatedRotation(
                                    turns: _isExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 13 * widget.uiScale,
                                      color: adjustedColor,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: adjustedColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 120 * widget.uiScale),
                        child: Text(
                          widget.entry.category,
                          style: GoogleFonts.inter(
                            fontSize: 11 * widget.uiScale,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white.withOpacity(0.55) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasImage && !_isExpanded) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_camera_rounded,
                                size: 10,
                                color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                AppStrings.of(context).badgePhoto,
                                style: GoogleFonts.inter(
                                  fontSize: 8.5 * widget.uiScale,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isInProgress || isPaused) ...[
                        if (widget.entry.targetDate != null) ...[
                          const SizedBox(width: 5),
                          _buildDDayBadge(widget.entry.targetDate!, adjustedColor, compact: true),
                        ],
                      ] else if (isTodo) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: adjustedColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TODO',
                            style: GoogleFonts.inter(
                              fontSize: 8.5 * widget.uiScale,
                              fontWeight: FontWeight.w700,
                              color: adjustedColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (widget.entry.targetDate != null) ...[
                          const SizedBox(width: 5),
                          _buildDDayBadge(widget.entry.targetDate!, adjustedColor, compact: true),
                        ],
                      ] else if (isDone) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: adjustedColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: adjustedColor.withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 9.5 * widget.uiScale,
                                color: adjustedColor.withOpacity(0.9),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${formatSecondsKo(widget.entry.effectiveDurationSeconds)}${AppStrings.of(context).spentDurationSuffix}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8.5 * widget.uiScale,
                                  fontWeight: FontWeight.w600,
                                  color: adjustedColor.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        DateFormat('yyyy.MM.dd').format(widget.entry.timestamp),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10 * widget.uiScale,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF64748B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Top Right (Done check circle or options)
                      if (isDone)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.readOnly ? null : widget.onStatusToggle,
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: adjustedColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (!widget.readOnly)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showEntryOptionsSheet(context, adjustedColor),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.more_vert_rounded,
                              color: isDark ? Colors.white.withOpacity(0.55) : Colors.black.withOpacity(0.55),
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // 2. Start Time & Main Note Text (Full Width)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18 * widget.uiScale,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: Center(
                                child: Icon(
                                  showStartPrefix
                                      ? Icons.play_circle_outline_rounded
                                      : Icons.access_time_rounded,
                                  size: (showStartPrefix ? 11 : 10) * widget.uiScale,
                                  color: showStartPrefix
                                      ? adjustedColor.withOpacity(0.75)
                                      : (isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('HH:mm').format(widget.entry.timestamp),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.0 * widget.uiScale,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.entry.note.isEmpty
                              ? (hasImage ? (AppStrings.of(context).isKo ? '사진 메모' : 'Photo memo') : (AppStrings.of(context).isKo ? '기록된 순간' : 'Recorded moment'))
                              : widget.entry.note,
                          style: GoogleFonts.inter(
                            color: isDone
                                ? (isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B))
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            fontSize: 13.5 * widget.uiScale,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: (isExpandable && !_isExpanded) ? 1 : null,
                          overflow: (isExpandable && !_isExpanded) ? TextOverflow.ellipsis : TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                  // Target Date (TODO ONLY)
                  if (isTodo && widget.entry.targetDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: adjustedColor.withOpacity(0.8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('yyyy-MM-dd').format(widget.entry.targetDate!),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10 * widget.uiScale,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF475569),
                          ),
                        ),
                        const Spacer(),
                        _buildDDayBadge(widget.entry.targetDate!, adjustedColor, compact: false),
                      ],
                    ),
                  ],

                  // 1. Photo (Shown under note when expanded, rectangular without rounded corners - 100% full view)
                  if (widget.entry.imagePath != null && _isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onTap: () => _showFullScreenImagePreview(context, widget.entry.imagePath!),
                        child: Image.file(
                          File(widget.entry.imagePath!),
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),

                  // 2. Completed Info (Left-aligned, clearly separated if TODO image exists)
                  if (isDone && widget.entry.doneTimestamp != null) ...[
                    if (widget.entry.imagePath != null && _isExpanded) ...[
                      const SizedBox(height: 14),
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      const SizedBox(height: 3),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20 * widget.uiScale,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: Center(
                                  child: Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 11 * widget.uiScale,
                                    color: adjustedColor.withOpacity(0.85),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                DateFormat('HH:mm').format(widget.entry.doneTimestamp!),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.0 * widget.uiScale,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            constraints: BoxConstraints(minHeight: 20 * widget.uiScale),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              (widget.entry.doneNote != null && widget.entry.doneNote!.trim().isNotEmpty)
                                  ? widget.entry.doneNote!
                                  : (widget.entry.note.isEmpty ? (hasImage ? (AppStrings.of(context).isKo ? '사진 메모' : 'Photo memo') : AppStrings.of(context).commonDone) : widget.entry.note),
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1E293B),
                                fontSize: 13.5 * widget.uiScale,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                              maxLines: (isExpandable && !_isExpanded) ? 1 : null,
                              overflow: (isExpandable && !_isExpanded) ? TextOverflow.ellipsis : TextOverflow.visible,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // 3. Duration / Completion for normal entry with duration (Left-aligned)
                  if (widget.entry.computedDurationMinutes != null && !isDone) ...[
                    if (widget.entry.imagePath != null && _isExpanded) ...[
                      const SizedBox(height: 14),
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      const SizedBox(height: 3),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: Center(
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 11 * widget.uiScale,
                              color: adjustedColor.withOpacity(0.85),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('HH:mm').format(widget.entry.timestamp.add(Duration(minutes: widget.entry.computedDurationMinutes!))),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.0 * widget.uiScale,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.timer_outlined,
                          size: 11 * widget.uiScale,
                          color: adjustedColor.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${formatSecondsKo(widget.entry.effectiveDurationSeconds)}${AppStrings.of(context).spentDurationSuffix}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5 * widget.uiScale,
                            fontWeight: FontWeight.w600,
                            color: adjustedColor.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // 4. Task Completion Photo (Clearly separated under completed section, rectangular without rounded corners - 100% full view)
                  if (isDone && widget.entry.doneImagePath != null && _isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onTap: () => _showFullScreenImagePreview(context, widget.entry.doneImagePath!),
                        child: Image.file(
                          File(widget.entry.doneImagePath!),
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),

                  // Work Sessions Milestone Timeline (시각화)
                  if ((widget.entry.workSessions.isNotEmpty || widget.entry.isManualDuration) && _isExpanded)
                    _buildWorkSessionsTimeline(adjustedColor, isDark),

                  // 5. Action Buttons (Right-aligned at bottom: 착수 / 일시정지 / 계속하기 + 완료)
                  if (isPendingTodo && !widget.readOnly) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isInProgress) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _pauseProgress,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * widget.uiScale,
                                vertical: 5 * widget.uiScale,
                              ),
                              decoration: BoxDecoration(
                                color: adjustedColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: adjustedColor.withOpacity(0.35), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pause_rounded, size: 13 * widget.uiScale, color: adjustedColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.of(context).actionPause,
                                    style: GoogleFonts.inter(
                                      fontSize: 11 * widget.uiScale,
                                      fontWeight: FontWeight.w700,
                                      color: adjustedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else if (isPaused) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _resumeProgress,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * widget.uiScale,
                                vertical: 5 * widget.uiScale,
                              ),
                              decoration: BoxDecoration(
                                color: adjustedColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: adjustedColor.withOpacity(0.4), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 14 * widget.uiScale, color: adjustedColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    AppStrings.of(context).actionResume,
                                    style: GoogleFonts.inter(
                                      fontSize: 11 * widget.uiScale,
                                      fontWeight: FontWeight.w700,
                                      color: adjustedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else if (isTodo) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _startProgress,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * widget.uiScale,
                                vertical: 5 * widget.uiScale,
                              ),
                              decoration: BoxDecoration(
                                color: adjustedColor.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: adjustedColor.withOpacity(0.4), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 14 * widget.uiScale, color: adjustedColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    AppStrings.of(context).actionStart,
                                    style: GoogleFonts.inter(
                                      fontSize: 11 * widget.uiScale,
                                      fontWeight: FontWeight.w700,
                                      color: adjustedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onStatusToggle,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 11 * widget.uiScale,
                              vertical: 5 * widget.uiScale,
                            ),
                            decoration: BoxDecoration(
                              color: adjustedColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, size: 13 * widget.uiScale, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  AppStrings.of(context).actionDone,
                                  style: GoogleFonts.inter(
                                    fontSize: 11 * widget.uiScale,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: appCardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isAppDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.of(context).deleteConfirmTitle,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: appText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppStrings.of(context).deleteConfirmDesc,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: appTextSecondary,
                    ),
                  ),
                  if (widget.entry.note.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appSubtleBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: appBorder,
                        ),
                      ),
                      child: Text(
                        widget.entry.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: appText,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 76,
                        height: 46,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            backgroundColor: appSubtleBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            AppStrings.of(context).commonCancel,
                            style: GoogleFonts.inter(
                              color: appTextSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              AppStrings.of(context).commonDelete,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  void _showEntryOptionsSheet(BuildContext context, Color adjustedColor) {
    String selectedCategory = widget.entry.category;
    bool isTodo = widget.entry.isPendingTodo;
    DateTime? targetDate = widget.entry.targetDate;
    String? selectedImagePath = widget.entry.imagePath;

    final TextEditingController editNoteController =
        TextEditingController(text: widget.entry.note);

    int currentMinutes = widget.entry.computedDurationMinutes ?? 0;
    int hours = currentMinutes ~/ 60;
    int minutes = currentMinutes % 60;

    final TextEditingController hoursController =
        TextEditingController(text: hours > 0 ? hours.toString() : '');
    final TextEditingController minutesController =
        TextEditingController(text: minutes > 0 ? minutes.toString() : '');

    Future<void> pickImage(ImageSource source, StateSetter setSheetState) async {
      if (source == ImageSource.camera) {
        final String? capturedPath = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (context) => const CameraPage()),
        );
        if (capturedPath != null) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(capturedPath)}';
          final saved = await File(capturedPath).copy('${directory.path}/$fileName');
          setSheetState(() {
            selectedImagePath = saved.path;
          });
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: source, imageQuality: 85);
        if (picked != null) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(picked.path)}';
          final saved = await File(picked.path).copy('${directory.path}/$fileName');
          setSheetState(() {
            selectedImagePath = saved.path;
          });
        }
      }
    }

    Future<void> pickTargetDate(StateSetter setSheetState, Color catColor) async {
      final picked = await showDeadlineDatePicker(
        context: context,
        initialDate: targetDate,
        accentColor: catColor,
        canClear: true,
      );
      if (picked != null) {
        setSheetState(() {
          if (picked.year == 1970) {
            targetDate = null;
          } else {
            targetDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          }
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
            final activeCategoryColor = widget.getCategoryColor != null
                ? widget.getCategoryColor!(selectedCategory)
                : widget.categoryColor;

            void addMinutes(int delta) {
              int total = (hours * 60) + minutes + delta;
              if (total < 0) total = 0;
              setSheetState(() {
                hours = total ~/ 60;
                minutes = total % 60;
                hoursController.text = hours > 0 ? hours.toString() : '';
                minutesController.text = minutes > 0 ? minutes.toString() : '';
              });
            }

            void resetTime() {
              setSheetState(() {
                hours = 0;
                minutes = 0;
                hoursController.text = '';
                minutesController.text = '';
              });
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: appCardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // iOS Style Handle Bar
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: (details) {
                            if (details.primaryDelta! > 7) {
                              Navigator.pop(context);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isAppDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Compact Header (Identical to Add Sheet)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: activeCategoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.edit_note_rounded,
                                size: 16,
                                color: activeCategoryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.of(context).editEntryTitle,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: appText,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: appSubtleBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: appTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Category Chips (Identical to Add Sheet)
                        if (widget.categories != null && widget.categories!.isNotEmpty) ...[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: widget.categories!.map((cat) {
                                final isSelected = selectedCategory == cat;
                                final catColor = widget.getCategoryColor != null
                                    ? widget.getCategoryColor!(cat)
                                    : widget.categoryColor;

                                return Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: InkWell(
                                    onTap: () {
                                      setSheetState(() => selectedCategory = cat);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? catColor.withOpacity(isAppDark ? 0.22 : 0.15)
                                            : (isAppDark ? const Color(0xFF20242F) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? catColor
                                              : appBorder,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: catColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            cat,
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5 * widget.uiScale,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                              color: isSelected ? appText : appTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // TODO Switch (Identical to Add Sheet)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: appSubtleBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: appBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.task_alt_rounded,
                                size: 16,
                                color: isTodo ? activeCategoryColor : appTextTertiary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppStrings.of(context).registerAsTodo,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isTodo ? appText : appTextSecondary,
                                ),
                              ),
                              const Spacer(),
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: isTodo,
                                  onChanged: (val) {
                                    setSheetState(() => isTodo = val);
                                  },
                                  activeColor: activeCategoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isTodo) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => pickTargetDate(setSheetState, activeCategoryColor),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: appSubtleBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: appBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 14, color: appTextTertiary),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.of(context).dueDate,
                                    style: GoogleFonts.inter(fontSize: 12.5, color: appTextSecondary),
                                  ),
                                  const Spacer(),
                                  Text(
                                    targetDate == null ? AppStrings.of(context).selectDate : DateFormat('yyyy.MM.dd').format(targetDate!),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: targetDate != null ? activeCategoryColor : appTextTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        if (!isTodo) ...[
                          const SizedBox(height: 12),

                          // Spent Time (소요 시간 입력 - 일반 항목 전용)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: appSubtleBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: appBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined, size: 15, color: appTextTertiary),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppStrings.of(context).spentTimeForStats,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: appTextSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      (hours * 60 + minutes) > 0
                                          ? '${hours > 0 ? "$hours${AppStrings.of(context).unitHour} " : ""}$minutes${AppStrings.of(context).unitMinute}'
                                          : AppStrings.of(context).notSet,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: (hours * 60 + minutes) > 0 ? activeCategoryColor : appTextTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 38,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: isAppDark ? Colors.white.withOpacity(0.04) : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: appBorder),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: hoursController,
                                                keyboardType: TextInputType.number,
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 13.5,
                                                  color: appText,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: '0',
                                                  hintStyle: TextStyle(color: appTextTertiary),
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                ),
                                                onChanged: (val) {
                                                  final p = int.tryParse(val) ?? 0;
                                                  setSheetState(() => hours = p.clamp(0, 999));
                                                },
                                              ),
                                            ),
                                            Text(AppStrings.of(context).unitHour, style: GoogleFonts.inter(fontSize: 11.5, color: appTextTertiary)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 38,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: isAppDark ? Colors.white.withOpacity(0.04) : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: appBorder),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: minutesController,
                                                keyboardType: TextInputType.number,
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 13.5,
                                                  color: appText,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: '0',
                                                  hintStyle: TextStyle(color: appTextTertiary),
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                ),
                                                onChanged: (val) {
                                                  final p = int.tryParse(val) ?? 0;
                                                  setSheetState(() => minutes = p.clamp(0, 59));
                                                },
                                              ),
                                            ),
                                            Text(AppStrings.of(context).unitMinute, style: GoogleFonts.inter(fontSize: 11.5, color: appTextTertiary)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _buildPresetChip('+15${AppStrings.of(context).unitMinute}', () => addMinutes(15), activeCategoryColor),
                                      const SizedBox(width: 6),
                                      _buildPresetChip('+30${AppStrings.of(context).unitMinute}', () => addMinutes(30), activeCategoryColor),
                                      const SizedBox(width: 6),
                                      _buildPresetChip('+1${AppStrings.of(context).unitHour}', () => addMinutes(60), activeCategoryColor),
                                      const SizedBox(width: 6),
                                      _buildPresetChip('+2${AppStrings.of(context).unitHour}', () => addMinutes(120), activeCategoryColor),
                                      const SizedBox(width: 6),
                                      _buildPresetChip(AppStrings.of(context).resetPreset, resetTime, appTextTertiary, isOutline: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Image Preview (Identical to Add Sheet)
                        if (selectedImagePath != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(selectedImagePath!),
                                    height: 130,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setSheetState(() => selectedImagePath = null);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Note Input (Left aligned, vertically centered with icons)
                        TextField(
                          controller: editNoteController,
                          maxLines: 4,
                          minLines: 1,
                          textAlign: TextAlign.start,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (_) => setSheetState(() {}),
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: appText,
                          ),
                          decoration: InputDecoration(
                            hintText: AppStrings.of(context).editEntryNoteHintQuick,
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: appTextTertiary,
                            ),
                            filled: true,
                            fillColor: appSubtleBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            suffixIconConstraints: const BoxConstraints(minHeight: 40),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.camera_alt_outlined, size: 20),
                                    color: appTextSecondary,
                                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                    padding: EdgeInsets.zero,
                                    onPressed: () => pickImage(ImageSource.camera, setSheetState),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                                    color: appTextSecondary,
                                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                    padding: EdgeInsets.zero,
                                    onPressed: () => pickImage(ImageSource.gallery, setSheetState),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons Row (Compact Cancel + Wide Main Button)
                        Builder(
                          builder: (context) {
                            final bool canUpdate = editNoteController.text.trim().isNotEmpty || selectedImagePath != null;
                            return Row(
                              children: [
                                SizedBox(
                                  width: 76,
                                  height: 46,
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    style: TextButton.styleFrom(
                                      backgroundColor: appSubtleBg,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      AppStrings.of(context).commonCancel,
                                      style: GoogleFonts.inter(
                                        color: appTextSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 46,
                                    child: ElevatedButton(
                                      onPressed: canUpdate
                                          ? () {
                                              final totalMins = (hours * 60) + minutes;
                                              if (widget.onUpdate != null) {
                                                final String resolvedStatus = widget.entry.isDone
                                                    ? 'done'
                                                    : (widget.entry.isInProgress
                                                        ? (isTodo ? 'in_progress' : 'none')
                                                        : (widget.entry.isPaused
                                                            ? (isTodo ? 'paused' : 'none')
                                                            : (isTodo ? 'todo' : 'none')));
                                                widget.onUpdate!(widget.entry.copyWith(
                                                  note: editNoteController.text.trim(),
                                                  category: selectedCategory,
                                                  status: resolvedStatus,
                                                  targetDate: isTodo ? targetDate : null,
                                                  imagePath: selectedImagePath,
                                                  clearImage: selectedImagePath == null,
                                                  manualDurationMinutes: (!isTodo && totalMins > 0)
                                                      ? totalMins
                                                      : (widget.entry.isDone && totalMins > 0 ? totalMins : null),
                                                  clearManualDuration: (!isTodo && totalMins <= 0) || (widget.entry.isDone && totalMins <= 0),
                                                ));
                                              }
                                              Navigator.pop(ctx);
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: canUpdate
                                            ? activeCategoryColor
                                            : (isAppDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                                        foregroundColor: canUpdate
                                            ? (activeCategoryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                                            : (isAppDark ? Colors.white30 : Colors.black26),
                                        disabledBackgroundColor: isAppDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                                        disabledForegroundColor: isAppDark ? Colors.white30 : Colors.black26,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        AppStrings.of(context).editEntrySave,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap, Color color, {bool isOutline = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(isOutline ? 0.4 : 0.25),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: (color == Colors.white38 || color == appTextTertiary) ? appTextSecondary : color,
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height - 16, // Matching the margin set in Container
      const Radius.circular(24),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final ui.PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}

class CategoryView extends StatefulWidget {
  final ValueNotifier<List<TimestampEntry>> entriesNotifier;
  final Function(String) onDelete;
  final Function(String) onToggle;
  final Function(String) onClearCategory;
  final Function(String) onDeleteCategory;
  final Function(TimestampEntry)? onUpdateEntry;
  final double uiScale;
  final List<String> categories;
  final Map<String, Color> categoryColors;
  final String defaultCategory;
  final Function(String, Color) onAddCategory;
  final Function(int, int) onReorderCategories;
  final Function(String) onSetDefaultCategory;
  final Function(String, Color) onUpdateCategoryColor;
  final bool Function(String, String)? onRenameCategory;

  const CategoryView({
    super.key,
    required this.entriesNotifier,
    required this.onDelete,
    required this.onToggle,
    required this.onClearCategory,
    required this.onDeleteCategory,
    this.onUpdateEntry,
    required this.uiScale,
    required this.categories,
    required this.categoryColors,
    required this.defaultCategory,
    required this.onAddCategory,
    required this.onReorderCategories,
    required this.onSetDefaultCategory,
    required this.onUpdateCategoryColor,
    this.onRenameCategory,
  });

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  void _navigateToCategoryDetail(BuildContext context, String cat, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailView(
          category: cat,
          entriesNotifier: widget.entriesNotifier,
          categoryColor: color,
          onDelete: widget.onDelete,
          onToggle: widget.onToggle,
          onClearCategory: widget.onClearCategory,
          onUpdateEntry: widget.onUpdateEntry,
          categories: widget.categories,
          categoryColors: widget.categoryColors,
          uiScale: widget.uiScale,
          onUpdateCategoryColor: widget.onUpdateCategoryColor,
          onRenameCategory: widget.onRenameCategory,
        ),
      ),
    );
  }

  final Map<String, IconData> _categoryIcons = const {
    'General': Icons.folder_outlined,
    'Work': Icons.work_outline_rounded,
    'Personal': Icons.person_outline_rounded,
    'Health': Icons.favorite_outline_rounded,
    'Study': Icons.menu_book_rounded,
  };

  IconData _getCategoryIcon(String cat) {
    if (_categoryIcons.containsKey(cat)) return _categoryIcons[cat]!;
    final lower = cat.toLowerCase();
    if (lower.contains('work') || lower.contains('업무') || lower.contains('회사') || lower.contains('일')) {
      return Icons.work_outline_rounded;
    }
    if (lower.contains('study') || lower.contains('공부') || lower.contains('학습') || lower.contains('독서')) {
      return Icons.school_outlined;
    }
    if (lower.contains('health') || lower.contains('운동') || lower.contains('건강') || lower.contains('헬스')) {
      return Icons.fitness_center_rounded;
    }
    if (lower.contains('person') || lower.contains('개인') || lower.contains('일상') || lower.contains('생각')) {
      return Icons.person_outline_rounded;
    }
    if (lower.contains('food') || lower.contains('음식') || lower.contains('식사') || lower.contains('맛집')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('shop') || lower.contains('쇼핑') || lower.contains('구매')) {
      return Icons.shopping_bag_outlined;
    }
    if (lower.contains('money') || lower.contains('finance') || lower.contains('돈') || lower.contains('금융') || lower.contains('가계부')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (lower.contains('trip') || lower.contains('travel') || lower.contains('여행')) {
      return Icons.flight_takeoff_rounded;
    }
    if (lower.contains('idea') || lower.contains('아이디어')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (lower.contains('hobby') || lower.contains('취미')) {
      return Icons.palette_outlined;
    }
    return Icons.folder_outlined;
  }

  void _showDeleteCategorySheet(BuildContext context, String cat) {
    showModalBottomSheet(
      context: context,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: appCardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 7) {
                        Navigator.pop(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isAppDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.of(context).categoryDeleteTitle,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: appText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppStrings.of(context).isKo
                        ? '"$cat" 카테고리와 연관된 모든 기록이 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'
                        : 'All records associated with "$cat" will be deleted.\nThis action cannot be undone.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.45,
                      color: appTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons Row (Compact Cancel + Wide Main Button)
                  Row(
                    children: [
                      SizedBox(
                        width: 76,
                        height: 46,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: appSubtleBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            AppStrings.of(context).commonCancel,
                            style: GoogleFonts.inter(
                              color: appTextSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onDeleteCategory(cat);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              AppStrings.of(context).commonDelete,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditCategorySheet(BuildContext context, String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    final Color color = widget.categoryColors[currentName] ?? const Color(0xFF6366F1);
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final isKo = AppStrings.of(context).isKo;
            return Container(
              decoration: BoxDecoration(
                color: appCardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta! > 7) {
                          Navigator.pop(context);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isAppDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.edit_rounded, size: 16, color: color),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isKo ? '카테고리 이름 변경' : 'Rename Category',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: appText,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: appSubtleBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: appTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isKo ? '새 카테고리 이름' : 'New Category Name',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: appTextTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        color: appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.of(context).categoryNameHint,
                        hintStyle: GoogleFonts.inter(color: appTextTertiary),
                        filled: true,
                        fillColor: appSubtleBg,
                        errorText: errorText,
                        errorStyle: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: color, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        final trimmed = val.trim();
                        if (trimmed.isEmpty) {
                          setSheetState(() => errorText = isKo ? '이름을 입력해주세요.' : 'Please enter a name.');
                        } else if (trimmed != currentName && widget.categories.contains(trimmed)) {
                          setSheetState(() => errorText = isKo ? '이미 존재하는 카테고리 이름입니다.' : 'Category already exists.');
                        } else {
                          if (errorText != null) {
                            setSheetState(() => errorText = null);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons Row (Compact Cancel + Wide Main Button)
                    Row(
                      children: [
                        SizedBox(
                          width: 76,
                          height: 46,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: appSubtleBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              AppStrings.of(context).commonCancel,
                              style: GoogleFonts.inter(
                                color: appTextSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () {
                                final newName = nameController.text.trim();
                                if (newName.isEmpty) {
                                  setSheetState(() => errorText = isKo ? '이름을 입력해주세요.' : 'Please enter a name.');
                                  return;
                                }
                                if (newName != currentName && widget.categories.contains(newName)) {
                                  setSheetState(() => errorText = isKo ? '이미 존재하는 카테고리 이름입니다.' : 'Category already exists.');
                                  return;
                                }

                                if (newName != currentName && widget.onRenameCategory != null) {
                                  widget.onRenameCategory!(currentName, newName);
                                }
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                AppStrings.of(context).commonSave,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryOptionsSheet(BuildContext context, String cat) {
    final color = widget.categoryColors[cat] ?? const Color(0xFF6366F1);

    showModalBottomSheet(
      context: context,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: appCardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 7) {
                        Navigator.pop(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isAppDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getCategoryIcon(cat), size: 18, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: appText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: Icon(Icons.edit_outlined, color: appTextSecondary, size: 20),
                    title: Text(
                      AppStrings.of(context).isKo ? '이름 변경' : 'Rename',
                      style: GoogleFonts.inter(color: appText, fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditCategorySheet(context, cat);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: color, size: 20),
                    title: Text(
                      AppStrings.of(context).isKo ? '색상 변경' : 'Change Color',
                      style: GoogleFonts.inter(color: appText, fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () async {
                      Navigator.pop(context);
                      final picked = await showCustomColorPickerDialog(
                        context,
                        initialColor: color,
                      );
                      if (picked != null) {
                        widget.onUpdateCategoryColor(cat, picked);
                      }
                    },
                  ),
                  if (cat != 'General')
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      title: Text(
                        AppStrings.of(context).categoryDeleteTitle,
                        style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteCategorySheet(context, cat);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReorderAndDefaultSheet(BuildContext context) {
    final List<String> sheetCategories = List<String>.from(widget.categories);
    String sheetDefault = widget.defaultCategory;
    final theme = ThemeController.instance.currentTheme;
    final themeAccent = (!theme.isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isKo = AppStrings.of(context).isKo;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: appCardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) {
                          if (details.primaryDelta! > 7) {
                            Navigator.pop(context);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isAppDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isKo ? '카테고리 순서 및 기본값 설정' : 'Category Order & Defaults',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: appText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isKo ? '드래그하여 순서 변경 · 별표를 눌러 기본 카테고리 지정' : 'Drag to reorder · Tap star to set default',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: appTextTertiary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: appTextSecondary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            canvasColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: sheetCategories.length,
                            onReorder: (oldIndex, newIndex) {
                              widget.onReorderCategories(oldIndex, newIndex);
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = sheetCategories.removeAt(oldIndex);
                              sheetCategories.insert(newIndex, item);
                              setSheetState(() {});
                            },
                            itemBuilder: (context, index) {
                              final cat = sheetCategories[index];
                              final color = widget.categoryColors[cat] ?? const Color(0xFF6366F1);
                              final bool isDefault = cat == sheetDefault;

                              return Container(
                                key: ValueKey('order_$cat'),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: appSubtleBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDefault ? Colors.amber.withOpacity(0.5) : appBorder,
                                    width: isDefault ? 1.4 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.4),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cat,
                                            style: GoogleFonts.inter(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: appText,
                                            ),
                                          ),
                                          if (isDefault) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              isKo ? '기본 카테고리 (작성 시 자동 선택)' : 'Default (Auto-selected)',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Default button
                                    InkWell(
                                      onTap: () {
                                        widget.onSetDefaultCategory(cat);
                                        sheetDefault = cat;
                                        setSheetState(() {});
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isDefault
                                              ? Colors.amber.withOpacity(0.18)
                                              : (isAppDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
                                              size: 16,
                                              color: isDefault ? Colors.amber : appTextTertiary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isDefault ? (isKo ? '기본' : 'Default') : (isKo ? '기본설정' : 'Set Default'),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: isDefault ? FontWeight.w700 : FontWeight.w500,
                                                color: isDefault ? Colors.amber : appTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Drag handle
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.drag_handle_rounded,
                                          size: 20,
                                          color: appTextTertiary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeAccent,
                            foregroundColor: themeAccent.computeLuminance() > 0.6 ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppStrings.of(context).commonDone,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBentoView(
    BuildContext context,
    List<TimestampEntry> currentEntries,
    AppTheme theme,
    Color themeAccent,
  ) {
    final isDark = theme.isDark;
    final isKo = AppStrings.of(context).isKo;
    if (widget.categories.isEmpty) {
      return Center(
        child: Text(
          isKo ? '카테고리가 없습니다.' : 'No categories.',
          style: GoogleFonts.inter(color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
        ),
      );
    }

    final heroCat = widget.categories.contains(widget.defaultCategory)
        ? widget.defaultCategory
        : widget.categories.first;
    final subCategories = widget.categories.where((c) => c != heroCat).toList();

    final heroEntries = currentEntries.where((e) => e.category == heroCat).toList();
    final heroCount = heroEntries.length;
    final heroTodoCount = heroEntries.where((e) => e.isPendingTodo).length;
    final heroDoneCount = heroEntries.where((e) => e.status == 'done').length;
    final heroTotal = heroTodoCount + heroDoneCount;
    final heroDoneRate = heroTotal > 0 ? (heroDoneCount / heroTotal) : 0.0;
    final heroColor = widget.categoryColors[heroCat] ?? themeAccent;
    final bool isHeroDefault = heroCat == widget.defaultCategory;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      children: [
        // 1. Hero Bento Card
        InkWell(
          onTap: () => _navigateToCategoryDetail(context, heroCat, heroColor),
          onLongPress: () => _showCategoryOptionsSheet(context, heroCat),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? null : theme.cardBg,
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        heroColor.withOpacity(0.22),
                        theme.cardBg,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? (isHeroDefault ? Colors.amber.withOpacity(0.55) : heroColor.withOpacity(0.35))
                    : (isHeroDefault ? const Color(0xFFF59E0B) : Colors.black.withOpacity(0.06)),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? heroColor.withOpacity(0.14) : Colors.black.withOpacity(0.04),
                  blurRadius: isDark ? 16 : 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: heroColor.withOpacity(isDark ? 0.25 : 0.16),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: heroColor.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Icon(_getCategoryIcon(heroCat), color: heroColor, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  heroCat,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17 * widget.uiScale,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                                    const SizedBox(width: 3),
                                    Text(
                                      isHeroDefault ? (isKo ? '기본' : 'Default') : (isKo ? '대표' : 'Primary'),
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5 * widget.uiScale,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isKo ? '총 $heroCount개 기록' : '$heroCount records',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              fontSize: 12.5 * widget.uiScale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showCategoryOptionsSheet(context, heroCat),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings_outlined,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                if (heroTotal > 0) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isKo ? 'TODO 진행률 ($heroDoneCount/$heroTotal 완료)' : 'Tasks Progress ($heroDoneCount/$heroTotal Done)',
                        style: GoogleFonts.inter(
                          fontSize: 11 * widget.uiScale,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${(heroDoneRate * 100).toInt()}%',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12 * widget.uiScale,
                          fontWeight: FontWeight.w800,
                          color: heroColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: heroDoneRate,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(heroColor),
                      minHeight: 5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 기본 카테고리 하단 배너 광고
        if (!kIsProVersion)
          const BannerAdWidget(
            margin: EdgeInsets.only(top: 14),
          ),

        // 2. Sub Bento Tiles Grid
        if (subCategories.isNotEmpty) ...[
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final cat = subCategories[index];
              final catEntries = currentEntries.where((e) => e.category == cat).toList();
              final count = catEntries.length;
              final todoCount = catEntries.where((e) => e.isPendingTodo).length;
              final doneCount = catEntries.where((e) => e.status == 'done').length;
              final totalTasks = todoCount + doneCount;
              final color = widget.categoryColors[cat] ?? Colors.grey;

              return InkWell(
                onTap: () => _navigateToCategoryDetail(context, cat, color),
                onLongPress: () => _showCategoryOptionsSheet(context, cat),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color.withOpacity(isDark ? 0.22 : 0.14),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Center(
                              child: Icon(_getCategoryIcon(cat), color: color, size: 18),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showCategoryOptionsSheet(context, cat),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.settings_outlined,
                                size: 17,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat,
                            style: GoogleFonts.inter(
                              fontSize: 14 * widget.uiScale,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                isKo ? '$count개' : '$count items',
                                style: GoogleFonts.inter(
                                  fontSize: 11 * widget.uiScale,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (todoCount > 0) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'TODO $todoCount',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9 * widget.uiScale,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (totalTasks > 0) ...[
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: doneCount / totalTasks,
                                backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 2.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance.currentTheme;
    final isAppDark = theme.isDark;
    final isKo = AppStrings.of(context).isKo;
    final themeAccent = (!isAppDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.of(context).navCategory,
                        style: GoogleFonts.inter(
                          fontSize: 18 * widget.uiScale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isAppDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isKo ? '주제별로 모아보는 나만의 순간들' : 'Your moments organized by topic',
                        style: GoogleFonts.inter(
                          color: isAppDark ? Colors.white.withOpacity(0.4) : const Color(0xFF64748B),
                          fontSize: 12.5 * widget.uiScale,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showReorderAndDefaultSheet(context),
                        tooltip: isKo ? '카테고리 순서 및 기본 설정' : 'Category order & default',
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        color: isAppDark ? Colors.white70 : const Color(0xFF475569),
                        style: IconButton.styleFrom(
                          backgroundColor: isAppDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          showAddCategoryModal(
                            context,
                            onAddCategory: widget.onAddCategory,
                          );
                        },
                        tooltip: AppStrings.of(context).categoryAddNew,
                        icon: const Icon(Icons.add_rounded, size: 22),
                        color: themeAccent.computeLuminance() > 0.6 ? Colors.black : Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: themeAccent,
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Categories Display (Bento Dashboard)
              Expanded(
                child: ValueListenableBuilder<List<TimestampEntry>>(
                  valueListenable: widget.entriesNotifier,
                  builder: (context, currentEntries, _) {
                    return _buildBentoView(context, currentEntries, theme, themeAccent);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryDetailView extends StatefulWidget {
  final String category;
  final ValueNotifier<List<TimestampEntry>> entriesNotifier;
  final Color categoryColor;
  final Function(String) onDelete;
  final Function(String) onToggle;
  final Function(String) onClearCategory;
  final Function(TimestampEntry)? onUpdateEntry;
  final List<String>? categories;
  final Map<String, Color>? categoryColors;
  final double uiScale;
  final Function(String, Color)? onUpdateCategoryColor;
  final bool Function(String, String)? onRenameCategory;

  const CategoryDetailView({
    super.key,
    required this.category,
    required this.entriesNotifier,
    required this.categoryColor,
    required this.onDelete,
    required this.onToggle,
    required this.onClearCategory,
    this.onUpdateEntry,
    this.categories,
    this.categoryColors,
    required this.uiScale,
    this.onUpdateCategoryColor,
    this.onRenameCategory,
  });

  @override
  State<CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends State<CategoryDetailView> {
  late Timer _timer;
  bool _showOnlyTodo = false;
  late String _currentCategory;
  bool _isAllExpanded = true; // 기본으로 펼쳐보기
  bool _isSelectionMode = false; // 선택 공유 모드
  Set<String> _selectedEntryIds = <String>{};

  Color get _effectiveColor =>
      widget.categoryColors?[_currentCategory] ?? widget.categoryColor;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _shareSelectedEntries(List<TimestampEntry> allEntries) async {
    final selectedEntries = allEntries
        .where((e) => _selectedEntryIds.contains(e.id))
        .toList();
    if (selectedEntries.isEmpty) return;

    // 날짜/시간 순서(오름차순) 정렬
    selectedEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final isKo = AppStrings.of(context).isKo;
    final sb = StringBuffer();
    sb.writeln('[$_currentCategory] ${isKo ? "기록 (총 ${selectedEntries.length}건)" : "Records (${selectedEntries.length} items)"}');
    sb.writeln();

    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    for (int i = 0; i < selectedEntries.length; i++) {
      final e = selectedEntries[i];
      final timeStr = dateFormat.format(e.timestamp);
      final isDone = e.status == 'done';
      final statusBadge = isDone
          ? (isKo ? '✅ [완료]' : '✅ [DONE]')
          : (e.isInProgress
              ? (isKo ? '🔥 [진행 중]' : '🔥 [IN PROGRESS]')
              : (e.isPaused
                  ? (isKo ? '⏸ [일시정지]' : '⏸ [PAUSED]')
                  : (e.isTodo
                      ? (isKo ? '⏳ [TODO]' : '⏳ [TODO]')
                      : (isKo ? '📌 [기록]' : '📌 [RECORD]'))));

      sb.writeln('${i + 1}. $statusBadge $timeStr');
      if (e.note.trim().isNotEmpty) {
        sb.writeln('   ${e.note.trim()}');
      }
      if (isDone && e.doneNote != null && e.doneNote!.trim().isNotEmpty) {
        sb.writeln('   • ${isKo ? "완료 메모" : "Completion Note"}: ${e.doneNote!.trim()}');
      }
      if (e.effectiveDurationSeconds > 0) {
        sb.writeln('   • ${isKo ? "소요 시간" : "Duration"}: ${formatSecondsKo(e.effectiveDurationSeconds)}');
      }
      if (e.targetDate != null) {
        sb.writeln('   • ${isKo ? "목표 기한" : "Due Date"}: ${dateFormat.format(e.targetDate!)}');
      }
      if (i < selectedEntries.length - 1) {
        sb.writeln();
      }
    }

    final shareText = sb.toString().trim();

    final List<XFile> imageFiles = [];
    for (final e in selectedEntries) {
      if (e.imagePath != null && e.imagePath!.isNotEmpty) {
        final f = File(e.imagePath!);
        if (f.existsSync()) {
          imageFiles.add(XFile(f.path));
        }
      }
      if (e.doneImagePath != null && e.doneImagePath!.isNotEmpty) {
        final f = File(e.doneImagePath!);
        if (f.existsSync()) {
          imageFiles.add(XFile(f.path));
        }
      }
    }

    try {
      if (imageFiles.isNotEmpty) {
        // 일부 메신저(메시지, 카카오톡 등)가 사진 첨부 시 텍스트를 누락시키는 플랫폼 제약 대비 클립보드 자동 복사
        await Clipboard.setData(ClipboardData(text: shareText));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isKo
                  ? '📋 글 내용이 클립보드에 복사되었습니다. (사진만 전송될 경우 붙여넣기 하세요)'
                  : '📋 Content copied to clipboard. (Paste if only photos were attached)'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        await Share.shareXFiles(
          imageFiles,
          text: shareText,
        );
      } else {
        await Share.share(shareText);
      }
    } catch (err) {
      debugPrint('Share error: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isKo ? '공유 중 오류가 발생했습니다: $err' : 'Error sharing: $err'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isKo = s.isKo;

    return ValueListenableBuilder<List<TimestampEntry>>(
      valueListenable: widget.entriesNotifier,
      builder: (context, currentEntries, _) {
        final categoryEntries = currentEntries
            .where((e) => e.category == _currentCategory)
            .toList();

        final filteredEntries = _showOnlyTodo
            ? categoryEntries.where((e) => e.isPendingTodo).toList()
            : categoryEntries;

        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return PopScope(
          canPop: !_isSelectionMode,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedEntryIds.clear();
              });
            }
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: _isSelectionMode
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, size: 22, color: appText),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedEntryIds.clear();
                        });
                      },
                      tooltip: isKo ? '선택 취소' : 'Cancel selection',
                    )
                  : IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, size: 20, color: appText),
                      onPressed: () => Navigator.pop(context),
                    ),
              title: Text(
                _isSelectionMode
                    ? (isKo ? '${_selectedEntryIds.length}개 선택됨' : '${_selectedEntryIds.length} selected')
                    : _currentCategory,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 18 * widget.uiScale,
                  color: appText,
                ),
              ),
              centerTitle: true,
              actions: _isSelectionMode
                  ? [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedEntryIds.length == filteredEntries.length) {
                              _selectedEntryIds.clear();
                            } else {
                              _selectedEntryIds = filteredEntries.map((e) => e.id).toSet();
                            }
                          });
                        },
                        child: Text(
                          _selectedEntryIds.length == filteredEntries.length
                              ? (isKo ? '전체 해제' : 'Deselect All')
                              : (isKo ? '전체 선택' : 'Select All'),
                          style: GoogleFonts.inter(
                            color: _effectiveColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ]
                  : [
                      IconButton(
                        onPressed: () => setState(() => _isAllExpanded = !_isAllExpanded),
                        icon: Icon(
                          _isAllExpanded
                              ? Icons.unfold_less_rounded
                              : Icons.unfold_more_rounded,
                          color: _effectiveColor,
                          size: 22,
                        ),
                        tooltip: _isAllExpanded
                            ? (isKo ? '전체 접기' : 'Collapse All')
                            : (isKo ? '전체 펼치기' : 'Expand All'),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showOnlyTodo = !_showOnlyTodo),
                        icon: Icon(
                          _showOnlyTodo
                              ? Icons.filter_list_rounded
                              : Icons.filter_list_off_rounded,
                          color: _showOnlyTodo
                              ? _effectiveColor
                              : appTextTertiary,
                          size: 20,
                        ),
                        tooltip: _showOnlyTodo
                            ? (isKo ? '전체 보기' : 'View All')
                            : (isKo ? 'TODO 모아보기' : 'View Tasks'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          onPressed: filteredEntries.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedEntryIds.clear();
                                  });
                                },
                          icon: Icon(
                            Icons.share_rounded,
                            color: filteredEntries.isEmpty
                                ? appTextTertiary.withOpacity(0.4)
                                : _effectiveColor,
                            size: 21,
                          ),
                          tooltip: isKo ? '기록 선택하여 공유' : 'Select to share',
                        ),
                      ),
                    ],
            ),
            bottomNavigationBar: _isSelectionMode
                ? Container(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
                    decoration: BoxDecoration(
                      color: appCardBg,
                      border: Border(top: BorderSide(color: appBorder)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isKo ? '${_selectedEntryIds.length}개 선택됨' : '${_selectedEntryIds.length} selected',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: appText,
                                ),
                              ),
                              Text(
                                _selectedEntryIds.isEmpty
                                    ? (isKo ? '공유할 기록을 체크하세요' : 'Select records to share')
                                    : (isKo ? '텍스트 및 첨부 사진 포함' : 'Includes text & photos'),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: appTextTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectedEntryIds.isEmpty
                              ? null
                              : () => _shareSelectedEntries(filteredEntries),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(
                            isKo ? '공유하기' : 'Share',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _effectiveColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: appSubtleBg,
                            disabledForegroundColor: appTextTertiary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: _selectedEntryIds.isEmpty ? 0 : 2,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            body: SafeArea(
              top: false,
              bottom: !_isSelectionMode,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 최상단 배너 광고 (스크롤 시 함께 자연스럽게 이동)
                  if (!kIsProVersion)
                    const SliverToBoxAdapter(
                      child: TopBannerAdWidget(
                        margin: EdgeInsets.fromLTRB(16, 4, 16, 8),
                      ),
                    ),

                  if (categoryEntries.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 48,
                              color: appTextTertiary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isKo ? '이 카테고리에 기록이 없습니다' : 'No records in this category',
                              style: GoogleFonts.inter(
                                color: appTextTertiary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (filteredEntries.isEmpty && _showOnlyTodo)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list_off_rounded,
                              size: 48,
                              color: appTextTertiary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isKo ? '이 카테고리에 진행 중인 TODO가 없습니다' : 'No pending tasks in this category',
                              style: GoogleFonts.inter(
                                color: appTextTertiary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 48 + bottomPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = filteredEntries[index];
                            final isSelected = _selectedEntryIds.contains(entry.id);

                            final itemWidget = TimestampListItem(
                              key: ValueKey('${entry.id}_$_isAllExpanded'),
                              entry: entry,
                              categoryColor: _effectiveColor,
                              onDelete: () => widget.onDelete(entry.id),
                              onStatusToggle: () => widget.onToggle(entry.id),
                              onUpdate: widget.onUpdateEntry,
                              categories: widget.categories,
                              getCategoryColor: (cat) =>
                                  widget.categoryColors?[cat] ??
                                  (cat == _currentCategory ? _effectiveColor : widget.categoryColor),
                              uiScale: widget.uiScale,
                              initialExpanded: _isAllExpanded,
                            );

                            if (_isSelectionMode) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedEntryIds.remove(entry.id);
                                      } else {
                                        _selectedEntryIds.add(entry.id);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? _effectiveColor
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? _effectiveColor.withOpacity(0.06)
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 10.0, right: 4.0),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? _effectiveColor
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected
                                                    ? _effectiveColor
                                                    : appTextTertiary.withOpacity(0.6),
                                                width: 2,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 15,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        Expanded(
                                          child: IgnorePointer(
                                            child: itemWidget,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            return itemWidget;
                          },
                          childCount: filteredEntries.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class InsightView extends StatefulWidget {
  final ValueNotifier<List<TimestampEntry>> entriesNotifier;
  final double uiScale;
  final Map<String, Color>? categoryColors;
  final Function(String)? onDelete;
  final Function(String)? onToggle;
  final Function(TimestampEntry)? onUpdate;
  final List<String>? categories;

  const InsightView({
    super.key, 
    required this.entriesNotifier,
    required this.uiScale,
    this.categoryColors,
    this.onDelete,
    this.onToggle,
    this.onUpdate,
    this.categories,
  });

  @override
  State<InsightView> createState() => _InsightViewState();
}

class _InsightCategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final AppTheme theme;

  _InsightCategoryFilterDelegate({
    required this.child,
    required this.height,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = theme.isDark;
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBg,
        border: shrinkOffset > 0
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                  width: 0.8,
                ),
              )
            : null,
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _InsightCategoryFilterDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.height != height ||
        oldDelegate.theme != theme;
  }
}

class _InsightViewState extends State<InsightView> {
  String _whereFilter = '전체';
  String _whereMetricType = 'count'; // 'count' (기록 건수 점유율, 기본값) or 'time' (소요 시간 점유율)
  final List<String> _whereFilters = ['전체', '일간', '주간', '월간', '연간'];
  DateTime _whereReferenceDate = DateTime.now();
  String _selectedGlobalCategory = 'All';
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedCalendarDay;
  DateTime _selectedWeekStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
      .subtract(Duration(days: DateTime.now().weekday - 1));
  DateTime _matrixMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  static const List<Map<String, dynamic>> kDefaultCards = [
    {
      'id': 'activity_calendar',
      'title': '활동 캘린더',
      'subtitle': '월별 기록 밀도 및 날짜별 상세 내역',
      'icon': Icons.calendar_month_rounded,
    },
    {
      'id': 'where_my_time_goes',
      'title': '카테고리별 시간 분석',
      'subtitle': '카테고리별 소요 시간 및 점유 비율',
      'icon': Icons.pie_chart_outline_rounded,
    },
    {
      'id': 'top_tasks',
      'title': '활동 시간 랭킹',
      'subtitle': '가장 많은 시간을 투자한 활동 랭킹',
      'icon': Icons.leaderboard_outlined,
    },
    {
      'id': 'activity_distribution_24h',
      'title': '24시간 활동 패턴',
      'subtitle': '시간대별(새벽/오전/오후/저녁) 활동 분포',
      'icon': Icons.schedule_rounded,
    },
    {
      'id': 'weekday_pattern',
      'title': '요일별 집중도',
      'subtitle': '월~일 활동 분포 및 주중/주말 패턴',
      'icon': Icons.calendar_view_week_rounded,
    },
    {
      'id': 'productivity_summary',
      'title': 'TODO 달성률',
      'subtitle': 'TODO 완료율 및 평균 소요 시간',
      'icon': Icons.task_alt_rounded,
    },
    {
      'id': 'weekly_timetable',
      'title': '주간 타임 테이블',
      'subtitle': '가로(요일) × 세로(시간대)별 활동 매트릭스',
      'icon': Icons.table_chart_rounded,
    },
    {
      'id': 'monthly_time_matrix',
      'title': '월간 타임 테이블',
      'subtitle': '세로(날짜 1~31일) × 가로(24시간) 활동 타임라인',
      'icon': Icons.calendar_view_month_rounded,
    },
  ];

  List<String> _cardOrder = [
    'activity_calendar',
    'where_my_time_goes',
    'top_tasks',
    'activity_distribution_24h',
    'weekday_pattern',
    'productivity_summary',
    'weekly_timetable',
    'monthly_time_matrix',
  ];

  Map<String, bool> _cardVisibility = {
    'activity_calendar': true,
    'where_my_time_goes': true,
    'top_tasks': true,
    'activity_distribution_24h': true,
    'weekday_pattern': true,
    'productivity_summary': true,
    'weekly_timetable': true,
    'monthly_time_matrix': true,
  };

  @override
  void initState() {
    super.initState();
    _loadCardSettings();
  }

  Future<void> _loadCardSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final int version = prefs.getInt('chronos_insight_card_order_version') ?? 1;
    if (version < 2) {
      // 새로운 기본 카드 순서(활동 캘린더 -> 카테고리별 분석 -> ...)로 마이그레이션
      await prefs.setInt('chronos_insight_card_order_version', 2);
      await prefs.remove('chronos_insight_card_order');
      if (mounted) {
        setState(() {
          _cardOrder = kDefaultCards.map((c) => c['id'] as String).toList();
        });
      }
      return;
    }

    final orderJson = prefs.getString('chronos_insight_card_order');
    final visJson = prefs.getString('chronos_insight_card_visibility');
    if (orderJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(orderJson);
        final List<String> loadedOrder = decoded.map((e) => e.toString()).toList();
        for (final card in kDefaultCards) {
          if (!loadedOrder.contains(card['id'])) {
            loadedOrder.add(card['id'] as String);
          }
        }
        if (mounted) {
          setState(() {
            _cardOrder = loadedOrder;
          });
        }
      } catch (_) {}
    }
    if (visJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(visJson);
        final Map<String, bool> loadedVis = decoded.map((k, v) => MapEntry(k, v as bool));
        for (final card in kDefaultCards) {
          final id = card['id'] as String;
          if (!loadedVis.containsKey(id)) {
            loadedVis[id] = true;
          }
        }
        if (mounted) {
          setState(() {
            _cardVisibility = loadedVis;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _saveCardSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chronos_insight_card_order_version', 2);
    await prefs.setString('chronos_insight_card_order', jsonEncode(_cardOrder));
    await prefs.setString('chronos_insight_card_visibility', jsonEncode(_cardVisibility));
  }

  String _getCardTitle(String id, BuildContext context) {
    final s = AppStrings.of(context);
    switch (id) {
      case 'activity_calendar':
        return s.insightCalendar;
      case 'where_my_time_goes':
        return s.insightTimeStats;
      case 'top_tasks':
        return s.insightRanking;
      case 'activity_distribution_24h':
        return s.insight24hPattern;
      case 'weekday_pattern':
        return s.insightWeeklyPattern;
      case 'productivity_summary':
        return s.insightTodoCompletion;
      case 'weekly_timetable':
        return s.insightWeeklyTable;
      case 'monthly_time_matrix':
        return s.insightMonthlyTable;
      default:
        return id;
    }
  }

  String _getCardSubtitle(String id, BuildContext context) {
    final s = AppStrings.of(context);
    switch (id) {
      case 'activity_calendar':
        return s.insightCalendarDesc;
      case 'where_my_time_goes':
        return s.insightTimeStatsDesc;
      case 'top_tasks':
        return s.insightRankingDesc;
      case 'activity_distribution_24h':
        return s.insight24hPatternDesc;
      case 'weekday_pattern':
        return s.insightWeeklyPatternDesc;
      case 'productivity_summary':
        return s.insightTodoCompletionDesc;
      case 'weekly_timetable':
        return s.insightWeeklyTableDesc;
      case 'monthly_time_matrix':
        return s.insightMonthlyTableDesc;
      default:
        return '';
    }
  }

  String _getFilterLabel(String filter, BuildContext context) {
    final s = AppStrings.of(context);
    switch (filter) {
      case '전체':
        return s.filterAll;
      case '일간':
        return s.filterDaily;
      case '주간':
        return s.filterWeekly;
      case '월간':
        return s.filterMonthly;
      case '연간':
        return s.filterYearly;
      default:
        return filter;
    }
  }

  void _showCardCustomizationSheet(BuildContext context) {
    final List<String> currentOrder = List<String>.from(_cardOrder);
    final Map<String, bool> currentVis = Map<String, bool>.from(_cardVisibility);
    final theme = ThemeController.instance.currentTheme;
    final themeAccent = (!theme.isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isKo = AppStrings.of(context).isKo;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: appCardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) {
                          if (details.primaryDelta! > 7) {
                            Navigator.pop(context);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isAppDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isKo ? '통계 카드 편집' : 'Edit Insight Cards',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: appText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isKo ? '카드를 켜거나 끄고, 드래그하여 순서를 변경하세요' : 'Toggle cards and drag to reorder',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: appTextTertiary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  currentOrder.clear();
                                  currentOrder.addAll(kDefaultCards.map((c) => c['id'] as String));
                                  for (final c in kDefaultCards) {
                                    currentVis[c['id'] as String] = true;
                                  }
                                  setSheetState(() {});
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AppStrings.of(context).resetPreset,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: themeAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded, size: 20),
                                color: appTextSecondary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            canvasColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: currentOrder.length,
                            onReorder: (oldIndex, newIndex) {
                              if (oldIndex < newIndex) newIndex -= 1;
                              final item = currentOrder.removeAt(oldIndex);
                              currentOrder.insert(newIndex, item);
                              setSheetState(() {});
                            },
                            itemBuilder: (context, index) {
                              final cardId = currentOrder[index];
                              final cardMeta = kDefaultCards.firstWhere(
                                (c) => c['id'] == cardId,
                                orElse: () => {
                                  'id': cardId,
                                  'title': cardId,
                                  'subtitle': '',
                                  'icon': Icons.insights_rounded,
                                },
                              );
                              final bool isVisible = currentVis[cardId] ?? true;

                              return Container(
                                key: ValueKey('card_$cardId'),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: appSubtleBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isVisible ? themeAccent.withOpacity(0.4) : appBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      cardMeta['icon'] as IconData,
                                      size: 20,
                                      color: isVisible ? themeAccent : appTextTertiary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getCardTitle(cardId, context),
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: isVisible ? appText : appTextTertiary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _getCardSubtitle(cardId, context),
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              color: appTextTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: isVisible,
                                      activeColor: themeAccent,
                                      onChanged: (val) {
                                        currentVis[cardId] = val;
                                        setSheetState(() {});
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.drag_handle_rounded,
                                          size: 20,
                                          color: appTextTertiary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _cardOrder = currentOrder;
                              _cardVisibility = currentVis;
                            });
                            _saveCardSettings();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            AppStrings.of(context).commonDone,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _previousWherePeriod() {
    setState(() {
      if (_whereFilter == '일간') {
        _whereReferenceDate = _whereReferenceDate.subtract(const Duration(days: 1));
      } else if (_whereFilter == '주간') {
        _whereReferenceDate = _whereReferenceDate.subtract(const Duration(days: 7));
      } else if (_whereFilter == '월간') {
        _whereReferenceDate = DateTime(
          _whereReferenceDate.year,
          _whereReferenceDate.month - 1,
          _whereReferenceDate.day,
        );
      } else if (_whereFilter == '연간') {
        _whereReferenceDate = DateTime(
          _whereReferenceDate.year - 1,
          _whereReferenceDate.month,
          _whereReferenceDate.day,
        );
      }
    });
  }

  void _nextWherePeriod() {
    setState(() {
      if (_whereFilter == '일간') {
        _whereReferenceDate = _whereReferenceDate.add(const Duration(days: 1));
      } else if (_whereFilter == '주간') {
        _whereReferenceDate = _whereReferenceDate.add(const Duration(days: 7));
      } else if (_whereFilter == '월간') {
        _whereReferenceDate = DateTime(
          _whereReferenceDate.year,
          _whereReferenceDate.month + 1,
          _whereReferenceDate.day,
        );
      } else if (_whereFilter == '연간') {
        _whereReferenceDate = DateTime(
          _whereReferenceDate.year + 1,
          _whereReferenceDate.month,
          _whereReferenceDate.day,
        );
      }
    });
  }

  void _previousCalendarMonth() {
    setState(() {
      _calendarMonth = DateTime(
        _calendarMonth.year,
        _calendarMonth.month - 1,
        1,
      );
      _selectedCalendarDay = null;
    });
  }

  void _nextCalendarMonth() {
    setState(() {
      _calendarMonth = DateTime(
        _calendarMonth.year,
        _calendarMonth.month + 1,
        1,
      );
      _selectedCalendarDay = null;
    });
  }

  void _showMonthPicker() {
    final theme = ThemeController.instance.currentTheme;
    final themeAccent = (!theme.isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;

    showDialog(
      context: context,
      builder: (context) {
        DateTime tempDate = _calendarMonth;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isKo = AppStrings.of(context).isKo;
            return AlertDialog(
              backgroundColor: appCardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: appBorder),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isKo ? '월 선택' : 'Select Month',
                    style: GoogleFonts.inter(
                      color: appText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  DropdownButton<int>(
                    value: tempDate.year,
                    dropdownColor: appCardBg,
                    style: GoogleFonts.jetBrainsMono(
                      color: appText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: appTextSecondary,
                    ),
                    underline: Container(),
                    items: List.generate(21, (i) => 2020 + i)
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (y) {
                      if (y != null) {
                        setDialogState(
                          () => tempDate = DateTime(y, tempDate.month),
                        );
                      }
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                height: 240,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected =
                        _calendarMonth.year == tempDate.year &&
                        _calendarMonth.month == month;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _calendarMonth = DateTime(tempDate.year, month, 1);
                          _selectedCalendarDay = null;
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeAccent
                              : appSubtleBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? themeAccent
                                : appBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isKo ? '$month월' : DateFormat('MMM').format(DateTime(2024, month)),
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? Colors.white
                                : appTextSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateKorean(DateTime date, {bool includeWeekday = false}) {
    final isKo = AppStrings.isCurrentLocaleKo;
    if (includeWeekday) {
      if (isKo) {
        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
        final w = weekdays[(date.weekday - 1).clamp(0, 6)];
        return '${date.year}년 ${date.month}월 ${date.day}일 ($w)';
      } else {
        return DateFormat('EEE, MMM d, yyyy').format(date);
      }
    }
    if (isKo) {
      return '${date.year}년 ${date.month}월';
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }

  String _getWherePeriodLabel() {
    final isKo = AppStrings.isCurrentLocaleKo;
    if (_whereFilter == '일간') {
      return _formatDateKorean(_whereReferenceDate, includeWeekday: true);
    } else if (_whereFilter == '주간') {
      final refDateOnly = DateTime(_whereReferenceDate.year, _whereReferenceDate.month, _whereReferenceDate.day);
      final startOfWeek = refDateOnly.subtract(Duration(days: _whereReferenceDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${startOfWeek.month}/${startOfWeek.day} ~ ${endOfWeek.month}/${endOfWeek.day}';
    } else if (_whereFilter == '월간') {
      return _formatDateKorean(_whereReferenceDate);
    } else if (_whereFilter == '연간') {
      return isKo ? '${_whereReferenceDate.year}년' : '${_whereReferenceDate.year}';
    }
    return isKo ? '전체 기간' : 'All Time';
  }

  List<TimestampEntry> _getWhereFilteredEntries(List<TimestampEntry> allEntries) {
    var entries = allEntries;
    if (_selectedGlobalCategory != 'All') {
      entries = entries.where((e) => e.category == _selectedGlobalCategory).toList();
    }

    if (_whereFilter == '전체') return entries;

    final ref = _whereReferenceDate;
    final refDateOnly = DateTime(ref.year, ref.month, ref.day);

    return entries.where((entry) {
      final entryDate = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      if (_whereFilter == '일간') {
        return entryDate == refDateOnly;
      } else if (_whereFilter == '주간') {
        // 월요일 00:00:00.000 정규화 (오늘 이전 기록도 주간 범위에 완벽 포함!)
        final startOfWeek = refDateOnly.subtract(Duration(days: ref.weekday - 1));
        // 다음 주 월요일 00:00:00.000 (일요일 23:59:59.999까지)
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return (entry.timestamp.isAfter(startOfWeek) || entry.timestamp.isAtSameMomentAs(startOfWeek)) &&
            entry.timestamp.isBefore(endOfWeek);
      } else if (_whereFilter == '월간') {
        return entry.timestamp.year == ref.year && entry.timestamp.month == ref.month;
      } else if (_whereFilter == '연간') {
        return entry.timestamp.year == ref.year;
      }
      return true;
    }).toList();
  }

  Widget _buildGlobalCategoryFilter(List<TimestampEntry> entries) {
    final categoryList = <String>['All'];
    if (widget.categoryColors != null) {
      categoryList.addAll(widget.categoryColors!.keys);
    }
    for (final e in entries) {
      if (!categoryList.contains(e.category)) {
        categoryList.add(e.category);
      }
    }

    final theme = ThemeController.instance.currentTheme;
    final themeAccent = (!theme.isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: categoryList.map((cat) {
          final isSelected = _selectedGlobalCategory == cat;
          final color = cat == 'All' ? themeAccent : _getCategoryColor(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedGlobalCategory = cat;
                  _selectedCalendarDay = null;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(isAppDark ? 0.22 : 0.15)
                      : (isAppDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : appBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat == 'All' ? (AppStrings.of(context).isKo ? '전체' : 'All') : cat,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? (isAppDark ? Colors.white : color) : (isAppDark ? Colors.white.withOpacity(0.6) : const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final isKo = AppStrings.isCurrentLocaleKo;
    if (minutes <= 0) return isKo ? '0분' : '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return isKo ? '${h}시간 ${m}분' : '${h}h ${m}m';
    if (h > 0) return isKo ? '${h}시간' : '${h}h';
    return isKo ? '${m}분' : '${m}m';
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    Widget? selector,
    Widget? content,
    Widget? child,
    IconData? icon,
    Widget? headerTrailing,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    final effectiveContent = content ?? child ?? const SizedBox.shrink();
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 20),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: appBorder),
        boxShadow: [
          BoxShadow(
            color: isAppDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: isAppDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: appText,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (headerTrailing != null) headerTrailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: appTextTertiary,
                fontSize: 12,
              ),
            ),
          ],
          if (selector != null) ...[
            const SizedBox(height: 16),
            selector,
          ],
          const SizedBox(height: 18),
          effectiveContent,
        ],
      ),
    );
  }

  Widget _buildWhereMyTimeGoesCard(
    List<TimestampEntry> filteredEntries,
    int totalCount,
    Map<String, Map<String, dynamic>> categoryStats,
  ) {
    final isKo = AppStrings.of(context).isKo;
    int totalTimeMinutes = 0;
    if (categoryStats.isNotEmpty) {
      totalTimeMinutes = categoryStats.values.first['totalDurationMinutes'] as int? ?? 0;
    }
    final theme = ThemeController.instance.currentTheme;
    final themeAccent = (!theme.isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;
    final accentColor = _selectedGlobalCategory == 'All'
        ? themeAccent
        : _getCategoryColor(_selectedGlobalCategory);
    final effectiveMetricType = _whereMetricType;

    return _buildSectionCard(
      title: AppStrings.of(context).insightTimeStats,
      subtitle: AppStrings.of(context).insightTimeStatsDesc,
      icon: Icons.pie_chart_outline_rounded,
      selector: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _whereFilters.map((filter) {
                final isSelected = _whereFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(_getFilterLabel(filter, context)),
                    selected: isSelected,
                    selectedColor: accentColor,
                    backgroundColor: appSubtleBg,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected
                          ? (accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                          : appTextSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _whereFilter = filter);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? accentColor : appBorder,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_whereFilter != '전체') ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousWherePeriod,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: appTextSecondary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: appSubtleBg,
                  ),
                ),
                Flexible(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDeadlineDatePicker(
                        context: context,
                        initialDate: _whereReferenceDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        title: isKo ? '기준 날짜 선택' : 'Select Reference Date',
                        canClear: false,
                      );
                      if (picked != null) setState(() => _whereReferenceDate = picked);
                    },
                    child: Text(
                      _getWherePeriodLabel(),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: appText,
                        decoration: TextDecoration.underline,
                        decorationColor: isAppDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextWherePeriod,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: appTextSecondary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: appSubtleBg,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo
                ? (totalTimeMinutes > 0
                    ? '총 ${_formatMinutes(totalTimeMinutes)} 소요 • $totalCount건의 기록'
                    : '총 $totalCount건의 기록')
                : (totalTimeMinutes > 0
                    ? 'Total ${_formatMinutes(totalTimeMinutes)} • $totalCount records'
                    : 'Total $totalCount records'),
            style: GoogleFonts.inter(
              color: appTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (categoryStats.isNotEmpty) ...[
            const SizedBox(height: 16),
            // 점유율 기준 전환 토글 (소요 시간 vs 기록 건수)
            Container(
              decoration: BoxDecoration(
                color: appSubtleBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: appBorder),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (_whereMetricType != 'count') {
                          setState(() => _whereMetricType = 'count');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: effectiveMetricType == 'count'
                              ? accentColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 14,
                              color: effectiveMetricType == 'count'
                                  ? (accentColor.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white)
                                  : appTextSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isKo ? '기록 건수 점유율' : 'Count Share',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: effectiveMetricType == 'count'
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: effectiveMetricType == 'count'
                                    ? (accentColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white)
                                    : appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (_whereMetricType != 'time') {
                          setState(() => _whereMetricType = 'time');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: effectiveMetricType == 'time'
                              ? accentColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: effectiveMetricType == 'time'
                                  ? (accentColor.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white)
                                  : appTextSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isKo ? '소요 시간 점유율' : 'Duration Share',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: effectiveMetricType == 'time'
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: effectiveMetricType == 'time'
                                    ? (accentColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white)
                                    : appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (effectiveMetricType == 'time' && totalTimeMinutes == 0) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: appSubtleBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: appBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      size: 34,
                      color: appTextTertiary.withOpacity(0.6),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.of(context).noTimeRecorded,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: appText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      AppStrings.of(context).noTimeRecordedDesc,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: appTextSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    effectiveMetricType == 'time'
                        ? (AppStrings.of(context).isKo ? '카테고리별 시간 점유율' : 'Duration Share by Category')
                        : (AppStrings.of(context).isKo ? '카테고리별 건수 점유율' : 'Count Share by Category'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: appTextTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  effectiveMetricType == 'time'
                      ? (AppStrings.of(context).isKo ? '총 ${_formatMinutes(totalTimeMinutes)} 기준' : 'Total ${_formatMinutes(totalTimeMinutes)}')
                      : (AppStrings.of(context).isKo ? '총 $totalCount건 기준' : 'Total $totalCount items'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: appTextTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: appSubtleBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: appBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Builder(
                builder: (context) {
                  final activeStatsForBar = categoryStats.entries
                      .where((s) => (s.value['percentage'] as num).toDouble() > 0.0001)
                      .toList();
                  if (activeStatsForBar.isEmpty) {
                    return Container(color: appSubtleBg);
                  }
                  return Row(
                    children: activeStatsForBar.map((stat) {
                      final double pct = (stat.value['percentage'] as num).toDouble();
                      final catColor = _getCategoryColor(stat.key);
                      return Expanded(
                        flex: (pct * 1000).round().clamp(1, 1000),
                        child: Container(color: catColor),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ...categoryStats.entries.map((stat) {
              final catColor = _getCategoryColor(stat.key);
              return _buildStatRow(
                stat.key,
                stat.value,
                totalCount,
                color: catColor,
              );
            }),
          ],
        ] else ...[
            const SizedBox(height: 24),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  isKo ? '선택한 기간에 기록된 데이터가 없습니다.' : 'No data recorded for the selected period.',
                  style: GoogleFonts.inter(color: appTextTertiary, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _build24HourDistributionCard(List<TimestampEntry> entries) {
    if (entries.isEmpty) {
      return _buildSectionCard(
        title: AppStrings.of(context).insight24hPattern,
        subtitle: AppStrings.of(context).insight24hPatternDesc,
        icon: Icons.schedule_rounded,
        content: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              AppStrings.of(context).isKo ? '기록된 데이터가 없습니다.' : 'No data recorded yet.',
              style: GoogleFonts.inter(color: appTextTertiary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    final hourCounts = List.filled(24, 0);
    for (final e in entries) {
      final hour = e.timestamp.hour.clamp(0, 23);
      hourCounts[hour]++;
    }

    int maxHourCount = 0;
    int peakHour = 0;
    for (int i = 0; i < 24; i++) {
      if (hourCounts[i] > maxHourCount) {
        maxHourCount = hourCounts[i];
        peakHour = i;
      }
    }

    int nightCount = 0;
    int morningCount = 0;
    int afternoonCount = 0;
    int eveningCount = 0;
    for (int i = 0; i < 6; i++) nightCount += hourCounts[i];
    for (int i = 6; i < 12; i++) morningCount += hourCounts[i];
    for (int i = 12; i < 18; i++) afternoonCount += hourCounts[i];
    for (int i = 18; i < 24; i++) eveningCount += hourCounts[i];

    final isKo = AppStrings.of(context).isKo;
    final total = entries.length;
    final theme = ThemeController.instance.currentTheme;
    final themeAccent = (!theme.isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;
    final chartColor = _selectedGlobalCategory == 'All'
        ? themeAccent
        : _getCategoryColor(_selectedGlobalCategory);

    return _buildSectionCard(
      title: AppStrings.of(context).insight24hPattern,
      subtitle: AppStrings.of(context).insight24hPatternDesc,
      icon: Icons.schedule_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: chartColor.withOpacity(isAppDark ? 0.12 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: chartColor.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    maxHourCount > 0
                        ? (isKo
                            ? '피크 타임: ${peakHour.toString().padLeft(2, '0')}:00 ~ ${(peakHour + 1).toString().padLeft(2, '0')}:00 ($maxHourCount건 기록)'
                            : 'Peak Time: ${peakHour.toString().padLeft(2, '0')}:00 ~ ${(peakHour + 1).toString().padLeft(2, '0')}:00 ($maxHourCount records)')
                        : (isKo ? '기록된 활동 없음' : 'No activity recorded'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: appText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSegmentPill(isKo ? '🌙 새벽' : '🌙 Night', isKo ? '00-06시' : '00-06h', nightCount, total, const Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              _buildSegmentPill(isKo ? '🌅 오전' : '🌅 Morning', isKo ? '06-12시' : '06-12h', morningCount, total, const Color(0xFF06B6D4)),
              const SizedBox(width: 8),
              _buildSegmentPill(isKo ? '☀️ 오후' : '☀️ Afternoon', isKo ? '12-18시' : '12-18h', afternoonCount, total, const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _buildSegmentPill(isKo ? '🌆 저녁' : '🌆 Evening', isKo ? '18-24시' : '18-24h', eveningCount, total, const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            isKo ? '24시간 타임라인 (00:00 ~ 23:00)' : '24-Hour Timeline (00:00 ~ 23:00)',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: appTextTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 114,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: appSubtleBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (h) {
                final count = hourCounts[h];
                final double factor = maxHourCount > 0 ? (count / maxHourCount) : 0.0;
                final bool isPeak = count == maxHourCount && count > 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 14,
                          child: Center(
                            child: count > 0
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$count',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 7.5,
                                        color: isPeak ? chartColor : appTextSecondary,
                                        fontWeight: isPeak ? FontWeight.w800 : FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: (factor * 50).clamp(4.0, 50.0),
                          decoration: BoxDecoration(
                            color: count == 0
                                ? (isAppDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
                                : (isPeak
                                    ? chartColor
                                    : chartColor.withOpacity(0.4 + 0.5 * factor)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 14,
                          child: Center(
                            child: Text(
                              h % 6 == 0 ? '$h' : '·',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8,
                                color: appTextTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentPill(String title, String timeRange, int count, int total, Color accentColor) {
    final pct = total > 0 ? ((count / total) * 100).toInt() : 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
        decoration: BoxDecoration(
          color: appSubtleBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: appText,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                timeRange,
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  color: appTextTertiary,
                ),
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppStrings.isCurrentLocaleKo ? '$count건' : '$count',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$pct%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: appTextTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayPatternCard(List<TimestampEntry> entries) {
    if (entries.isEmpty) {
      return _buildSectionCard(
        title: AppStrings.of(context).insightWeeklyPattern,
        subtitle: AppStrings.of(context).insightWeeklyPatternDesc,
        icon: Icons.calendar_view_week_rounded,
        content: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              AppStrings.of(context).isKo ? '기록된 데이터가 없습니다.' : 'No data recorded yet.',
              style: GoogleFonts.inter(color: appTextTertiary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    final dayCounts = List.filled(7, 0);
    final dayMinutes = List.filled(7, 0);
    final isKo = AppStrings.of(context).isKo;
    final dayNames = isKo ? ['월', '화', '수', '목', '금', '토', '일'] : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    for (final e in entries) {
      final dIndex = (e.timestamp.weekday - 1).clamp(0, 6);
      dayCounts[dIndex]++;
      int dur = e.effectiveDurationMinutes;
      dayMinutes[dIndex] += dur;
    }

    int maxDayCount = 0;
    int bestDay = 0;
    for (int i = 0; i < 7; i++) {
      if (dayCounts[i] > maxDayCount) {
        maxDayCount = dayCounts[i];
        bestDay = i;
      }
    }

    int weekdayCount = 0;
    int weekendCount = 0;
    for (int i = 0; i < 5; i++) weekdayCount += dayCounts[i];
    for (int i = 5; i < 7; i++) weekendCount += dayCounts[i];
    final total = entries.length;
    final weekdayPct = total > 0 ? ((weekdayCount / total) * 100).toInt() : 0;
    final weekendPct = total > 0 ? ((weekendCount / total) * 100).toInt() : 0;
    final theme = ThemeController.instance.currentTheme;
    final themeAccent = (!theme.isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;
    final chartColor = _selectedGlobalCategory == 'All'
        ? const Color(0xFF10B981)
        : _getCategoryColor(_selectedGlobalCategory);

    return _buildSectionCard(
      title: AppStrings.of(context).insightWeeklyPattern,
      subtitle: AppStrings.of(context).insightWeeklyPatternDesc,
      icon: Icons.calendar_view_week_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: chartColor.withOpacity(isAppDark ? 0.12 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: chartColor.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 16, color: chartColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    maxDayCount > 0
                        ? (isKo
                            ? '가장 집중한 요일: ${dayNames[bestDay]}요일 (${dayCounts[bestDay]}건 / ${_formatMinutes(dayMinutes[bestDay])})'
                            : 'Most Focused: ${dayNames[bestDay]} (${dayCounts[bestDay]} records / ${_formatMinutes(dayMinutes[bestDay])})')
                        : (isKo ? '기록된 활동 없음' : 'No activity recorded'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: appText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final count = dayCounts[i];
              final factor = maxDayCount > 0 ? (count / maxDayCount) : 0.0;
              final isBest = i == bestDay && count > 0;
              final isWeekend = i >= 5;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$count',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: isBest ? FontWeight.w800 : FontWeight.w600,
                          color: isBest ? chartColor : appTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: (factor * 70).clamp(6.0, 70.0),
                        decoration: BoxDecoration(
                          color: isBest
                              ? chartColor
                              : (count == 0
                                  ? (isAppDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))
                                  : (isWeekend
                                      ? const Color(0xFFF59E0B).withOpacity(0.4 + 0.5 * factor)
                                      : chartColor.withOpacity(0.4 + 0.5 * factor))),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayNames[i],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isBest ? FontWeight.w800 : FontWeight.w600,
                          color: isBest
                              ? chartColor
                              : (isWeekend ? const Color(0xFFF59E0B) : appTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appSubtleBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: appBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isKo
                            ? '주중 (월~금) $weekdayCount건 ($weekdayPct%)'
                            : 'Weekdays (M-F) $weekdayCount ($weekdayPct%)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: themeAccent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isKo
                            ? '주말 (토~일) $weekendCount건 ($weekendPct%)'
                            : 'Weekends (S-S) $weekendCount ($weekendPct%)',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF59E0B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: weekdayCount > 0 ? weekdayCount : 1,
                        child: Container(height: 6, color: themeAccent),
                      ),
                      Expanded(
                        flex: weekendCount > 0 ? weekendCount : 1,
                        child: Container(height: 6, color: const Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivitySummaryCard(List<TimestampEntry> entries) {
    final theme = ThemeController.instance.currentTheme;
    final themeAccent = (!theme.isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;
    final chartColor = _selectedGlobalCategory == 'All'
        ? const Color(0xFF10B981)
        : _getCategoryColor(_selectedGlobalCategory);
    final todos = entries.where((e) => e.isAnyTodo).toList();
    final dones = entries.where((e) => e.status == 'done').toList();
    final pending = entries.where((e) => e.isPendingTodo).toList();

    int totalDoneMinutes = 0;
    int doneCountWithTime = 0;
    for (final d in dones) {
      int dur = d.effectiveDurationMinutes;
      if (dur > 0) {
        totalDoneMinutes += dur;
        doneCountWithTime++;
      }
    }
    final avgDoneMinutes = doneCountWithTime > 0 ? (totalDoneMinutes ~/ doneCountWithTime) : 0;
    final int completionRate = todos.isNotEmpty ? ((dones.length / todos.length) * 100).toInt() : 0;

    final s = AppStrings.of(context);
    final isKo = s.isKo;
    String insightMsg;
    if (todos.isEmpty) {
      insightMsg = isKo ? '아직 등록된 TODO가 없습니다. TODO를 기록해보세요!' : 'No tasks registered yet. Add a task to get started!';
    } else if (completionRate >= 80) {
      insightMsg = isKo ? '대단해요! 대부분의 목표를 완벽하게 완수하고 있습니다 🎉' : 'Awesome! You are completing most of your goals 🎉';
    } else if (completionRate >= 50) {
      insightMsg = isKo ? '절반 이상의 목표를 달성하며 꾸준히 나아가고 있습니다 👍' : 'Great progress! More than half completed 👍';
    } else {
      insightMsg = isKo ? '차근차근 하나씩 완료해 나가며 달성률을 높여보세요 💪' : 'Keep going step by step to improve your completion rate 💪';
    }

    return _buildSectionCard(
      title: s.insightTodoCompletion,
      subtitle: s.insightTodoCompletionDesc,
      icon: Icons.task_alt_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: appSubtleBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.insightTodoCompletion,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: appTextSecondary,
                      ),
                    ),
                    Text(
                      '$completionRate%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: chartColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: completionRate / 100.0,
                    minHeight: 8,
                    backgroundColor: isAppDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(chartColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insightMsg,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMetricTile(s.metricCompletedTasks, isKo ? '${dones.length}건' : '${dones.length}', Icons.check_circle_outline_rounded, const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _buildMetricTile(s.metricPendingTasks, isKo ? '${pending.length}건' : '${pending.length}', Icons.pending_actions_rounded, const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetricTile(s.metricTotalTasks, isKo ? '${todos.length}건' : '${todos.length}', Icons.format_list_bulleted_rounded, themeAccent),
              const SizedBox(width: 8),
              _buildMetricTile(s.metricAvgDuration, avgDoneMinutes > 0 ? _formatMinutes(avgDoneMinutes) : '-', Icons.timer_outlined, const Color(0xFF06B6D4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: appSubtleBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: appTextTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: appText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTasksCard(List<TimestampEntry> entries) {
    final List<Map<String, dynamic>> tasksWithTime = [];

    for (final e in entries) {
      int dur = e.effectiveDurationMinutes;
      if (dur > 0) {
        tasksWithTime.add({
          'entry': e,
          'duration': dur,
        });
      }
    }

    tasksWithTime.sort((a, b) => (b['duration'] as int).compareTo(a['duration'] as int));
    final topTasks = tasksWithTime.take(5).toList();
    final theme = ThemeController.instance.currentTheme;
    final themeAccent = (!theme.isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;

    return _buildSectionCard(
      title: AppStrings.of(context).insightRanking,
      subtitle: AppStrings.of(context).insightRankingDesc,
      icon: Icons.leaderboard_outlined,
      content: topTasks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  AppStrings.of(context).noTasksForStats,
                  style: GoogleFonts.inter(color: appTextTertiary, fontSize: 13),
                ),
              ),
            )
          : Column(
              children: List.generate(topTasks.length, (index) {
                final item = topTasks[index];
                final entry = item['entry'] as TimestampEntry;
                final dur = item['duration'] as int;
                final catColor = _getCategoryColor(entry.category);

                String rankBadge;
                Color rankColor;
                if (index == 0) {
                  rankBadge = '🥇';
                  rankColor = Colors.amber;
                } else if (index == 1) {
                  rankBadge = '🥈';
                  rankColor = const Color(0xFFCBD5E1);
                } else if (index == 2) {
                  rankBadge = '🥉';
                  rankColor = const Color(0xFFD97706);
                } else {
                  rankBadge = '#${index + 1}';
                  rankColor = appTextSecondary;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: appSubtleBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: index == 0 ? Colors.amber.withOpacity(0.3) : appBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text(
                          rankBadge,
                          style: GoogleFonts.inter(
                            fontSize: index < 3 ? 14 : 11,
                            fontWeight: FontWeight.w800,
                            color: rankColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.note.isEmpty
                                  ? (AppStrings.of(context).isKo ? '기록된 작업' : 'Recorded task')
                                  : entry.note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: appText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      entry.category,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: catColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('MM.dd').format(entry.timestamp),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    color: appTextTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: themeAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _formatMinutes(dur),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: themeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Future<void> _showDayEntriesBottomSheet(
    BuildContext context, {
    required DateTime date,
    required bool Function(TimestampEntry) entryFilter,
    String? title,
    String? subtitle,
  }) {
    final isKo = AppStrings.of(context).isKo;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final w = weekdays[(date.weekday - 1).clamp(0, 6)];
    final theme = ThemeController.instance.currentTheme;
    final isAppDark = theme.isDark;
    final appCardBg = theme.cardBg;
    final appText = theme.textColor;
    final appTextSecondary = isAppDark ? Colors.white60 : const Color(0xFF64748B);
    final appTextTertiary = isAppDark ? Colors.white38 : const Color(0xFF94A3B8);
    final appBorder = isAppDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(sheetContext).viewPadding.bottom;
        final effectiveBottom =
            bottomInset > 0 ? bottomInset + 10 : (bottomPadding > 0 ? bottomPadding + 10 : 20.0);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: appCardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: appBorder),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: ValueListenableBuilder<List<TimestampEntry>>(
              valueListenable: widget.entriesNotifier,
              builder: (context, allEntries, _) {
                final matchedEntries = allEntries.where(entryFilter).toList()
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Drag Handle (iOS style with drag down to close)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta! > 7) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isAppDark
                                  ? Colors.white.withOpacity(0.18)
                                  : Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Header Row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title ?? (isKo ? '${date.year}년 ${date.month}월 ${date.day}일 ($w)' : DateFormat('EEE, MMM d, yyyy').format(date)),
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: appText,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle ??
                                      (matchedEntries.isEmpty
                                          ? (isKo ? '기록된 활동이 없습니다' : 'No activity recorded')
                                          : (isKo ? '총 ${matchedEntries.length}건의 기록' : '${matchedEntries.length} records in total')),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: appTextTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(sheetContext),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isAppDark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: appTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: appBorder),

                    // Entries List - Dynamic compact height for 0 or few items, scrollable when many
                    Flexible(
                      child: matchedEntries.isEmpty
                          ? Padding(
                              padding: EdgeInsets.fromLTRB(20, 36, 20, effectiveBottom + 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty_rounded,
                                      size: 38,
                                      color: appTextTertiary.withOpacity(0.4),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      isKo ? '기록된 활동이 없습니다' : 'No activity recorded',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        color: appTextTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(16, 14, 16, effectiveBottom + 20),
                              itemCount: matchedEntries.length,
                              itemBuilder: (context, index) {
                                final entry = matchedEntries[index];
                                final catColor = _getCategoryColor(entry.category);
                                return TimestampListItem(
                                  entry: entry,
                                  categoryColor: catColor,
                                  onDelete: () => widget.onDelete?.call(entry.id),
                                  onStatusToggle: () => widget.onToggle?.call(entry.id),
                                  onUpdate: widget.onUpdate,
                                  categories: widget.categories,
                                  getCategoryColor: _getCategoryColor,
                                  uiScale: widget.uiScale,
                                  initialExpanded: true,
                                  readOnly: true,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showTimetableSlotDetailsSheet(
    BuildContext context,
    DateTime date,
    int hour,
    List<TimestampEntry> entries,
  ) {
    final isKo = AppStrings.of(context).isKo;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final w = weekdays[(date.weekday - 1).clamp(0, 6)];
    final currHour = hour.toString().padLeft(2, '0');
    final nextHour = (hour + 1).toString().padLeft(2, '0');
    _showDayEntriesBottomSheet(
      context,
      date: date,
      entryFilter: (e) {
        if (_selectedGlobalCategory != 'All' && e.category != _selectedGlobalCategory) return false;
        return e.timestamp.year == date.year &&
            e.timestamp.month == date.month &&
            e.timestamp.day == date.day &&
            e.timestamp.hour == hour;
      },
      title: isKo
          ? '${date.month}월 ${date.day}일 ($w) $currHour:00 ~ $nextHour:00'
          : '${DateFormat("MMM d, EEE").format(date)} $currHour:00 ~ $nextHour:00',
    );
  }

  void _showMatrixDayDetailsSheet(
    BuildContext context,
    DateTime date,
    List<TimestampEntry> entries,
  ) {
    final isKo = AppStrings.of(context).isKo;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final w = weekdays[(date.weekday - 1).clamp(0, 6)];
    _showDayEntriesBottomSheet(
      context,
      date: date,
      entryFilter: (e) {
        if (_selectedGlobalCategory != 'All' && e.category != _selectedGlobalCategory) return false;
        return e.timestamp.year == date.year &&
            e.timestamp.month == date.month &&
            e.timestamp.day == date.day;
      },
      title: isKo
          ? '${date.year}년 ${date.month}월 ${date.day}일 ($w)'
          : DateFormat('EEE, MMM d, yyyy').format(date),
    );
  }

  Widget _buildMonthlyTimeMatrixCard(List<TimestampEntry> allEntries) {
    final now = DateTime.now();
    final selectedMonth = _matrixMonth;
    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final endOfMonth = DateTime(selectedMonth.year, selectedMonth.month, daysInMonth, 23, 59, 59);
    final bool isCurrentMonth = now.year == selectedMonth.year && now.month == selectedMonth.month;

    final monthEntries = allEntries.where((e) {
      if (_selectedGlobalCategory != 'All' && e.category != _selectedGlobalCategory) return false;
      return (e.timestamp.isAfter(startOfMonth.subtract(const Duration(milliseconds: 1))) &&
              e.timestamp.isBefore(endOfMonth.add(const Duration(milliseconds: 1))));
    }).toList();

    final Map<int, List<TimestampEntry>> dayEntriesMap = {};
    final Set<String> categoriesInMonth = {};
    for (final e in monthEntries) {
      final day = e.timestamp.day;
      dayEntriesMap.putIfAbsent(day, () => []).add(e);
      categoriesInMonth.add(e.category);
    }

    final theme = ThemeController.instance.currentTheme;
    final isDark = theme.isDark;
    final themeAccent = (!isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;

    final isKo = AppStrings.of(context).isKo;
    final weekdayLabels = isKo ? ['월', '화', '수', '목', '금', '토', '일'] : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return _buildSectionCard(
      title: AppStrings.of(context).insightMonthlyTable,
      subtitle: isKo
          ? '세로(날짜 1~${daysInMonth}일) × 가로(24시간) 활동 타임라인'
          : 'Days (1~$daysInMonth) × 24h activity timeline',
      icon: Icons.calendar_view_month_rounded,
      selector: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _matrixMonth = DateTime(_matrixMonth.year, _matrixMonth.month - 1, 1);
              });
            },
            icon: Icon(Icons.chevron_left_rounded, color: appTextSecondary),
            style: IconButton.styleFrom(
              backgroundColor: appSubtleBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _matrixMonth = DateTime(now.year, now.month, 1);
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isKo
                          ? '${selectedMonth.year}년 ${selectedMonth.month}월'
                          : DateFormat('MMMM yyyy').format(selectedMonth),
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: appText,
                      ),
                    ),
                    if (!isCurrentMonth) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeAccent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isKo ? '이번 달로' : 'This Month',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: themeAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isKo
                      ? '총 ${monthEntries.length}건 기록 • ${daysInMonth}일 중 ${dayEntriesMap.keys.length}일 활동'
                      : '${monthEntries.length} records • Active ${dayEntriesMap.keys.length}/$daysInMonth days',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: appTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _matrixMonth = DateTime(_matrixMonth.year, _matrixMonth.month + 1, 1);
              });
            },
            icon: Icon(Icons.chevron_right_rounded, color: appTextSecondary),
            style: IconButton.styleFrom(
              backgroundColor: appSubtleBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 가로 시간축 눈금 헤더 (0시, 6시, 12시, 18시, 24시)
          Container(
            padding: const EdgeInsets.fromLTRB(54, 8, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isKo ? '00시' : '00h', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: appTextTertiary)),
                Text(isKo ? '06시' : '06h', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: appTextTertiary)),
                Text(isKo ? '12시' : '12h', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: appTextTertiary)),
                Text(isKo ? '18시' : '18h', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: appTextTertiary)),
                Text(isKo ? '24시' : '24h', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: appTextTertiary)),
              ],
            ),
          ),

          // 세로 스크롤 날짜별 가로 타임 트랙 리스트
          Container(
            height: 380,
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  itemCount: daysInMonth,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final dayDate = DateTime(selectedMonth.year, selectedMonth.month, day);
                    final isToday = now.year == dayDate.year && now.month == dayDate.month && now.day == day;
                    final weekday = dayDate.weekday; // 1~7 (월~일)
                    final weekdayLabel = weekdayLabels[weekday - 1];
                    final isSat = weekday == 6;
                    final isSun = weekday == 7;
                    final dayEntries = dayEntriesMap[day] ?? [];

                    Color dateColor = appText;
                    if (isToday) {
                      dateColor = themeAccent;
                    } else if (isSun) {
                      dateColor = const Color(0xFFF43F5E);
                    } else if (isSat) {
                      dateColor = const Color(0xFF38BDF8);
                    } else if (dayEntries.isEmpty) {
                      dateColor = appTextTertiary;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: InkWell(
                        onTap: () => _showMatrixDayDetailsSheet(context, dayDate, dayEntries),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isToday
                                ? themeAccent.withOpacity(isDark ? 0.12 : 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: themeAccent.withOpacity(0.4), width: 1.0)
                                : null,
                          ),
                          child: Row(
                            children: [
                              // 날짜 라벨 (일 + 요일)
                              SizedBox(
                                width: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      day.toString().padLeft(2, '0'),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11.5,
                                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                        color: dateColor,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      weekdayLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                        color: dateColor.withOpacity(0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),

                              // 우측 24시간 가로 타임 트랙
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final trackWidth = constraints.maxWidth;
                                    return Container(
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.04)
                                            : Colors.black.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // 6시, 12시, 18시 은은한 가이드라인
                                          Positioned(
                                            left: trackWidth * 0.25,
                                            top: 0,
                                            bottom: 0,
                                            width: 1,
                                            child: Container(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                                          ),
                                          Positioned(
                                            left: trackWidth * 0.50,
                                            top: 0,
                                            bottom: 0,
                                            width: 1,
                                            child: Container(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07)),
                                          ),
                                          Positioned(
                                            left: trackWidth * 0.75,
                                            top: 0,
                                            bottom: 0,
                                            width: 1,
                                            child: Container(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                                          ),

                                          // 기록 블록들
                                          ...dayEntries.map((e) {
                                            final catColor = _getCategoryColor(e.category);
                                            final startFraction = (e.timestamp.hour + (e.timestamp.minute / 60.0)) / 24.0;
                                            final durationMins = e.effectiveDurationMinutes;
                                            final double blockFraction = (durationMins > 0)
                                                ? (math.max(25, durationMins) / (24.0 * 60.0))
                                                : (35.0 / (24.0 * 60.0));

                                            final left = (startFraction * trackWidth).clamp(0.0, trackWidth - 8.0);
                                            final width = (blockFraction * trackWidth).clamp(8.0, trackWidth - left);

                                            return Positioned(
                                              left: left,
                                              top: 2,
                                              bottom: 2,
                                              width: width,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: catColor.withOpacity(isDark ? 0.88 : 0.82),
                                                  borderRadius: BorderRadius.circular(3),
                                                  border: Border.all(
                                                    color: catColor,
                                                    width: 0.6,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: catColor.withOpacity(0.25),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 하단 안내 텍스트 및 범례
          Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 13, color: appTextTertiary),
              const SizedBox(width: 4),
              Text(
                isKo ? '날짜를 탭하면 해당 일의 모든 기록 목록을 열람할 수 있습니다' : 'Tap a date to view all records for that day',
                style: GoogleFonts.inter(fontSize: 11, color: appTextTertiary),
              ),
            ],
          ),
          if (categoriesInMonth.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categoriesInMonth.map((cat) {
                  final catColor = _getCategoryColor(cat);
                  final count = monthEntries.where((e) => e.category == cat).length;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(isDark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: catColor.withOpacity(0.35), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: themeAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyTimetableCard(List<TimestampEntry> allEntries) {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final weekStart = DateTime(_selectedWeekStart.year, _selectedWeekStart.month, _selectedWeekStart.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final currentWeekStart = todayOnly.subtract(Duration(days: todayOnly.weekday - 1));
    final bool isCurrentWeek = weekStart == currentWeekStart;

    final weekEntries = allEntries.where((e) {
      if (_selectedGlobalCategory != 'All' && e.category != _selectedGlobalCategory) return false;
      return (e.timestamp.isAfter(weekStart.subtract(const Duration(milliseconds: 1))) &&
              e.timestamp.isBefore(weekEnd));
    }).toList();

    final Map<String, List<TimestampEntry>> slotEntries = {};
    final Set<String> categoriesInWeek = {};
    for (final e in weekEntries) {
      final eDate = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      final dayDiff = eDate.difference(weekStart).inDays;
      if (dayDiff >= 0 && dayDiff < 7) {
        final key = '${dayDiff}_${e.timestamp.hour}';
        slotEntries.putIfAbsent(key, () => []).add(e);
        categoriesInWeek.add(e.category);
      }
    }

    final theme = ThemeController.instance.currentTheme;
    final isDark = theme.isDark;
    final themeAccent = (!isDark && theme.accent.computeLuminance() > 0.6)
        ? const Color(0xFF4F46E5)
        : theme.accent;

    final isKo = AppStrings.of(context).isKo;
    final weekdayLabels = isKo ? ['월', '화', '수', '목', '금', '토', '일'] : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final weekEndDisplay = weekStart.add(const Duration(days: 6));
    final periodTitle = '${weekStart.month}.${weekStart.day} ~ ${weekEndDisplay.month}.${weekEndDisplay.day}';

    return _buildSectionCard(
      title: AppStrings.of(context).insightWeeklyTable,
      subtitle: AppStrings.of(context).insightWeeklyTableDesc,
      icon: Icons.table_chart_rounded,
      selector: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
              });
            },
            icon: Icon(Icons.chevron_left_rounded, color: appTextSecondary),
            style: IconButton.styleFrom(
              backgroundColor: appSubtleBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedWeekStart = currentWeekStart;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      periodTitle,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: appText,
                      ),
                    ),
                    if (!isCurrentWeek) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeAccent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isKo ? '이번 주로' : 'This Week',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: themeAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isKo ? '${weekEntries.length}건의 기록' : '${weekEntries.length} records',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: appTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
              });
            },
            icon: Icon(Icons.chevron_right_rounded, color: appTextSecondary),
            style: IconButton.styleFrom(
              backgroundColor: appSubtleBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Timetable Matrix Container
          Container(
            decoration: BoxDecoration(
              color: appSubtleBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: appBorder),
            ),
            child: Column(
              children: [
                // 1. Day of Week Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(bottom: BorderSide(color: appBorder)),
                  ),
                  child: Row(
                    children: [
                      // Time Axis Space
                      SizedBox(
                        width: 38,
                        child: Center(
                          child: Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: appTextTertiary,
                          ),
                        ),
                      ),
                      // 7 Days
                      ...List.generate(7, (i) {
                        final dayDate = weekStart.add(Duration(days: i));
                        final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;
                        final isWeekend = i >= 5;

                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              _showDayEntriesBottomSheet(
                                context,
                                date: dayDate,
                                entryFilter: (e) {
                                  if (_selectedGlobalCategory != 'All' && e.category != _selectedGlobalCategory) return false;
                                  return e.timestamp.year == dayDate.year &&
                                      e.timestamp.month == dayDate.month &&
                                      e.timestamp.day == dayDate.day;
                                },
                                title: isKo
                                    ? '${dayDate.year}년 ${dayDate.month}월 ${dayDate.day}일 (${weekdayLabels[i]})'
                                    : DateFormat('EEE, MMM d, yyyy').format(dayDate),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  weekdayLabels[i],
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                    color: isToday
                                        ? themeAccent
                                        : (isWeekend ? const Color(0xFFF59E0B) : appTextSecondary),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isToday ? themeAccent : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${dayDate.day}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                      color: isToday ? Colors.white : appText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // 2. Vertical 24-Hour Scrollable Grid
                SizedBox(
                  height: 350,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: List.generate(24, (hour) {
                        return Container(
                          height: 34,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Time Label Column
                              SizedBox(
                                width: 38,
                                child: Center(
                                  child: Text(
                                    '${hour.toString().padLeft(2, '0')}:00',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: appTextTertiary,
                                    ),
                                  ),
                                ),
                              ),
                              // 7 Day Cells
                              ...List.generate(7, (dayIdx) {
                                final dayDate = weekStart.add(Duration(days: dayIdx));
                                final items = slotEntries['${dayIdx}_$hour'] ?? [];

                                if (items.isEmpty) {
                                  return Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final first = items.first;
                                final catColor = _getCategoryColor(first.category);

                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(1.5),
                                    child: InkWell(
                                      onTap: () => _showTimetableSlotDetailsSheet(context, dayDate, hour, items),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: catColor.withOpacity(isDark ? 0.38 : 0.22),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: catColor.withOpacity(0.65),
                                            width: 1.0,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: catColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                Expanded(
                                                  child: Text(
                                                    first.text.trim(),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (items.length > 1)
                                                  Text(
                                                    '+${items.length - 1}',
                                                    style: GoogleFonts.jetBrainsMono(
                                                      fontSize: 7.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: catColor,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 14, color: appTextTertiary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  isKo
                      ? '시간 블록을 터치하면 해당 시간대의 상세 활동 내역을 볼 수 있습니다'
                      : 'Tap a time block to view detailed activity',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: appTextTertiary,
                  ),
                ),
              ),
            ],
          ),

          // Category Legend Chips
          if (categoriesInWeek.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categoriesInWeek.map((cat) {
                  final color = _getCategoryColor(cat);
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(
                          cat,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityCalendarCard(List<TimestampEntry> entries) {
    final now = DateTime.now();
    final bool isCurrentMonth = _calendarMonth.year == now.year &&
        _calendarMonth.month == now.month;

    final monthEntries = entries.where((e) =>
        e.timestamp.year == _calendarMonth.year &&
        e.timestamp.month == _calendarMonth.month &&
        (_selectedGlobalCategory == 'All' || e.category == _selectedGlobalCategory)).toList();

    final isKo = AppStrings.of(context).isKo;
    final int monthTotal = monthEntries.length;
    final int monthDoneTodos = entries.where((e) {
      if (_selectedGlobalCategory != 'All' && e.category != _selectedGlobalCategory) return false;
      if (e.status != 'done') return false;
      final doneDate = e.doneTimestamp ?? e.timestamp;
      return doneDate.year == _calendarMonth.year && doneDate.month == _calendarMonth.month;
    }).length;

    final int monthPendingTodos = entries.where((e) {
      if (_selectedGlobalCategory != 'All' && e.category != _selectedGlobalCategory) return false;
      if (!e.isPendingTodo) return false;
      if (isCurrentMonth) return true;
      final createdInMonth = e.timestamp.year == _calendarMonth.year && e.timestamp.month == _calendarMonth.month;
      final dueInMonth = e.targetDate != null && e.targetDate!.year == _calendarMonth.year && e.targetDate!.month == _calendarMonth.month;
      return createdInMonth || dueInMonth;
    }).length;

    return _buildSectionCard(
      title: AppStrings.of(context).insightCalendar,
      subtitle: AppStrings.of(context).insightCalendarDesc,
      icon: Icons.calendar_month_rounded,
      padding: const EdgeInsets.all(20),
      selector: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousCalendarMonth,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: appTextSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: appSubtleBg,
            ),
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDateKorean(_calendarMonth),
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: appText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isKo ? '$monthTotal건 기록됨' : '$monthTotal records',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: appTextTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _nextCalendarMonth,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: appTextSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: appSubtleBg,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          // Monthly Summary Banner (iOS Style)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: appSubtleBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: appBorder),
            ),
            child: Row(
              children: [
                _buildMonthMetricItem(
                  icon: Icons.history_rounded,
                  label: isKo ? '처리한 TODO' : 'Completed',
                  value: '$monthDoneTodos',
                  color: const Color(0xFF10B981),
                ),
                Container(width: 1, height: 26, color: appBorder),
                _buildMonthMetricItem(
                  icon: Icons.pending_actions_rounded,
                  label: isKo ? '진행 중 TODO' : 'In Progress',
                  value: '$monthPendingTodos',
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
          _buildActivityCalendar(entries),
        ],
      ),
    );
  }

  Widget _buildMonthMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: appText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: appTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<List<TimestampEntry>>(
          valueListenable: widget.entriesNotifier,
          builder: (context, entries, _) {
            // Where My Time Goes 전용 필터 적용
            final whereFilteredEntries = _getWhereFilteredEntries(entries);
            final whereTotalCount = whereFilteredEntries.length;
            final whereCategoryStats = _calculateStats(whereFilteredEntries, metricType: _whereMetricType);

            // 다른 통계 카드용 (전역 카테고리 필터만 적용)
            final globalFilteredEntries = entries.where((e) {
              if (_selectedGlobalCategory != 'All' &&
                  e.category != _selectedGlobalCategory) {
                return false;
              }
              return true;
            }).toList();

            final theme = ThemeController.instance.currentTheme;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.of(context).tabInsights,
                                style: GoogleFonts.inter(
                                  fontSize: 18 * widget.uiScale,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: appText,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppStrings.of(context).isKo
                                    ? '시간 활용과 활동 패턴을 한눈에 분석하세요'
                                    : 'Analyze your time & activity patterns',
                                style: GoogleFonts.inter(
                                  color: appTextTertiary,
                                  fontSize: 12.5 * widget.uiScale,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _showCardCustomizationSheet(context),
                          tooltip: AppStrings.of(context).isKo ? '통계 카드 편집' : 'Edit insight cards',
                          icon: const Icon(Icons.dashboard_customize_rounded, size: 20),
                          color: isAppDark ? Colors.white70 : const Color(0xFF475569),
                          style: IconButton.styleFrom(
                            backgroundColor: isAppDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                            padding: const EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pinned Category Filter Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _InsightCategoryFilterDelegate(
                    child: _buildGlobalCategoryFilter(entries),
                    height: 50 * widget.uiScale,
                    theme: theme,
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 120.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 인사이트 카테고리 필터 하단 배너 광고
                      if (!kIsProVersion)
                        const BannerAdWidget(
                          margin: EdgeInsets.only(bottom: 14),
                        ),

                      // Dynamic Cards in order
                      ..._cardOrder.where((id) => _cardVisibility[id] ?? true).map((id) {
                        switch (id) {
                          case 'weekly_timetable':
                            return _buildWeeklyTimetableCard(entries);
                          case 'monthly_time_matrix':
                            return _buildMonthlyTimeMatrixCard(entries);
                          case 'where_my_time_goes':
                            return _buildWhereMyTimeGoesCard(whereFilteredEntries, whereTotalCount, whereCategoryStats);
                          case 'activity_distribution_24h':
                            return _build24HourDistributionCard(globalFilteredEntries);
                          case 'weekday_pattern':
                            return _buildWeekdayPatternCard(globalFilteredEntries);
                          case 'productivity_summary':
                            return _buildProductivitySummaryCard(globalFilteredEntries);
                          case 'top_tasks':
                            return _buildTopTasksCard(globalFilteredEntries);
                          case 'activity_calendar':
                            return _buildActivityCalendarCard(entries);
                          default:
                            return const SizedBox.shrink();
                        }
                      }).toList(),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivityCalendar(List<TimestampEntry> entries) {
    final firstDayOfMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    // Sunday is 0, Monday is 1, ..., Saturday is 6
    final startWeekday = firstDayOfMonth.weekday % 7;
    final totalSlots = startWeekday + daysInMonth;

    final isKo = AppStrings.of(context).isKo;
    final dayNames = isKo ? const ['일', '월', '화', '수', '목', '금', '토'] : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: appSubtleBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(7, (i) {
              final isSun = i == 0;
              final isSat = i == 6;
              return Expanded(
                child: Center(
                  child: Text(
                    dayNames[i],
                    style: GoogleFonts.inter(
                      color: isSun
                          ? const Color(0xFFEF4444).withOpacity(0.85)
                          : (isSat
                              ? const Color(0xFF3B82F6).withOpacity(0.85)
                              : appTextTertiary),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: totalSlots,
            itemBuilder: (context, index) {
              final dayOffset = index - startWeekday;
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }

                  final day = dayOffset + 1;
                  final currentDayDate = DateTime(
                    _calendarMonth.year,
                    _calendarMonth.month,
                    day,
                  );

                  final dayEntries = entries.where((e) {
                    if (_selectedGlobalCategory != 'All' &&
                        e.category != _selectedGlobalCategory) {
                      return false;
                    }

                    final createdOnDay =
                        e.timestamp.year == currentDayDate.year &&
                        e.timestamp.month == currentDayDate.month &&
                        e.timestamp.day == currentDayDate.day;
                    if (createdOnDay) return true;

                    final targetOnDay = e.isPendingTodo &&
                        e.targetDate != null &&
                        e.targetDate!.year == currentDayDate.year &&
                        e.targetDate!.month == currentDayDate.month &&
                        e.targetDate!.day == currentDayDate.day;
                    if (targetOnDay) return true;

                    final completedOnDay = e.status == 'done' &&
                        e.doneTimestamp != null &&
                        e.doneTimestamp!.year == currentDayDate.year &&
                        e.doneTimestamp!.month == currentDayDate.month &&
                        e.doneTimestamp!.day == currentDayDate.day;
                    if (completedOnDay) return true;

                    return false;
                  }).toList();

                  final bool isActive = dayEntries.isNotEmpty;
                  final color = isActive
                      ? (_selectedGlobalCategory != 'All'
                            ? _getCategoryColor(_selectedGlobalCategory)
                            : _getCategoryColor(dayEntries.first.category))
                      : Colors.transparent;

                  final bool isSelected =
                      _selectedCalendarDay != null &&
                      _selectedCalendarDay?.year == currentDayDate.year &&
                      _selectedCalendarDay?.month == currentDayDate.month &&
                      _selectedCalendarDay?.day == currentDayDate.day;

                  return InkWell(
                    onTap: () {
                      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                      final w = weekdays[(currentDayDate.weekday - 1).clamp(0, 6)];
                      setState(() {
                        _selectedCalendarDay = currentDayDate;
                      });
                      _showDayEntriesBottomSheet(
                        context,
                        date: currentDayDate,
                        entryFilter: (e) {
                          if (_selectedGlobalCategory != 'All' &&
                              e.category != _selectedGlobalCategory) {
                            return false;
                          }

                          final sameCreated =
                              e.timestamp.year == currentDayDate.year &&
                              e.timestamp.month == currentDayDate.month &&
                              e.timestamp.day == currentDayDate.day;
                          if (sameCreated) return true;

                          final sameTarget = e.isPendingTodo &&
                              e.targetDate != null &&
                              e.targetDate!.year == currentDayDate.year &&
                              e.targetDate!.month == currentDayDate.month &&
                              e.targetDate!.day == currentDayDate.day;
                          if (sameTarget) return true;

                          final sameDone = e.status == 'done' &&
                              e.doneTimestamp != null &&
                              e.doneTimestamp!.year == currentDayDate.year &&
                              e.doneTimestamp!.month == currentDayDate.month &&
                              e.doneTimestamp!.day == currentDayDate.day;
                          if (sameDone) return true;

                          return false;
                        },
                        title: isKo
                            ? '${currentDayDate.year}년 ${currentDayDate.month}월 ${currentDayDate.day}일 ($w)'
                            : DateFormat('EEE, MMM d, yyyy').format(currentDayDate),
                      ).then((_) {
                        if (mounted) {
                          setState(() {
                            _selectedCalendarDay = null;
                          });
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.4)
                            : (isActive
                                  ? color.withOpacity(0.2)
                                  : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : (isActive
                                    ? color.withOpacity(0.5)
                                    : appBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: GoogleFonts.jetBrainsMono(
                            color: isSelected
                                ? Colors.white
                                : (isActive
                                      ? color
                                      : appTextTertiary),
                            fontSize: 12,
                            fontWeight: isSelected || isActive
                                ? FontWeight.w800
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
  }

  Color _getAdjustedColor(
    TimestampEntry entry,
    Color baseColor, {
    String? statusOverride,
  }) {
    final status = statusOverride ?? entry.status;
    final hsl = HSLColor.fromColor(baseColor);
    if (status == 'todo' || status == 'in_progress' || status == 'paused') {
      double factor;
      if (entry.targetDate != null) {
        final now = DateTime.now();
        final totalDuration = entry.targetDate!
            .difference(entry.timestamp)
            .inSeconds;
        final elapsed = now.difference(entry.timestamp).inSeconds;

        if (totalDuration <= 0) {
          factor = 1.0;
        } else {
          factor = (elapsed / totalDuration).clamp(0.0, 1.0);
        }
      } else {
        final age = DateTime.now().difference(entry.timestamp);
        factor = (age.inSeconds / 86400.0).clamp(0.0, 1.0);
      }

      final newSaturation = (hsl.saturation + (0.3 * factor)).clamp(0.0, 1.0);
      return hsl
          .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
          .withSaturation(newSaturation)
          .toColor();
    } else if (status == 'done') {
      return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
    }
    return baseColor;
  }

  Widget _buildDayDetailList(List<TimestampEntry> entries) {
    if (_selectedCalendarDay == null) return const SizedBox.shrink();

    final List<Map<String, dynamic>> dayRecords = [];

    for (final entry in entries) {
      if (_selectedGlobalCategory != 'All' &&
          entry.category != _selectedGlobalCategory) {
        continue;
      }

      final sameCreated =
          entry.timestamp.year == _selectedCalendarDay!.year &&
          entry.timestamp.month == _selectedCalendarDay!.month &&
          entry.timestamp.day == _selectedCalendarDay!.day;

      final sameDone = entry.status == 'done' &&
          entry.doneTimestamp != null &&
          entry.doneTimestamp!.year == _selectedCalendarDay!.year &&
          entry.doneTimestamp!.month == _selectedCalendarDay!.month &&
          entry.doneTimestamp!.day == _selectedCalendarDay!.day;
          
      // 같은 날 생성되고 같은 날 완료된 건은 todo_created로 중복 추가하지 않고 done으로만 표시
      if (sameCreated && !sameDone) {
        dayRecords.add({
          'entry': entry,
          'time': entry.timestamp,
          'type': entry.isAnyTodo
              ? 'todo_created'
              : 'moment',
        });
      }

      final sameTarget = entry.isPendingTodo &&
          entry.targetDate != null &&
          entry.targetDate!.year == _selectedCalendarDay!.year &&
          entry.targetDate!.month == _selectedCalendarDay!.month &&
          entry.targetDate!.day == _selectedCalendarDay!.day;
          
      if (sameTarget) {
        dayRecords.add({
          'entry': entry,
          'time': entry.targetDate!,
          'type': 'todo_target',
        });
      }

      if (sameDone) {
        dayRecords.add({
          'entry': entry,
          'time': entry.doneTimestamp!,
          'type': 'done',
        });
      }
    }

    dayRecords.sort(
      (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appSubtleBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _formatDateKorean(_selectedCalendarDay!, includeWeekday: true),
                  style: GoogleFonts.inter(
                    color: appText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedCalendarDay = null),
                icon: Icon(
                  Icons.close_rounded,
                  color: appTextSecondary,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dayRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  AppStrings.of(context).isKo ? '이 날짜의 기록이 없습니다' : 'No records on this date',
                  style: GoogleFonts.inter(
                    color: appTextTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...dayRecords.map((record) => _DetailRecordWidget(
                  record: record,
                  getCategoryColor: _getCategoryColor,
                  getAdjustedColor: _getAdjustedColor,
                )),
        ],
      ),
    );
  }

  Map<String, Map<String, dynamic>> _calculateStats(
    List<TimestampEntry> entries, {
    String metricType = 'count',
  }) {
    if (entries.isEmpty) return {};
    final Map<String, int> counts = {};
    final Map<String, int> durations = {};
    int totalDuration = 0;

    for (var entry in entries) {
      counts[entry.category] = (counts[entry.category] ?? 0) + 1;
      int dur = entry.computedDurationMinutes ?? 0;
      if (dur <= 0 && entry.status == 'done' && entry.doneTimestamp != null) {
        dur = entry.doneTimestamp!.difference(entry.timestamp).inMinutes;
      }
      if (dur > 0) {
        durations[entry.category] = (durations[entry.category] ?? 0) + dur;
        totalDuration += dur;
      }
    }

    final bool hasTimeData = totalDuration > 0;
    final int totalCount = entries.length;
    final String effectiveMetricType = metricType;

    final result = <String, Map<String, dynamic>>{};
    for (var entry in counts.entries) {
      final k = entry.key;
      final count = entry.value;
      final catDuration = durations[k] ?? 0;
      final double timePercentage = (totalDuration > 0) ? (catDuration / totalDuration) : 0.0;
      final double countPercentage = (totalCount > 0) ? (count / totalCount) : 0.0;

      final double percentage = (effectiveMetricType == 'time')
          ? timePercentage
          : countPercentage;

      result[k] = {
        'percentage': percentage,
        'timePercentage': timePercentage,
        'countPercentage': countPercentage,
        'count': count,
        'durationMinutes': catDuration,
        'totalDurationMinutes': totalDuration,
        'hasTimeData': hasTimeData,
        'metricType': effectiveMetricType,
      };
    }

    final sortedEntries = result.entries.toList()
      ..sort((a, b) {
        final cmp = (b.value['percentage'] as double).compareTo(a.value['percentage'] as double);
        if (cmp != 0) return cmp;
        if (effectiveMetricType == 'time') {
          return (b.value['count'] as int).compareTo(a.value['count'] as int);
        } else {
          return (b.value['durationMinutes'] as int).compareTo(a.value['durationMinutes'] as int);
        }
      });

    return Map.fromEntries(sortedEntries);
  }

  Widget _buildStatRow(
    String category,
    Map<String, dynamic> data,
    int total, {
    Color? color,
  }) {
    final effectiveColor = color ?? _getCategoryColor(category);
    final double percentage = (data['percentage'] as num).toDouble();
    final int count = data['count'] as int;
    final int duration = data['durationMinutes'] as int? ?? 0;
    final String metricType = data['metricType'] as String? ?? 'time';

    final isKo = AppStrings.isCurrentLocaleKo;
    String subtitle;
    if (metricType == 'time') {
      if (duration > 0) {
        subtitle = isKo ? '${_formatMinutes(duration)} 소요 • $count건' : '${_formatMinutes(duration)} spent • $count items';
      } else {
        subtitle = isKo ? '소요 시간 없음 • $count건' : 'No elapsed time • $count items';
      }
    } else {
      if (duration > 0) {
        subtitle = isKo ? '$count건 기록 • ${_formatMinutes(duration)} 소요' : '$count records • ${_formatMinutes(duration)} spent';
      } else {
        subtitle = isKo ? '$count건 기록' : '$count records';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.inter(
                        color: appText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: appTextTertiary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.jetBrainsMono(
                  color: effectiveColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isAppDark ? effectiveColor.withOpacity(0.12) : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveColor,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    if (widget.categoryColors != null && widget.categoryColors!.containsKey(category)) {
      return widget.categoryColors![category]!;
    }
    switch (category) {
      case 'General':
        return const Color(0xFF64748B);
      case 'Work':
        return const Color(0xFF6366F1);
      case 'Personal':
        return const Color(0xFF10B981);
      case 'Health':
        return const Color(0xFFEF4444);
      case 'Study':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

}




class _DetailRecordWidget extends StatefulWidget {
  final Map<String, dynamic> record;
  final Color Function(String) getCategoryColor;
  final Color Function(TimestampEntry, Color, {String? statusOverride})
      getAdjustedColor;

  const _DetailRecordWidget({
    required this.record,
    required this.getCategoryColor,
    required this.getAdjustedColor,
  });

  @override
  State<_DetailRecordWidget> createState() => _DetailRecordWidgetState();
}

class _DetailRecordWidgetState extends State<_DetailRecordWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isKo = AppStrings.of(context).isKo;
    final entry = widget.record['entry'] as TimestampEntry;
    final time = widget.record['time'] as DateTime;
    final type = widget.record['type'] as String;
    final baseColor = widget.getCategoryColor(entry.category);
    final adjustedColor = widget.getAdjustedColor(
      entry,
      baseColor,
      statusOverride: (type == 'done') ? 'done' : 'todo',
    );

    Color accentColor;
    IconData typeIcon;
    String typeLabel;

    if (type == 'done') {
      accentColor = adjustedColor;
      typeIcon = Icons.check_circle_outline_rounded;
      typeLabel = isKo ? '완료' : 'DONE';
    } else if (type == 'todo_created') {
      accentColor = adjustedColor;
      typeIcon = Icons.radio_button_unchecked_rounded;
      typeLabel = 'TODO';
    } else if (type == 'todo_target') {
      accentColor = adjustedColor;
      typeIcon = Icons.flag_rounded;
      typeLabel = isKo ? '목표' : 'DUE';
    } else {
      accentColor = baseColor;
      typeIcon = Icons.fiber_manual_record_rounded;
      typeLabel = '';
    }

    final bool isExpandable = entry.note.length > 30 ||
        (type == 'done' || type == 'todo_target') ||
        entry.doneNote != null ||
        entry.imagePath != null ||
        entry.doneImagePath != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: isExpandable ? () => setState(() => _isExpanded = !_isExpanded) : null,
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('HH:mm').format(time),
                    style: GoogleFonts.jetBrainsMono(
                      color: appTextTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 3,
              height: 28,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (typeLabel.isNotEmpty) ...[
                        Icon(typeIcon, size: 14, color: accentColor),
                        const SizedBox(width: 5),
                      ],
                      Expanded(
                        child: Text(
                          entry.note,
                          style: GoogleFonts.inter(
                            color: (type == 'done')
                                ? appTextSecondary
                                : appText,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                            height: 1.35,
                            decoration: (type == 'done')
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (type == 'done') ...[
                    if (entry.doneImagePath != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: GestureDetector(
                          onTap: () => _showFullScreenImagePreview(context, entry.doneImagePath!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(entry.doneImagePath!),
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                  ] else ...[
                    if (entry.imagePath != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: GestureDetector(
                          onTap: () => _showFullScreenImagePreview(context, entry.imagePath!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(entry.imagePath!),
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                  ],
                  if (_isExpanded) ...[
                    const SizedBox(height: 6),
                    // DONE details
                    if (type == 'done' && entry.doneNote != null && entry.doneNote!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 14,
                                  color: accentColor.withOpacity(0.7),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isKo ? '완료 메모' : 'Completion Note',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor.withOpacity(0.8),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.doneNote!,
                              style: GoogleFonts.inter(
                                color: appTextSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Actual Duration result
                    if (entry.computedDurationMinutes != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              size: 12,
                              color: accentColor.withOpacity(0.8),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isKo
                                  ? '소요 시간: ${formatSecondsKo(entry.effectiveDurationSeconds)}'
                                  : 'Duration: ${formatSecondsKo(entry.effectiveDurationSeconds)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accentColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Planned Context
                    if (type == 'done' || type == 'todo_target')
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: appTextTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: appTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
