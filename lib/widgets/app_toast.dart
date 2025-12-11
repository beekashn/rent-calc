import 'dart:ui';
import 'package:flutter/material.dart';

enum AppToastStyle { android, cupertino }

enum AppToastPosition { top, bottom }

class AppToast {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    AppToastStyle? style,
    AppToastPosition position = AppToastPosition.bottom,
    Duration duration = const Duration(seconds: 2),
    bool isError = false,
  }) {
    // Remove previous toast if any
    _entry?.remove();
    _entry = null;

    // Use maybeOf so the null-check makes sense
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // Default style based on platform if not provided
    final platform = Theme.of(context).platform;
    final resolvedStyle =
        style ??
        (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
            ? AppToastStyle.cupertino
            : AppToastStyle.android);

    _entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        style: resolvedStyle,
        position: position,
        duration: duration,
        isError: isError,
        onDismissed: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );

    overlay.insert(_entry!);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final AppToastStyle style;
  final AppToastPosition position;
  final Duration duration;
  final bool isError;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.message,
    required this.style,
    required this.position,
    required this.duration,
    required this.isError,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    final beginOffset = widget.position == AppToastPosition.top
        ? const Offset(0, -0.2)
        : const Offset(0, 0.2);

    _offset = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Auto hide after duration
    Future.delayed(widget.duration, () {
      if (!mounted) return;
      _controller.reverse();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Alignment get _alignment => widget.position == AppToastPosition.top
      ? Alignment.topCenter
      : Alignment.bottomCenter;

  EdgeInsets get _padding => widget.position == AppToastPosition.top
      ? const EdgeInsets.fromLTRB(16, 40, 16, 0)
      : const EdgeInsets.fromLTRB(16, 0, 16, 40);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget child;
    switch (widget.style) {
      case AppToastStyle.android:
        child = _buildAndroidToast(theme, isDark);
        break;
      case AppToastStyle.cupertino:
        child = _buildCupertinoToast(theme, isDark);
        break;
    }

    return IgnorePointer(
      ignoring: true, // touches go through
      child: SafeArea(
        child: Align(
          alignment: _alignment,
          child: Padding(
            padding: _padding,
            child: SlideTransition(
              position: _offset,
              child: FadeTransition(opacity: _opacity, child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidToast(ThemeData theme, bool isDark) {
    final bgColor = widget.isError
        ? const Color(0xFFE53935)
        : (isDark ? const Color(0xFF212121) : const Color(0xFF323232));

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          widget.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoToast(ThemeData theme, bool isDark) {
    final bgColor = widget.isError
        ? (isDark
              ? const Color(0xFFB00020).withValues(alpha: 0.85)
              : const Color(0xFFFF5252).withValues(alpha: 0.85))
        : (isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.95));

    final textColor = widget.isError
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Text(
            widget.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
