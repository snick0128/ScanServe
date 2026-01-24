import 'package:flutter/widgets.dart';
import 'dart:math';
import 'dart:ui' as ui;

class ScreenScale {
  static double? _screenWidth;
  static double? _screenHeight;

  static bool? _isMobileOverride;
  static bool get isMobile => _isMobileOverride ?? screenWidth < 900;

  static const double refMobileW = 375;
  static const double refMobileH = 812;
  static const double refWebW = 1440;
  static const double refWebH = 900;

  static double get screenWidth {
    if (_screenWidth == null) {
      final view = ui.PlatformDispatcher.instance.implicitView;
      _screenWidth = view != null
          ? view.physicalSize.width / view.devicePixelRatio
          : refWebW;
    }
    return _screenWidth!;
  }

  static double get screenHeight {
    if (_screenHeight == null) {
      final view = ui.PlatformDispatcher.instance.implicitView;
      _screenHeight = view != null
          ? view.physicalSize.height / view.devicePixelRatio
          : refWebH;
    }
    return _screenHeight!;
  }

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    _screenWidth = mq.size.width;
    _screenHeight = mq.size.height;
  }

  static double get _baseScale {
    final shortest = min(screenWidth, screenHeight);
    final ref = isMobile ? refMobileW : refWebW;
    return (shortest / ref).clamp(0.85, 1.25);
  }

  static double scaleW(double v) => v * _baseScale;
  static double scaleH(double v) => v * _baseScale;

  static double scaleText(double v) {
    final factor = isMobile
        ? _baseScale.clamp(0.9, 1.15)
        : _baseScale.clamp(0.95, 1.2);
    return v * factor;
  }

  static double scaleRadius(double v) {
    return v * _baseScale.clamp(0.9, 1.1);
  }
}

extension ScaleExtension on num {
  double get w => ScreenScale.scaleW(toDouble());
  double get h => ScreenScale.scaleH(toDouble());
  double get sp => ScreenScale.scaleText(toDouble());
  double get r => ScreenScale.scaleRadius(toDouble());
}
