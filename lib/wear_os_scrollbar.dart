/// A custom scrollbar tailored for Wear OS applications.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'wear_os_scrollbar_platform_interface.dart';

export 'wear_os_expressive_item.dart';
export 'wear_os_scrollbar_platform_interface.dart' show WearOsRotaryHapticType;

/// Specifies the type of haptic feedback to be played when scrolling.
enum WearOsHapticFeedback {
  /// Native subtle rotary crown tick (corresponds to Wear OS ROTARY_SCROLL_TICK).
  ///
  /// Recommended for Wear OS devices (such as Pixel Watch 3) to provide crisp,
  /// tactile detent clicks without harsh motor vibration.
  rotaryTick,

  /// Vibrate.
  vibrate,

  /// Light impact.
  lightImpact,

  /// Medium impact.
  mediumImpact,

  /// Heavy impact.
  heavyImpact,

  /// Selection click.
  selectionClick,

  /// No haptic feedback.
  none,
}

/// A scrollbar indicator specifically designed for circular screens like those found on Wear OS devices.
class WearOsScrollbar extends StatefulWidget {
  /// Creates a [WearOsScrollbar].
  const WearOsScrollbar({
    required this.controller,
    required this.child,
    this.hapticScrollThreshold = 24.0,
    this.hapticFeedback = WearOsHapticFeedback.rotaryTick,
    this.enableLimitHaptic = true,
    this.rotarySensitivity = 0.4,
    this.enableSmoothScroll = true,
    this.indicatorColor = Colors.white,
    this.backgroundColor = Colors.white30,
    this.strokeWidth = 6.0,
    this.marginRight = 0.0,
    this.totalAngle = 30.0,
    this.hideIndicator = false,
    super.key,
  }) : assert(
         totalAngle >= 10 && totalAngle <= 90,
         'totalAngle must be between 10 and 90 degrees',
       ),
       assert(
         marginRight >= 0 && marginRight <= 50,
         'marginRight must be between 0 and 50',
       ),
       assert(
         strokeWidth >= 1 && strokeWidth <= 10,
         'strokeWidth must be between 1 and 10',
       ),
       assert(
         rotarySensitivity > 0 && rotarySensitivity <= 2.0,
         'rotarySensitivity must be between 0 and 2.0',
       );

  /// The scroll controller of the scrollable widget.
  final ScrollController controller;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The threshold distance that triggers haptic feedback.
  final double hapticScrollThreshold;

  /// The type of haptic feedback to occur during scrolling.
  final WearOsHapticFeedback hapticFeedback;

  /// Whether to trigger limit haptic feedback when scrolling hits the boundary.
  final bool enableLimitHaptic;

  /// Sensitivity multiplier applied to rotary input delta.
  ///
  /// Defaults to `0.4` to match the native scroll speed of Wear OS settings.
  final double rotarySensitivity;

  /// Whether to smoothly interpolate rotary scrolling with natural decay physics.
  final bool enableSmoothScroll;

  /// The color of the active scroll indicator.
  final Color indicatorColor;

  /// The color of the scroll track background.
  final Color backgroundColor;

  /// The width of the scrollbar stroke.
  final double strokeWidth;

  /// The right margin of the scrollbar.
  final double marginRight;

  /// The total angle in degrees that the scroll track occupies.
  final double totalAngle;

  /// Whether to hide the visual scroll indicator.
  final bool hideIndicator;

  @override
  State<WearOsScrollbar> createState() => _WearOsScrollbarState();
}

class _WearOsScrollbarState extends State<WearOsScrollbar>
    with SingleTickerProviderStateMixin {
  StreamSubscription<dynamic>? _rotarySubscription;
  double _accumulatedHapticScroll = 0;

  double _scrollPosition = 0;
  double _maxScrollExtent = 0;
  double _viewportDimension = 1;

  bool _isVisible = false;
  Timer? _hideTimer;

  late final Ticker _ticker;
  double _targetOffset = 0;
  Duration? _lastTickTime;
  bool _isRotaryDrivingScroll = false;
  DateTime _lastLimitHapticTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMetrics();
      if (_maxScrollExtent > 0) {
        _showIndicator();
      }
    });

    _rotarySubscription = WearOsScrollbarPlatform.instance.rotaryScrollEvents
        .listen(_onRotaryEvent);
  }

  void _onRotaryEvent(double event) {
    if (!widget.controller.hasClients) return;

    final position = widget.controller.position;
    final minScroll = position.minScrollExtent;
    final maxScroll = position.maxScrollExtent;

    if (maxScroll <= minScroll) {
      if (widget.enableLimitHaptic) {
        _triggerLimitHaptic();
      }
      return;
    }

    final scrollDelta = event * widget.rotarySensitivity;

    if (!widget.enableSmoothScroll) {
      final newOffset = (widget.controller.offset + scrollDelta).clamp(
        minScroll,
        maxScroll,
      );
      if (newOffset != widget.controller.offset) {
        widget.controller.jumpTo(newOffset);
        _checkHaptic(scrollDelta.abs());
      } else if (widget.enableLimitHaptic) {
        _triggerLimitHaptic();
      }
      return;
    }

    if (!_isRotaryDrivingScroll) {
      _targetOffset = widget.controller.offset;
    }

    final prevTarget = _targetOffset;
    _targetOffset = (_targetOffset + scrollDelta).clamp(minScroll, maxScroll);

    if (_targetOffset == prevTarget && scrollDelta != 0) {
      if (widget.enableLimitHaptic) {
        _triggerLimitHaptic();
      }
    } else {
      _checkHaptic(scrollDelta.abs());
    }

    if (!_ticker.isActive) {
      _lastTickTime = null;
      _isRotaryDrivingScroll = true;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!widget.controller.hasClients) {
      _stopTicker();
      return;
    }

    if (_lastTickTime == null) {
      _lastTickTime = elapsed;
      return;
    }

    final dt = (elapsed - _lastTickTime!).inMicroseconds / 1000000.0;
    _lastTickTime = elapsed;

    if (dt <= 0) return;

    final currentOffset = widget.controller.offset;
    final distance = _targetOffset - currentOffset;

    if (distance.abs() < 0.5) {
      widget.controller.jumpTo(_targetOffset);
      _stopTicker();
      return;
    }

    // Exponential decay interpolation for silky smooth deceleration.
    const decayRate = 18.0;
    final factor = (1.0 - exp(-decayRate * dt)).clamp(0.0, 1.0);
    final newOffset = currentOffset + distance * factor;

    widget.controller.jumpTo(newOffset);
  }

  void _stopTicker() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _lastTickTime = null;
    _isRotaryDrivingScroll = false;
  }

  void _triggerLimitHaptic() {
    final now = DateTime.now();
    if (now.difference(_lastLimitHapticTime).inMilliseconds >= 200) {
      _lastLimitHapticTime = now;
      if (widget.hapticFeedback == WearOsHapticFeedback.rotaryTick) {
        WearOsScrollbarPlatform.instance.performRotaryHaptic(
          type: WearOsRotaryHapticType.limit,
        );
      } else if (widget.hapticFeedback != WearOsHapticFeedback.none) {
        _performHapticFeedback();
      }
    }
  }

  void _checkHaptic(double delta) {
    _accumulatedHapticScroll += delta;
    if (_accumulatedHapticScroll >= widget.hapticScrollThreshold) {
      _accumulatedHapticScroll = 0.0;
      _performHapticFeedback();
    }
  }

  void _performHapticFeedback() {
    switch (widget.hapticFeedback) {
      case WearOsHapticFeedback.rotaryTick:
        WearOsScrollbarPlatform.instance.performRotaryHaptic(
          type: WearOsRotaryHapticType.tick,
        );
        break;
      case WearOsHapticFeedback.vibrate:
        HapticFeedback.vibrate();
        break;
      case WearOsHapticFeedback.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case WearOsHapticFeedback.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case WearOsHapticFeedback.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case WearOsHapticFeedback.selectionClick:
        HapticFeedback.selectionClick();
        break;
      case WearOsHapticFeedback.none:
        break;
    }
  }

  @override
  void didUpdateWidget(covariant WearOsScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _stopTicker();
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
      _updateMetrics();
    }
  }

  @override
  void dispose() {
    unawaited(_rotarySubscription?.cancel());
    widget.controller.removeListener(_onScroll);
    _hideTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isRotaryDrivingScroll && widget.controller.hasClients) {
      _targetOffset = widget.controller.offset;
    }
    _updateMetrics();
    _showIndicator();
  }

  void _updateMetrics() {
    if (widget.controller.hasClients) {
      final position = widget.controller.position;
      if (position.maxScrollExtent != _maxScrollExtent ||
          position.pixels != _scrollPosition ||
          position.viewportDimension != _viewportDimension) {
        setState(() {
          _scrollPosition = position.pixels;
          _maxScrollExtent = position.maxScrollExtent;
          _viewportDimension = position.viewportDimension;
        });
      }
    }
  }

  void _showIndicator() {
    if (widget.hideIndicator) return;
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isScrollable = _maxScrollExtent > 0;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _stopTicker();
              if (widget.controller.hasClients) {
                _targetOffset = widget.controller.offset;
              }
            }
            return false;
          },
          child: widget.child,
        ),
        if (isScrollable && !widget.hideIndicator)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: CustomPaint(
                  painter: _CircularScrollIndicatorPainter(
                    scrollPosition: _scrollPosition,
                    maxScrollExtent: _maxScrollExtent,
                    viewportDimension: _viewportDimension,
                    indicatorColor: widget.indicatorColor,
                    backgroundColor: widget.backgroundColor,
                    strokeWidth: widget.strokeWidth,
                    marginRight: widget.marginRight,
                    totalAngle: widget.totalAngle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CircularScrollIndicatorPainter extends CustomPainter {
  _CircularScrollIndicatorPainter({
    required this.scrollPosition,
    required this.maxScrollExtent,
    required this.viewportDimension,
    required this.indicatorColor,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.marginRight,
    required this.totalAngle,
  });

  final double scrollPosition;
  final double maxScrollExtent;
  final double viewportDimension;
  final Color indicatorColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double marginRight;
  final double totalAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = max(
      0.0,
      min(size.width / 2, size.height / 2) - strokeWidth / 2 - marginRight,
    );

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final indicatorPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = totalAngle * pi / 180;
    final startAngle = -sweepAngle / 2;

    final totalContentDimension = maxScrollExtent + viewportDimension;
    if (totalContentDimension <= 0) return;

    var indicatorSweepAngle =
        sweepAngle * (viewportDimension / totalContentDimension);

    indicatorSweepAngle = indicatorSweepAngle.clamp(
      sweepAngle * 0.15,
      sweepAngle,
    );

    final scrollRatio = maxScrollExtent > 0
        ? (scrollPosition / maxScrollExtent).clamp(0.0, 1.0)
        : 0.0;

    final movableSweepAngle = sweepAngle - indicatorSweepAngle;
    final indicatorStartAngle = startAngle + (movableSweepAngle * scrollRatio);

    final gapSize = strokeWidth / 2;
    final gapAngle = radius > 0 ? (strokeWidth + gapSize) / radius : 0;

    final topTrackSweep = (indicatorStartAngle - gapAngle) - startAngle;
    if (topTrackSweep > 0 && radius > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        topTrackSweep,
        false,
        backgroundPaint,
      );
    }

    if (radius > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        indicatorStartAngle,
        indicatorSweepAngle,
        false,
        indicatorPaint,
      );
    }

    final bottomTrackStartAngle =
        indicatorStartAngle + indicatorSweepAngle + gapAngle;
    final bottomTrackSweep = (startAngle + sweepAngle) - bottomTrackStartAngle;
    if (bottomTrackSweep > 0 && radius > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        bottomTrackStartAngle,
        bottomTrackSweep,
        false,
        backgroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularScrollIndicatorPainter oldDelegate) {
    return oldDelegate.scrollPosition != scrollPosition ||
        oldDelegate.maxScrollExtent != maxScrollExtent ||
        oldDelegate.viewportDimension != viewportDimension ||
        oldDelegate.indicatorColor != indicatorColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.marginRight != marginRight ||
        oldDelegate.totalAngle != totalAngle;
  }
}
