import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_os_scrollbar/wear_os_expressive_item.dart';

void main() {
  late ScrollController scrollController;

  setUp(() {
    scrollController = ScrollController();
  });

  tearDown(() {
    scrollController.dispose();
  });

  Widget buildTestWidget({
    double minScale = 0.5,
    double maxScale = 1.0,
    int itemCount = 20,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: ListView.builder(
            controller: scrollController,
            itemCount: itemCount,
            itemExtent: 50,
            itemBuilder: (context, index) {
              return WearOsExpressiveItem(
                scrollController: scrollController,
                minScale: minScale,
                maxScale: maxScale,
                child: Center(child: Text('Item $index')),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('WearOsExpressiveItem renders children', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
  });

  testWidgets('WearOsExpressiveItem applies scale based on position', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(minScale: 0.5, maxScale: 1.0));
    await tester.pumpAndSettle();

    // The list height is 300, item extent is 50.
    // Item 0 is at the top (edge).
    // Item 3 is exactly at the center (y=150, which is exactly center for a 50 height item).

    // Find all Transforms used by WearOsExpressiveItem
    final transforms = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(WearOsExpressiveItem),
            matching: find.byType(Transform),
          ),
        )
        .toList();

    expect(transforms.isNotEmpty, isTrue);

    // Get the transform matrix of the first item (Item 0) which is at the top edge.
    // It should be scaled down because it's far from the center.
    final firstItemTransform = transforms.first.transform;
    final scaleFirstItem = firstItemTransform.storage[0];

    // Get the transform matrix of an item near the center (Item 2 or 3)
    final centerItemTransform = transforms[2].transform;
    final scaleCenterItem = centerItemTransform.storage[0];

    // The scale of the item at the center should be larger than the item at the edge.
    expect(scaleCenterItem > scaleFirstItem, isTrue);
    scrollController.jumpTo(100);
    await tester.pumpAndSettle();

    // Get the new transform of the center item which has now moved up
    final updatedTransforms = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(WearOsExpressiveItem),
            matching: find.byType(Transform),
          ),
        )
        .toList();

    final movedItemTransform = updatedTransforms[0].transform;
    final scaleMovedItem = movedItemTransform.storage[0];

    // Scale should have changed after scrolling
    expect(scaleMovedItem, isNot(equals(scaleCenterItem)));
  });

  testWidgets('WearOsExpressiveItem handles unattached controller gracefully', (
    WidgetTester tester,
  ) async {
    final unattachedController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WearOsExpressiveItem(
            scrollController: unattachedController,
            child: const Text('Standalone Item'),
          ),
        ),
      ),
    );

    expect(find.text('Standalone Item'), findsOneWidget);

    final transforms = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(WearOsExpressiveItem),
            matching: find.byType(Transform),
          ),
        )
        .toList();

    expect(transforms.length, 1);

    // Should default to maxScale (1.0) when not in a viewport / no clients
    final transform = transforms.first.transform;
    expect(transform.storage[0], 1.0);

    unattachedController.dispose();
  });
}
