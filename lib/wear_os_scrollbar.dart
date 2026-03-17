import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'wear_os_scrollbar_platform_interface.dart';

enum WearOsHapticFeedback {
  vibrate,
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
}

class WearOsScrollbar extends StatefulWidget {
  const WearOsScrollbar({
    required this.controller,
    required this.child,
    this.hapticScrollThreshold = 30.0,
    this.hapticFeedback = WearOsHapticFeedback.lightImpact,
    this.indicatorColor = Colors.white,
    this.backgroundColor = Colors.white30,
    this.strokeWidth = 6.0,
    this.marginRight = 0.0,
    this.totalAngle = 30.0,
    super.key,
  })  : assert(totalAngle >= 10 && totalAngle <= 90,
            'totalAngle must be between 10 and 90 degrees'),
        assert(marginRight >= 0 && marginRight <= 50,
            'marginRight must be between 0 and 50'),
        assert(strokeWidth >= 1 && strokeWidth <= 10,
            'strokeWidth must be between 1 and 10');

  final ScrollController controller;
  final Widget child;
  final double hapticScrollThreshold;
  final WearOsHapticFeedback hapticFeedback;
  final Color indicatorColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double marginRight;
  final double totalAngle;

  @override
  State<WearOsScrollbar> createState() => _WearOsScrollbarState();
}

class _WearOsScrollbarState extends State<WearOsScrollbar> {
  StreamSubscription<dynamic>? _rotarySubscription;
  double _accumulatedHapticScroll = 0;

  double _scrollPosition = 0;
  double _maxScrollExtent = 0;
  double _viewportDimension = 1;

  bool _isVisible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMetrics();
      if (_maxScrollExtent > 0) {
        _showIndicator();
      }
    });

    _rotarySubscription = WearOsScrollbarPlatform.instance.rotaryScrollEvents
        .listen((double event) {
      final scrollAmount = event;
      final newOffset = widget.controller.offset + scrollAmount;

      final maxScrollExtent = widget.controller.position.maxScrollExtent;
      final minScrollExtent = widget.controller.position.minScrollExtent;
      final clampedOffset = newOffset.clamp(minScrollExtent, maxScrollExtent);

      if (clampedOffset != widget.controller.offset) {
        widget.controller.jumpTo(clampedOffset);

        _accumulatedHapticScroll += scrollAmount;
        if (_accumulatedHapticScroll.abs() >= widget.hapticScrollThreshold) {
          _performHapticFeedback();
          _accumulatedHapticScroll = 0.0;
        }
      }
    });
  }

  void _performHapticFeedback() {
    switch (widget.hapticFeedback) {
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
    }
  }

  @override
  void didUpdateWidget(covariant WearOsScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
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
    super.dispose();
  }

  void _onScroll() {
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
        widget.child,
        if (isScrollable)
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
    final radius = max(0.0,
        min(size.width / 2, size.height / 2) - strokeWidth / 2 - marginRight);

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

    indicatorSweepAngle =
        indicatorSweepAngle.clamp(sweepAngle * 0.15, sweepAngle);

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
