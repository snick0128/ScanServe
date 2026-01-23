import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:js' as js;

class HapticHelper {
  static void light() {
    if (kIsWeb) {
      _webVibrate(10);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  static void medium() {
    if (kIsWeb) {
      _webVibrate(20);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static void _webVibrate(int ms) {
    try {
      if (js.context.hasProperty('navigator') && 
          js.context['navigator'].hasProperty('vibrate')) {
        js.context['navigator'].callMethod('vibrate', [ms]);
      }
    } catch (e) {
      // Ignore if not supported
    }
  }
}
