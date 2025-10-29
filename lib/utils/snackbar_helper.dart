import 'dart:async';
import 'package:flutter/material.dart';

class SnackbarHelper {
  static OverlayEntry? _currentOverlay;
  static Timer? _timer;
  static AnimationController? _animationController;
  static Completer<void>? _dismissCompleter;

  static Future<void> showTopSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    await _dismissCurrent();

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;

    _animationController = AnimationController(
      vsync: overlay,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _dismissCompleter = Completer<void>();

    _currentOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).viewPadding.top + 12,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _animationController!,
            builder: (context, child) {
              final offset =
                  Tween<Offset>(
                    begin: const Offset(0, -1.2),
                    end: Offset.zero,
                  ).evaluate(
                    CurvedAnimation(
                      parent: _animationController!,
                      curve: Curves.easeOutBack,
                      reverseCurve: Curves.easeInOut,
                    ),
                  );

              return Transform.translate(
                offset: offset * 100,
                child: Opacity(
                  opacity: _animationController!.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: IgnorePointer(
                ignoring: true,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: iconColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              height: 1.3,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_currentOverlay!);
    _animationController!.forward();

    _timer = Timer(duration, () async {
      await _animationController?.reverse();
      await _dismissCurrent();
    });

    return _dismissCompleter!.future;
  }

  static Future<void> _dismissCurrent() async {
    if (!(_dismissCompleter?.isCompleted ?? true)) {
      _dismissCompleter?.complete();
    }

    _timer?.cancel();
    _timer = null;

    if (_animationController != null) {
      if (_animationController!.status == AnimationStatus.forward ||
          _animationController!.status == AnimationStatus.completed) {
        await _animationController?.reverse();
      }
      _animationController?.dispose();
      _animationController = null;
    }

    _currentOverlay?.remove();
    _currentOverlay = null;

    if (!(_dismissCompleter?.isCompleted ?? true)) {
      _dismissCompleter?.complete();
    }
    _dismissCompleter = null;
  }
}
