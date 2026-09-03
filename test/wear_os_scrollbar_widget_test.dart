import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWearOsScrollbarPlatform
    with MockPlatformInterfaceMixin
    implements WearOsScrollbarPlatform {
  final StreamController<double> _controller =
      StreamController<double>.broadcast();
  final List<WearOsRotaryHapticType> hapticCalls = [];

  @override
  Stream<double> get rotaryScrollEvents => _controller.stream;

  @override
  Future<void> performRotaryHaptic({
    WearOsRotaryHapticType type = WearOsRotaryHapticType.tick,
  }) async {
    hapticCalls.add(type);
  }

  void emitScrollEvent(double delta) {
    _controller.add(delta);
  }
}

void main() {
  late MockWearOsScrollbarPlatform mockPlatform;
  late ScrollController scrollController;

  setUp(() {
    mockPlatform = MockWearOsScrollbarPlatform();
    WearOsScrollbarPlatform.instance = mockPlatform;
    scrollController = ScrollController();
  });

  tearDown(() {
    scrollController.dispose();
  });

  testWidgets('WearOsScrollbar renders child', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WearOsScrollbar(
            controller: scrollController,
            child: const Text('Test Child'),
          ),
        ),
      ),
    );

    expect(find.text('Test Child'), findsOneWidget);
  });

  testWidgets('WearOsScrollbar shows indicator on scroll', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: WearOsScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (context, index) =>
                    ListTile(title: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );

    scrollController.jumpTo(50);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(AnimatedOpacity),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 2000));
  });

  testWidgets('WearOsScrollbar responds to rotary scroll with smooth decay', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: WearOsScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (context, index) =>
                    ListTile(title: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );

    expect(scrollController.offset, 0.0);

    mockPlatform.emitScrollEvent(100.0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(scrollController.offset, greaterThan(0.0));

    await tester.pumpAndSettle();
    expect(
      scrollController.offset,
      40.0,
    ); // 100.0 * 0.4 default rotarySensitivity
    expect(mockPlatform.hapticCalls, contains(WearOsRotaryHapticType.tick));
  });

  testWidgets('WearOsScrollbar responds to rotary scroll with instant mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: WearOsScrollbar(
              controller: scrollController,
              enableSmoothScroll: false,
              rotarySensitivity: 1.0,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (context, index) =>
                    ListTile(title: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );

    expect(scrollController.offset, 0.0);

    mockPlatform.emitScrollEvent(100.0);
    await tester.pump();

    expect(scrollController.offset, 100.0);

    // Hit top boundary in instant mode to trigger boundary limit branch
    scrollController.jumpTo(0.0);
    mockPlatform.emitScrollEvent(-50.0);
    await tester.pump();
  });

  testWidgets('WearOsScrollbar triggers limit haptic with rotary feedback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: WearOsScrollbar(
              controller: scrollController,
              hapticFeedback: WearOsHapticFeedback.rotaryTick,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (context, index) =>
                    ListTile(title: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );

    // Scroll up when already at 0.0 with rotaryTick
    mockPlatform.emitScrollEvent(-50.0);
    await tester.pump();

    expect(mockPlatform.hapticCalls, contains(WearOsRotaryHapticType.limit));
  });

  testWidgets(
    'WearOsScrollbar triggers limit haptic with non-rotary feedback',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: WearOsScrollbar(
                controller: scrollController,
                hapticFeedback: WearOsHapticFeedback.lightImpact,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 100,
                  itemBuilder: (context, index) =>
                      ListTile(title: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );

      mockPlatform.emitScrollEvent(-50.0);
      await tester.pump();
    },
  );

  testWidgets(
    'WearOsScrollbar stops ticker on touch drag scroll notification',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: WearOsScrollbar(
                controller: scrollController,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 100,
                  itemBuilder: (context, index) =>
                      ListTile(title: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );

      // Start rotary scroll to activate ticker
      mockPlatform.emitScrollEvent(100.0);
      await tester.pump();

      // Perform a touch drag
      await tester.drag(find.byType(ListView), const Offset(0, -30));
      await tester.pump();
    },
  );

  testWidgets('WearOsScrollbar ticker stops when controller loses clients', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: WearOsScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (context, index) =>
                    ListTile(title: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );

    // Start rotary scroll
    mockPlatform.emitScrollEvent(100.0);
    await tester.pump(); // ticker starts

    // Replace child with a widget that doesn't use scrollController
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: WearOsScrollbar(
              controller: scrollController,
              child: Container(),
            ),
          ),
        ),
      ),
    );

    // Pump frame so ticker fires _onTick while scrollController.hasClients is false
    await tester.pump(const Duration(milliseconds: 16));
  });

  testWidgets('WearOsScrollbar haptic feedback types', (
    WidgetTester tester,
  ) async {
    for (final feedback in WearOsHapticFeedback.values) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(feedback),
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: WearOsScrollbar(
                controller: scrollController,
                hapticFeedback: feedback,
                hapticScrollThreshold: 5,
                enableSmoothScroll: false,
                rotarySensitivity: 1.0,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 100,
                  itemBuilder: (context, index) =>
                      ListTile(title: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );

      mockPlatform.emitScrollEvent(20.0);
      await tester.pump();
    }
  });

  testWidgets('WearOsScrollbar updates when controller changes', (
    WidgetTester tester,
  ) async {
    final controller2 = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WearOsScrollbar(
            controller: scrollController,
            child: Container(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WearOsScrollbar(controller: controller2, child: Container()),
        ),
      ),
    );

    controller2.dispose();
  });

  testWidgets('WearOsScrollbar same controller update', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WearOsScrollbar(
            controller: scrollController,
            child: Container(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WearOsScrollbar(
            controller: scrollController,
            strokeWidth: 5,
            child: Container(),
          ),
        ),
      ),
    );
  });

  testWidgets('WearOsScrollbar dispose', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WearOsScrollbar(
            controller: scrollController,
            child: Container(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
  });

  testWidgets('WearOsScrollbar paints tracks when scrolled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            width: 200,
            child: WearOsScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (context, index) =>
                    ListTile(title: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );

    scrollController.jumpTo(scrollController.position.maxScrollExtent / 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.descendant(
        of: find.byType(AnimatedOpacity),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('WearOsScrollbar with empty list', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WearOsScrollbar(
            controller: scrollController,
            child: ListView(controller: scrollController, children: const []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AnimatedOpacity),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );

    // Emitting rotary event when maxScroll <= minScroll triggers limit haptic
    mockPlatform.emitScrollEvent(20.0);
    await tester.pump();
    expect(mockPlatform.hapticCalls, contains(WearOsRotaryHapticType.limit));
  });

  testWidgets('WearOsScrollbar with large margin (radius <= 0)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 10,
            height: 10,
            child: WearOsScrollbar(
              controller: scrollController,
              marginRight: 40,
              strokeWidth: 10,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (context, index) =>
                    ListTile(title: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );

    scrollController.jumpTo(50);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(AnimatedOpacity),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  group('Assertions', () {
    test('totalAngle must be between 10 and 90', () {
      expect(
        () => WearOsScrollbar(
          controller: scrollController,
          totalAngle: 5,
          child: Container(),
        ),
        throwsAssertionError,
      );
      expect(
        () => WearOsScrollbar(
          controller: scrollController,
          totalAngle: 95,
          child: Container(),
        ),
        throwsAssertionError,
      );
    });

    test('marginRight must be between 0 and 50', () {
      expect(
        () => WearOsScrollbar(
          controller: scrollController,
          marginRight: -1,
          child: Container(),
        ),
        throwsAssertionError,
      );
      expect(
        () => WearOsScrollbar(
          controller: scrollController,
          marginRight: 51,
          child: Container(),
        ),
        throwsAssertionError,
      );
    });

    test('strokeWidth must be between 1 and 10', () {
      expect(
        () => WearOsScrollbar(
          controller: scrollController,
          strokeWidth: 0,
          child: Container(),
        ),
        throwsAssertionError,
      );
      expect(
        () => WearOsScrollbar(
          controller: scrollController,
          strokeWidth: 11,
          child: Container(),
        ),
        throwsAssertionError,
      );
    });

    test('rotarySensitivity must be between 0 and 2.0', () {
      expect(
        () => WearOsScrollbar(
          controller: scrollController,
          rotarySensitivity: 0,
          child: Container(),
        ),
        throwsAssertionError,
      );
      expect(
        () => WearOsScrollbar(
          controller: scrollController,
          rotarySensitivity: 2.5,
          child: Container(),
        ),
        throwsAssertionError,
      );
    });
  });

  testWidgets(
    'WearOsScrollbar does not show indicator when hideIndicator is true',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: WearOsScrollbar(
                controller: scrollController,
                hideIndicator: true,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 100,
                  itemBuilder: (context, index) =>
                      ListTile(title: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );

      scrollController.jumpTo(50);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: find.byType(AnimatedOpacity),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'WearOsScrollbar rotary scroll works when hideIndicator is true',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: WearOsScrollbar(
                controller: scrollController,
                hideIndicator: true,
                enableSmoothScroll: false,
                rotarySensitivity: 1.0,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 100,
                  itemBuilder: (context, index) =>
                      ListTile(title: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );

      expect(scrollController.offset, 0.0);

      mockPlatform.emitScrollEvent(100.0);
      await tester.pump();

      expect(scrollController.offset, 100.0);
    },
  );
}
