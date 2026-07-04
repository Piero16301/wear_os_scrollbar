import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A wrapper widget that applies a scaling effect to its child based on its
/// vertical position within a scrollable area, following Material 3 Expressive
/// design guidelines for Wear OS.
class WearOsExpressiveItem extends StatefulWidget {
  /// Creates a [WearOsExpressiveItem].
  const WearOsExpressiveItem({
    required this.scrollController,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 1.0,
    super.key,
  });

  /// The scroll controller of the scrollable widget this item belongs to.
  final ScrollController scrollController;

  /// The widget to be scaled.
  final Widget child;

  /// The minimum scale applied to the item when it is at the edges of the viewport.
  final double minScale;

  /// The maximum scale applied to the item when it is at the center of the viewport.
  final double maxScale;

  @override
  State<WearOsExpressiveItem> createState() => _WearOsExpressiveItemState();
}

class _WearOsExpressiveItemState extends State<WearOsExpressiveItem> {
  @override
  void initState() {
    super.initState();
    // Force a rebuild after the first frame so that the renderObject is
    // available and the initial scale can be calculated correctly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.scrollController,
      builder: (context, child) {
        double scale = widget.maxScale;

        final renderObject = this.context.findRenderObject();
        if (renderObject is RenderBox && widget.scrollController.hasClients) {
          final viewport = RenderAbstractViewport.maybeOf(renderObject);

          if (viewport != null) {
            final viewportDimension =
                widget.scrollController.position.viewportDimension;

            // getOffsetToReveal with alignment 0.5 gives us the scroll offset
            // at which this item is perfectly centered in the viewport.
            final offsetToReveal = viewport.getOffsetToReveal(
              renderObject,
              0.5,
            );

            // Distance from the current scroll offset to the offset where the item is perfectly centered.
            final currentScrollOffset = widget.scrollController.position.pixels;
            final distanceToCenter =
                (offsetToReveal.offset - currentScrollOffset).abs();

            // Normalize the distance based on half the viewport dimension.
            // A distance equal to half the viewport means the item's center is exactly at the edge.
            final maxDistance = viewportDimension / 2;

            // Calculate a factor from 0.0 (at center) to 1.0 (at or beyond edge)
            final normalizedDistance = (distanceToCenter / maxDistance).clamp(
              0.0,
              1.0,
            );

            // Interpolate scale based on the normalized distance.
            final curvedDistance = Curves.easeIn.transform(normalizedDistance);

            scale =
                widget.maxScale -
                (widget.maxScale - widget.minScale) * curvedDistance;
          }
        }

        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
