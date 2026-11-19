import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:todonow/main.dart';

/// 사용 가능한 타임스탬프 디자인 (적용안함 + 무료 기본 4종 + frame_1)
enum TimestampDesign {
  none, // 적용안함 (디폴트)
  n1_1, // 2026.11.17 AM 12:27 (RubberNippleFactory)
  n1_2, // 2026/11/17 AM 12:27 (NixieOne)
  n2_1, // 2026년 11월 17일 (화) / 오전 12:27 (Cafe24OnePrettyNight)
  n2_2, // 2026년 11월 17일 / 오전 12:27 (NanumAmsterdam)
  frame_1, // timenow frame_1 (뷰파인더 프레임 + REC + 일시)
}

enum CameraAspectRatio {
  ratio1x1(1.0, '1:1'),
  ratio4x5(0.8, '4:5'),
  ratio9x16(9.0 / 16.0, '9:16');

  final double value;
  final String label;
  const CameraAspectRatio(this.value, this.label);
}

class TimestampLocaleFormatter {
  static const List<String> weekdaysKo = ['월', '화', '수', '목', '금', '토', '일'];

  static String formatNumericDate(DateTime dt, {String sep = '.'}) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$sep$m$sep$d';
  }

  static String formatLegacyN2_1Date(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final w = weekdaysKo[dt.weekday - 1];
    return '$y년 $m월 $d일 ($w)';
  }

  static String formatWordDate(DateTime dt, {bool padMonthDay = true}) {
    final y = dt.year;
    final m = padMonthDay ? dt.month.toString().padLeft(2, '0') : dt.month.toString();
    final d = padMonthDay ? dt.day.toString().padLeft(2, '0') : dt.day.toString();
    return '$y년 $m월 $d일';
  }

  static String format12hTime(
    DateTime dt, {
    bool padHour = true,
    bool localizePeriod = false,
  }) {
    final isAm = dt.hour < 12;
    final period = localizePeriod ? (isAm ? '오전' : '오후') : (isAm ? 'AM' : 'PM');
    int h = dt.hour % 12;
    if (h == 0) h = 12;
    final hStr = padHour ? h.toString().padLeft(2, '0') : h.toString();
    final mStr = dt.minute.toString().padLeft(2, '0');
    return '$period $hStr:$mStr';
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isReady = false;
  bool _isCapturing = false;

  // 종횡비 & 스탬프 설정
  CameraAspectRatio _aspectRatio = CameraAspectRatio.ratio1x1;
  TimestampDesign _currentDesign = TimestampDesign.none; // 기본: 적용안함
  Alignment _currentAlignment = Alignment.center;
  int _fontSizeIndex = 1; // 0: 1A, 1: 2A, 2: 3A

  // frame_1 에셋 ui.Image 캐시
  ui.Image? _frame1Image;
  ui.Image? _rec1Image;

  // 줌
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 5.0;
  double _baseZoom = 1.0;

  // 포커스
  Offset? _focusPoint;
  bool _showFocusIndicator = false;
  Timer? _focusTimer;

  // 실시간 시계 업데이트 (1초 주기)
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  static const List<Alignment> _availableAlignments = [
    Alignment.center,
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomCenter,
    Alignment.bottomRight,
  ];

  static const List<Shadow> _defaultShadows = [
    Shadow(offset: Offset(0, 1), blurRadius: 4.0, color: Colors.black54),
    Shadow(offset: Offset(0, 2), blurRadius: 10.0, color: Colors.black26),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _loadStampImages();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  Future<void> _loadStampImages() async {
    try {
      final f1Bytes = await rootBundle.load('assets/timestamp/frame/frame_1.png');
      final f1Codec = await ui.instantiateImageCodec(f1Bytes.buffer.asUint8List());
      final f1Frame = await f1Codec.getNextFrame();
      _frame1Image = f1Frame.image;

      final recBytes = await rootBundle.load('assets/timestamp/frame/rec_1.png');
      final recCodec = await ui.instantiateImageCodec(recBytes.buffer.asUint8List());
      final recFrame = await recCodec.getNextFrame();
      _rec1Image = recFrame.image;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading frame stamp images: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;
    // 앱이 비활성화되거나 백그라운드로 이동할 때 (화면 잠김 포함)
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (mounted) {
        setState(() {
          _isReady = false;
          _controller = null;
        });
      }
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // 앱으로 복귀했을 때 카메라 재초기화
      if (mounted) {
        _initializeCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _focusTimer?.cancel();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      int backCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backCameraIndex != -1 ? backCameraIndex : 0;

      await _setupController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isReady = false;
          _controller = null;
        });
      }
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    final prev = _controller;
    if (mounted) {
      setState(() => _isReady = false);
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.veryHigh, // 1080p 고화질 + 제로 셔터랙 (3초 지연 없는 즉각 촬영)
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await prev?.dispose();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = math.min(5.0, await controller.getMaxZoomLevel());
      _currentZoom = _minZoom;
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}

      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      debugPrint('Error setting up camera controller: $e');
      if (mounted) {
        setState(() {
          _isReady = false;
          _controller = null;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || !_isReady) return;
    HapticFeedback.selectionClick();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isReady = false);
    await _setupController(_cameras[_selectedCameraIndex]);
  }

  void _cycleAlignment() {
    HapticFeedback.selectionClick();
    final currentIndex = _availableAlignments.indexOf(_currentAlignment);
    final nextIndex = (currentIndex + 1) % _availableAlignments.length;
    setState(() {
      _currentAlignment = _availableAlignments[nextIndex];
    });
  }

  void _cycleFontSize() {
    HapticFeedback.selectionClick();
    setState(() {
      _fontSizeIndex = (_fontSizeIndex + 1) % 3;
    });
  }

  double get _baseFontSize {
    switch (_currentDesign) {
      case TimestampDesign.none:
        return 20.0;
      case TimestampDesign.n1_1:
        return 20.0;
      case TimestampDesign.n1_2:
        return 25.0;
      case TimestampDesign.n2_1:
        return 32.0;
      case TimestampDesign.n2_2:
        return 30.0;
      case TimestampDesign.frame_1:
        return 28.0;
    }
  }

  double get _scaledFontSize {
    final multipliers = [0.85, 1.0, 1.25];
    return _baseFontSize * multipliers[_fontSizeIndex];
  }

  void _handleTapToFocus(Offset localPos, double boxW, double boxH) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final point = Offset(localPos.dx / boxW, localPos.dy / boxH);
    try {
      await _controller!.setFocusPoint(point);
      await _controller!.setExposurePoint(point);
    } catch (_) {}

    setState(() {
      _focusPoint = localPos;
      _showFocusIndicator = true;
    });
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showFocusIndicator = false);
    });
  }

  void _onShutterPressed() {
    if (_isCapturing || !_isReady) return;
    _captureAndProcess();
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _isCapturing = true;
    });
    HapticFeedback.mediumImpact();

    try {
      final captureTime = DateTime.now();
      final XFile photo = await _controller!.takePicture();
      final isFront = _controller!.description.lensDirection == CameraLensDirection.front;

      // 이미지 처리 및 타임스탬프 합성
      final finalPath = await _processPhoto(
        rawPath: photo.path,
        aspectRatio: _aspectRatio.value,
        isFront: isFront,
        design: _currentDesign,
        captureTime: captureTime,
        alignment: _currentAlignment,
        fontSize: _scaledFontSize,
      );

      if (mounted) {
        Navigator.pop(context, finalPath);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<String> _processPhoto({
    required String rawPath,
    required double aspectRatio,
    required bool isFront,
    required TimestampDesign design,
    required DateTime captureTime,
    required Alignment alignment,
    required double fontSize,
  }) async {
    final rawBytes = await File(rawPath).readAsBytes();

    // 1. 원본 해상도 네이티브 디코더 (불필요한 강제 업스케일링 및 병목 제거)
    final codec = await ui.instantiateImageCodec(
      rawBytes,
    );
    final frame = await codec.getNextFrame();
    final uiImage = frame.image;

    final imgW = uiImage.width.toDouble();
    final imgH = uiImage.height.toDouble();

    // 2. 종횡비 크롭 영역 계산 (Center Crop)
    double targetW = imgW;
    double targetH = imgH;
    if (imgW / imgH > aspectRatio) {
      targetW = imgH * aspectRatio;
    } else {
      targetH = imgW / aspectRatio;
    }

    // 선명 해상도 (긴 변 기준 1440px 최적화: timenow급 선명 화질 유지 및 고속 인코딩)
    const double maxDimension = 1440.0;
    double outW = targetW;
    double outH = targetH;
    final double maxSide = math.max(targetW, targetH);
    if (maxSide > maxDimension) {
      final double downscale = maxDimension / maxSide;
      outW = targetW * downscale;
      outH = targetH * downscale;
    }

    final srcX = (imgW - targetW) / 2.0;
    final srcY = (imgH - targetH) / 2.0;
    final srcRect = Rect.fromLTWH(srcX, srcY, targetW, targetH);
    final dstRect = Rect.fromLTWH(0, 0, outW, outH);

    // frame_1 사용 시 이미지 로드 보장
    if (design == TimestampDesign.frame_1 && (_frame1Image == null || _rec1Image == null)) {
      await _loadStampImages();
    }

    // 3. GPU 하드웨어 가속 Canvas 렌더링 (초고속 크롭 + 전면반전 + 타임스탬프)
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.save();
    if (isFront) {
      canvas.translate(outW, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
      uiImage,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    // 4. 타임스탬프 합성
    if (design != TimestampDesign.none) {
      final scale = outW / 390.0;
      final drawFontSize = fontSize * scale;

      _paintTimestampOnCanvas(
        canvas: canvas,
        canvasSize: Size(outW, outH),
        design: design,
        time: captureTime,
        alignment: alignment,
        fontSize: drawFontSize,
        scale: scale,
      );
    }

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(outW.toInt(), outH.toInt());
    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);

    final tempDir = await getTemporaryDirectory();
    final outPath = path.join(
      tempDir.path,
      'todonow_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final outFile = File(outPath);
    await outFile.writeAsBytes(byteData!.buffer.asUint8List());

    // 5. timenow와 동일하게 기기 앨범(갤러리)에 비동기 저장 (화면 복귀 지연 방지)
    unawaited(
      Gal.putImage(outPath, album: 'todonow').catchError((e) {
        debugPrint('Failed to save to gallery album: $e');
        return Gal.putImage(outPath).catchError((e2) {
          debugPrint('Fallback gallery save failed: $e2');
        });
      }),
    );

    return outFile.path;
  }

  void _paintTimestampOnCanvas({
    required Canvas canvas,
    required Size canvasSize,
    required TimestampDesign design,
    required DateTime time,
    required Alignment alignment,
    required double fontSize,
    required double scale,
  }) {
    final margin = 20.0 * scale;
    final shadows = _defaultShadows.map((s) {
      return Shadow(
        offset: s.offset * scale,
        blurRadius: s.blurRadius * scale,
        color: s.color,
      );
    }).toList();

    if (design == TimestampDesign.none) return;

    if (design == TimestampDesign.frame_1) {
      // 1. frame_1.png 뷰파인더 테두리 그리기 (3분할 스트레치로 비율에 맞춰 자연스럽게 확장)
      final frameInset = 16.0 * scale;
      final frameRect = Rect.fromLTWH(
        frameInset,
        frameInset,
        canvasSize.width - frameInset * 2,
        canvasSize.height - frameInset * 2,
      );

      if (_frame1Image != null) {
        Frame1WidgetPainter.drawThreeSlice(canvas, _frame1Image!, frameRect);
      }

      // 2. rec_1.png REC 아이콘 그리기 (좌상단)
      if (_rec1Image != null) {
        final recW = 44.0 * scale;
        final recH = recW * (_rec1Image!.height / _rec1Image!.width);
        final recRect = Rect.fromLTWH(frameRect.left + 16.0 * scale, frameRect.top + 14.0 * scale, recW, recH);
        final srcRect = Rect.fromLTWH(0, 0, _rec1Image!.width.toDouble(), _rec1Image!.height.toDouble());
        canvas.drawImageRect(_rec1Image!, srcRect, recRect, Paint()..filterQuality = FilterQuality.high);
      }

      // 3. 일시 텍스트 그리기 (프레임 정중앙에 고정)
      final dateStr = TimestampLocaleFormatter.formatNumericDate(time, sep: '/');
      final timeStr = TimestampLocaleFormatter.format12hTime(time, padHour: true, localizePeriod: false);

      final dateTp = TextPainter(
        text: TextSpan(
          text: dateStr,
          style: TextStyle(
            fontFamily: 'Cafe24OnePrettyNight',
            fontSize: fontSize * 0.44,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: shadows,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final timeTp = TextPainter(
        text: TextSpan(
          text: timeStr,
          style: TextStyle(
            fontFamily: 'RubberNippleFactory',
            fontSize: fontSize * 0.92,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: shadows,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final totalH = dateTp.height + 4 * scale + timeTp.height;
      final maxW = math.max(dateTp.width, timeTp.width);

      // frame_1은 항상 프레임 정중앙에 배치
      final cx = frameRect.left + (frameRect.width - maxW) / 2.0;
      final cy = frameRect.top + (frameRect.height - totalH) / 2.0;

      final dateX = cx + (maxW - dateTp.width) / 2;
      dateTp.paint(canvas, Offset(dateX, cy));

      final timeX = cx + (maxW - timeTp.width) / 2;
      timeTp.paint(canvas, Offset(timeX, cy + dateTp.height + 4 * scale));
      return;
    }

    TextPainter painter;

    switch (design) {
      case TimestampDesign.none:
      case TimestampDesign.frame_1:
        return;

      case TimestampDesign.n1_1:
        final dateStr = TimestampLocaleFormatter.formatNumericDate(time, sep: '.');
        final timeStr = TimestampLocaleFormatter.format12hTime(time, padHour: true, localizePeriod: false);
        final fullText = '$dateStr $timeStr';
        painter = TextPainter(
          text: TextSpan(
            text: fullText,
            style: TextStyle(
              fontFamily: 'RubberNippleFactory',
              fontSize: fontSize,
              color: Colors.white,
              height: 1.0,
              shadows: shadows,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: canvasSize.width - margin * 2);
        break;

      case TimestampDesign.n1_2:
        final dateStr = TimestampLocaleFormatter.formatNumericDate(time, sep: '/');
        final timeStr = TimestampLocaleFormatter.format12hTime(time, padHour: true, localizePeriod: false);
        final fullText = '$dateStr $timeStr';
        painter = TextPainter(
          text: TextSpan(
            text: fullText,
            style: TextStyle(
              fontFamily: 'NixieOne',
              fontSize: fontSize,
              color: Colors.white,
              height: 1.0,
              shadows: shadows,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: canvasSize.width - margin * 2);
        break;

      case TimestampDesign.n2_1:
        final dateStr = TimestampLocaleFormatter.formatLegacyN2_1Date(time);
        final timeStr = TimestampLocaleFormatter.format12hTime(time, padHour: false, localizePeriod: true);
        final dateFontSize = fontSize * 0.36;

        painter = TextPainter(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$dateStr\n',
                style: TextStyle(
                  fontFamily: 'Cafe24OnePrettyNight',
                  fontSize: dateFontSize,
                  color: Colors.white,
                  height: 1.15,
                  shadows: shadows,
                ),
              ),
              TextSpan(
                text: timeStr,
                style: TextStyle(
                  fontFamily: 'Cafe24OnePrettyNight',
                  fontSize: fontSize,
                  color: Colors.white,
                  height: 1.0,
                  shadows: shadows,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: canvasSize.width - margin * 2);
        break;

      case TimestampDesign.n2_2:
        final dateStr = TimestampLocaleFormatter.formatWordDate(time, padMonthDay: true);
        final timeStr = TimestampLocaleFormatter.format12hTime(time, padHour: true, localizePeriod: true);
        final dateFontSize = fontSize * 0.52;

        painter = TextPainter(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$dateStr\n',
                style: TextStyle(
                  fontFamily: 'NanumAmsterdam',
                  fontSize: dateFontSize,
                  color: Colors.white,
                  height: 1.15,
                  shadows: shadows,
                ),
              ),
              TextSpan(
                text: timeStr,
                style: TextStyle(
                  fontFamily: 'NanumAmsterdam',
                  fontSize: fontSize,
                  color: Colors.white,
                  height: 1.0,
                  shadows: shadows,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: canvasSize.width - margin * 2);
        break;
    }

    // Alignment 에 따른 캔버스 좌표 계산
    final textW = painter.width;
    final textH = painter.height;

    double dx;
    double dy;

    if (alignment.x == 0.0) {
      dx = (canvasSize.width - textW) / 2;
    } else if (alignment.x < 0) {
      dx = margin;
    } else {
      dx = canvasSize.width - textW - margin;
    }

    if (alignment.y == 0.0) {
      dy = (canvasSize.height - textH) / 2;
    } else if (alignment.y < 0) {
      dy = margin;
    } else {
      dy = canvasSize.height - textH - margin;
    }

    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    final accentColor = ThemeController.instance.currentTheme.accent;

    if (!_isReady || _controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
      );
    }

    final topPadding = MediaQuery.of(context).padding.top;
    final topMenuH = topPadding + 56;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 카메라 뷰파인더 & 타임스탬프 오버레이 (상단 메뉴 아래 고정, 아래로 비율 확장)
          _buildCameraViewfinder(topMenuH),

          // 2. 우측 플로팅 컨트롤 (위치 & 폰트 크기 변경) -> 화면 정중앙(세로 가운데) 배치
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildFloatingControls(accentColor),
            ),
          ),

          // 3. 상단 메뉴 바 (timenow처럼 검은색 배경 고정, X 및 카메라 전환 버튼 배경색 없음)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(topPadding, topMenuH),
          ),

          // 4. 하단 컨트롤 스택 (비율 선택, 타임스탬프 피커, 셔터 바)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 8,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRatioButtons(accentColor),
                const SizedBox(height: 10),
                _buildTimestampPicker(accentColor),
                const SizedBox(height: 14),
                _buildShutterBar(accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double topPadding, double topMenuH) {
    return Container(
      height: topMenuH,
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(16, topPadding + 4, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 닫기 (X) - 배경색 없음
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 26),
            ),
          ),

          // 전후면 전환 - 배경색 없음
          GestureDetector(
            onTap: _switchCamera,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraViewfinder(double topMenuH) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;

        double boxW = screenW;
        double boxH;
        final boxTop = topMenuH; // 상단 검은색 메뉴 바로 아래 고정

        switch (_aspectRatio) {
          case CameraAspectRatio.ratio1x1:
            boxH = screenW;
            break;
          case CameraAspectRatio.ratio4x5:
            boxH = screenW * (5.0 / 4.0);
            break;
          case CameraAspectRatio.ratio9x16:
            boxH = screenW * (16.0 / 9.0);
            break;
        }

        return GestureDetector(
          onScaleStart: (_) => _baseZoom = _currentZoom,
          onScaleUpdate: (d) async {
            final z = (_baseZoom * d.scale).clamp(_minZoom, _maxZoom);
            try {
              await _controller!.setZoomLevel(z);
            } catch (_) {}
            if (mounted) setState(() => _currentZoom = z);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 뷰파인더 박스
              Positioned(
                left: 0,
                top: boxTop,
                width: boxW,
                height: boxH,
                child: ClipRect(
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 실시간 카메라 프리뷰 (timenow 센서 비율 정밀 피팅)
                        if (_controller != null && _controller!.value.isInitialized)
                          _buildPrecisePreview(boxW, boxH)
                        else
                          const Center(
                            child: CircularProgressIndicator(color: Colors.white24),
                          ),

                      // 탭 투 포커스 감지 영역
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) {
                            _handleTapToFocus(details.localPosition, boxW, boxH);
                          },
                        ),
                      ),

                      // 실시간 타임스탬프 오버레이
                      if (_currentDesign != TimestampDesign.none)
                        Positioned.fill(
                          child: _buildLiveTimestampOverlay(
                            design: _currentDesign,
                            time: _now,
                            alignment: _currentAlignment,
                            fontSize: _scaledFontSize,
                          ),
                        ),

                      // 포커스 인디케이터 (노란색 링)
                      if (_showFocusIndicator && _focusPoint != null)
                        Positioned(
                          left: _focusPoint!.dx - 28,
                          top: _focusPoint!.dy - 28,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
    );
  }

  Widget _buildPrecisePreview(double boxW, double boxH) {
    final sensorRatio = 1 / _controller!.value.aspectRatio;
    final boxRatio = boxW / boxH;

    double previewW;
    double previewH;

    if (boxRatio < sensorRatio) {
      // 뷰파인더가 센서보다 세로로 더 김 (예: 9:16 뷰파인더에 4:3 센서) -> 높이에 맞추고 좌우 크롭
      previewH = boxH;
      previewW = boxH * sensorRatio;
    } else {
      // 뷰파인더가 센서보다 가로로 더 넓음 (예: 1:1 또는 4:5 뷰파인더에 4:3 센서) -> 너비에 맞추고 상하 크롭
      previewW = boxW;
      previewH = boxW / sensorRatio;
    }

    final previewLeft = (boxW - previewW) / 2;
    final previewTop = (boxH - previewH) / 2;

    return Stack(
      children: [
        Positioned(
          left: previewLeft,
          top: previewTop,
          width: previewW,
          height: previewH,
          child: CameraPreview(_controller!),
        ),
      ],
    );
  }

  Widget _buildLiveTimestampOverlay({
    required TimestampDesign design,
    required DateTime time,
    required Alignment alignment,
    required double fontSize,
  }) {
    if (design == TimestampDesign.none) {
      return const SizedBox.shrink();
    }

    if (design == TimestampDesign.frame_1) {
      final dateStr = TimestampLocaleFormatter.formatNumericDate(time, sep: '/');
      final timeStr = TimestampLocaleFormatter.format12hTime(time, padHour: true, localizePeriod: false);
      return Stack(
        fit: StackFit.expand,
        children: [
          // 프레임 3분할 스트레치 (비율에 맞춰 1:1, 4:5, 9:16 높이 전체로 확장)
          CustomPaint(
            size: Size.infinite,
            painter: Frame1WidgetPainter(
              frameImage: _frame1Image,
              recImage: _rec1Image,
            ),
          ),
          // 중앙 일시 텍스트 (위치는 항상 프레임 중앙 고정)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontFamily: 'Cafe24OnePrettyNight',
                    fontSize: fontSize * 0.44,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: _defaultShadows,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontFamily: 'RubberNippleFactory',
                    fontSize: fontSize * 0.92,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: _defaultShadows,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget stampWidget;

    switch (design) {
      case TimestampDesign.none:
      case TimestampDesign.frame_1:
        return const SizedBox.shrink();

      case TimestampDesign.n1_1:
        final dateStr = TimestampLocaleFormatter.formatNumericDate(time, sep: '.');
        final timeStr = TimestampLocaleFormatter.format12hTime(time, padHour: true, localizePeriod: false);
        stampWidget = Text(
          '$dateStr $timeStr',
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontFamily: 'RubberNippleFactory',
            fontSize: fontSize,
            color: Colors.white,
            height: 1.0,
            shadows: _defaultShadows,
          ),
        );
        break;

      case TimestampDesign.n1_2:
        final dateStr = TimestampLocaleFormatter.formatNumericDate(time, sep: '/');
        final timeStr = TimestampLocaleFormatter.format12hTime(time, padHour: true, localizePeriod: false);
        stampWidget = Text(
          '$dateStr $timeStr',
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontFamily: 'NixieOne',
            fontSize: fontSize,
            color: Colors.white,
            height: 1.0,
            shadows: _defaultShadows,
          ),
        );
        break;

      case TimestampDesign.n2_1:
        final dateStr = TimestampLocaleFormatter.formatLegacyN2_1Date(time);
        final timeStr = TimestampLocaleFormatter.format12hTime(time, padHour: false, localizePeriod: true);
        stampWidget = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              dateStr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cafe24OnePrettyNight',
                fontSize: fontSize * 0.36,
                color: Colors.white,
                height: 1.15,
                shadows: _defaultShadows,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeStr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cafe24OnePrettyNight',
                fontSize: fontSize,
                color: Colors.white,
                height: 1.0,
                shadows: _defaultShadows,
              ),
            ),
          ],
        );
        break;

      case TimestampDesign.n2_2:
        final dateStr = TimestampLocaleFormatter.formatWordDate(time, padMonthDay: true);
        final timeStr = TimestampLocaleFormatter.format12hTime(time, padHour: true, localizePeriod: true);
        stampWidget = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              dateStr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NanumAmsterdam',
                fontSize: fontSize * 0.52,
                color: Colors.white,
                height: 1.15,
                shadows: _defaultShadows,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeStr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NanumAmsterdam',
                fontSize: fontSize,
                color: Colors.white,
                height: 1.0,
                shadows: _defaultShadows,
              ),
            ),
          ],
        );
        break;
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: stampWidget,
        ),
      ),
    );
  }

  Widget _buildFloatingControls(Color accentColor) {
    final bool canAlign = _currentDesign != TimestampDesign.frame_1 &&
        _currentDesign != TimestampDesign.none;
    final bool canResize = _currentDesign != TimestampDesign.none;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 위치 변경 버튼 (frame_1 및 none 은 레이아웃 고정/없음으로 비활성화)
        GestureDetector(
          onTap: canAlign ? _cycleAlignment : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: canAlign
                  ? Colors.black.withOpacity(0.65)
                  : Colors.black.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: canAlign ? Colors.white30 : Colors.white12,
                width: 1.2,
              ),
              boxShadow: canAlign
                  ? const [
                      BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.open_with_rounded,
              color: canAlign ? Colors.white : Colors.white24,
              size: 21,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. 폰트 크기 변경 버튼 (none 일 때는 비활성화)
        GestureDetector(
          onTap: canResize ? _cycleFontSize : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: canResize
                  ? Colors.black.withOpacity(0.65)
                  : Colors.black.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: canResize ? Colors.white30 : Colors.white12,
                width: 1.2,
              ),
              boxShadow: canResize
                  ? const [
                      BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${_fontSizeIndex + 1}A',
                style: TextStyle(
                  color: canResize ? Colors.white : Colors.white24,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatioButtons(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: CameraAspectRatio.values.map((r) {
          final isSelected = _aspectRatio == r;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _aspectRatio = r);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.35) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: accentColor, width: 1.2)
                    : null,
              ),
              child: Text(
                r.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimestampPicker(Color accentColor) {
    final designs = [
      TimestampDesign.none, // 1. 적용안함 (디폴트)
      TimestampDesign.n1_1, // 2. 기본 1 (RubberNippleFactory)
      TimestampDesign.n1_2, // 3. 기본 2 (NixieOne)
      TimestampDesign.n2_1, // 4. 기본 3 (Cafe24OnePrettyNight)
      TimestampDesign.n2_2, // 5. 기본 4 (NanumAmsterdam)
      TimestampDesign.frame_1, // 6. timenow frame_1 (뷰파인더 프레임)
    ];

    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: designs.length,
        itemBuilder: (context, index) {
          final d = designs[index];
          final isSelected = _currentDesign == d;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _currentDesign = d;
                if (d == TimestampDesign.frame_1) {
                  _currentAlignment = Alignment.center;
                }
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.18) : const Color(0xFF13151B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white24,
                  width: isSelected ? 2.0 : 0.8,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: _buildThumbnailContent(d),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnailContent(TimestampDesign design) {
    final now = DateTime(_now.year, _now.month, _now.day, 12, 27);

    switch (design) {
      case TimestampDesign.none:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, color: Colors.white70, size: 22),
              SizedBox(height: 4),
              Text(
                '적용안함',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      case TimestampDesign.n1_1:
        final str = '${TimestampLocaleFormatter.formatNumericDate(now, sep: '.')} ${TimestampLocaleFormatter.format12hTime(now, padHour: true, localizePeriod: false)}';
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                str,
                style: const TextStyle(
                  fontFamily: 'RubberNippleFactory',
                  fontSize: 10.5,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        );

      case TimestampDesign.n1_2:
        final str = '${TimestampLocaleFormatter.formatNumericDate(now, sep: '/')} ${TimestampLocaleFormatter.format12hTime(now, padHour: true, localizePeriod: false)}';
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                str,
                style: const TextStyle(
                  fontFamily: 'NixieOne',
                  fontSize: 10.5,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        );

      case TimestampDesign.n2_1:
        final dateStr = TimestampLocaleFormatter.formatLegacyN2_1Date(now);
        final timeStr = TimestampLocaleFormatter.format12hTime(now, padHour: false, localizePeriod: true);
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'Cafe24OnePrettyNight',
                    fontSize: 7.5,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: 'Cafe24OnePrettyNight',
                    fontSize: 15.0,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );

      case TimestampDesign.n2_2:
        final dateStr = TimestampLocaleFormatter.formatWordDate(now, padMonthDay: true);
        final timeStr = TimestampLocaleFormatter.format12hTime(now, padHour: true, localizePeriod: true);
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'NanumAmsterdam',
                    fontSize: 8.5,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: 'NanumAmsterdam',
                    fontSize: 14.5,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );

      case TimestampDesign.frame_1:
        return Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/timestamp/frame/frame_1.png',
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 6,
              top: 6,
              child: Image.asset(
                'assets/timestamp/frame/rec_1.png',
                width: 18,
                fit: BoxFit.contain,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '12:27',
                  style: const TextStyle(
                    fontFamily: 'RubberNippleFactory',
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildShutterBar(Color accentColor) {
    return Center(
      child: GestureDetector(
        onTap: _onShutterPressed,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accentColor, width: 4.5),
            color: Colors.black.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.35),
                blurRadius: 16,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: _isCapturing
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

/// timenow 공식 3분할 세로 스트레치 렌더러
/// 상단 1/3 및 하단 1/3 은 가로 기준 정비율로 유지하고 가운데 1/3 만 늘려
/// 1:1, 4:5, 9:16 어떤 비율에서도 코너 브라켓 왜곡 없이 프레임을 완벽하게 피팅합니다.
class Frame1WidgetPainter extends CustomPainter {
  final ui.Image? frameImage;
  final ui.Image? recImage;

  Frame1WidgetPainter({required this.frameImage, required this.recImage});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 390.0;
    final frameInset = 16.0 * scale;
    final dst = Rect.fromLTWH(
      frameInset,
      frameInset,
      size.width - frameInset * 2,
      size.height - frameInset * 2,
    );

    if (frameImage != null) {
      drawThreeSlice(canvas, frameImage!, dst);
    }

    if (recImage != null) {
      final recW = 44.0 * scale;
      final recH = recW * (recImage!.height / recImage!.width);
      final recRect = Rect.fromLTWH(dst.left + 16.0 * scale, dst.top + 14.0 * scale, recW, recH);
      final srcRect = Rect.fromLTWH(0, 0, recImage!.width.toDouble(), recImage!.height.toDouble());
      canvas.drawImageRect(recImage!, srcRect, recRect, Paint()..filterQuality = FilterQuality.high);
    }
  }

  static void drawThreeSlice(Canvas canvas, ui.Image image, Rect dst) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final f = dst.width / iw;
    final band = ih / 3.0;
    final topH = math.min(band * f, dst.height / 2.0);
    final bottomH = math.min(band * f, dst.height / 2.0);
    final midH = math.max(0.0, dst.height - topH - bottomH);
    final p = Paint()..filterQuality = FilterQuality.high;

    // 상단 1/3 (코너 브라켓 정비율)
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, iw, band),
      Rect.fromLTWH(dst.left, dst.top, dst.width, topH),
      p,
    );
    // 가운데 1/3 (세로 연장)
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, band, iw, band),
      Rect.fromLTWH(dst.left, dst.top + topH, dst.width, midH),
      p,
    );
    // 하단 1/3 (코너 브라켓 정비율)
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, ih - band, iw, band),
      Rect.fromLTWH(dst.left, dst.bottom - bottomH, dst.width, bottomH),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant Frame1WidgetPainter oldDelegate) {
    return oldDelegate.frameImage != frameImage || oldDelegate.recImage != recImage;
  }
}
