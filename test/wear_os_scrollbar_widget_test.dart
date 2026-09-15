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

    test('flingFactor must be between 0 and 2.0', () {
      expect(
        () => WearOsScrollbar(
          controller: scrollController,
          flingFactor: 0,
          child: Container(),
        ),
        throwsAssertionError,
      );
      expect(
        () => WearOsScrollbar(
          controller: scrollController,
          flingFactor: 2.5,
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

  group('Navigation and route awareness', () {
    testWidgets(
      'WearOsScrollbar only responds to rotary events when current route in Navigator',
      (WidgetTester tester) async {
        final controllerA = ScrollController();
        final controllerB = ScrollController();
        addTearDown(controllerA.dispose);
        addTearDown(controllerB.dispose);

        final navKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navKey,
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: WearOsScrollbar(
                  controller: controllerA,
                  enableSmoothScroll: false,
                  rotarySensitivity: 1.0,
                  child: ListView.builder(
                    controller: controllerA,
                    itemCount: 100,
                    itemBuilder: (context, index) =>
                        ListTile(title: Text('A: $index')),
                  ),
                ),
              ),
            ),
          ),
        );

        // Initially on Route A
        expect(controllerA.offset, 0.0);
        mockPlatform.emitScrollEvent(40.0);
        await tester.pump();
        expect(controllerA.offset, 40.0);

        // Push Route B on top
        navKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              body: SizedBox(
                height: 200,
                child: WearOsScrollbar(
                  controller: controllerB,
                  enableSmoothScroll: false,
                  rotarySensitivity: 1.0,
                  child: ListView.builder(
                    controller: controllerB,
                    itemCount: 100,
                    itemBuilder: (context, index) =>
                        ListTile(title: Text('B: $index')),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Rotary event should only scroll Route B, Route A must remain intact
        mockPlatform.emitScrollEvent(70.0);
        await tester.pump();

        expect(controllerB.offset, 70.0);
        expect(controllerA.offset, 40.0);

        // Pop Route B - Route A becomes current again
        navKey.currentState!.pop();
        await tester.pumpAndSettle();

        // Route A should now respond to rotary events again
        mockPlatform.emitScrollEvent(30.0);
        await tester.pump();

        expect(controllerA.offset, 70.0);
      },
    );

    testWidgets(
      'WearOsScrollbar scrolls background route when onlyWhenCurrentRoute is false',
      (WidgetTester tester) async {
        final controllerA = ScrollController();
        final controllerB = ScrollController();
        addTearDown(controllerA.dispose);
        addTearDown(controllerB.dispose);

        final navKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navKey,
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: WearOsScrollbar(
                  controller: controllerA,
                  onlyWhenCurrentRoute: false,
                  enableSmoothScroll: false,
                  rotarySensitivity: 1.0,
                  child: ListView.builder(
                    controller: controllerA,
                    itemCount: 100,
                    itemBuilder: (context, index) =>
                        ListTile(title: Text('A: $index')),
                  ),
                ),
              ),
            ),
          ),
        );

        navKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              body: SizedBox(
                height: 200,
                child: WearOsScrollbar(
                  controller: controllerB,
                  enableSmoothScroll: false,
                  rotarySensitivity: 1.0,
                  child: ListView.builder(
                    controller: controllerB,
                    itemCount: 100,
                    itemBuilder: (context, index) =>
                        ListTile(title: Text('B: $index')),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Both controllers receive scroll since onlyWhenCurrentRoute is false for A
        mockPlatform.emitScrollEvent(50.0);
        await tester.pump();

        expect(controllerB.offset, 50.0);
        expect(controllerA.offset, 50.0);
      },
    );

    testWidgets(
      'WearOsScrollbar functions normally outside of a Navigator (ModalRoute is null)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 200,
                child: WearOsScrollbar(
                  controller: scrollController,
                  enableSmoothScroll: false,
                  rotarySensitivity: 1.0,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 100,
                    itemBuilder: (context, index) =>
                        SizedBox(height: 40, child: Text('Item $index')),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(scrollController.offset, 0.0);

        mockPlatform.emitScrollEvent(80.0);
        await tester.pump();

        expect(scrollController.offset, 80.0);
      },
    );

    testWidgets(
      'WearOsScrollbar stops smooth scroll ticker when route becomes inactive or in background',
      (WidgetTester tester) async {
        final controllerA = ScrollController();
        addTearDown(controllerA.dispose);

        final navKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navKey,
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: WearOsScrollbar(
                  controller: controllerA,
                  enableSmoothScroll: true,
                  rotarySensitivity: 1.0,
                  child: ListView.builder(
                    controller: controllerA,
                    itemCount: 100,
                    itemBuilder: (context, index) =>
                        ListTile(title: Text('A: $index')),
                  ),
                ),
              ),
            ),
          ),
        );

        // Start smooth scroll on Route A
        mockPlatform.emitScrollEvent(200.0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        final offsetBeforePush = controllerA.offset;
        expect(offsetBeforePush, greaterThan(0.0));

        // Push Route B while ticker is active
        navKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (context) =>
                const Scaffold(body: Center(child: Text('Route B'))),
          ),
        );
        // Step forward enough for Route B to push and ticker to evaluate _onTick
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));

        // Send rotary event while Route A is not current to trigger _onRotaryEvent stopTicker branch
        mockPlatform.emitScrollEvent(50.0);
        await tester.pump();

        // Also verify background route programmatic scroll does not show indicator
        controllerA.jumpTo(controllerA.offset + 10);
        await tester.pump();

        // Pump and settle to complete push transition
        await tester.pumpAndSettle();
      },
    );
  });

  group('Wear OS 7 native physics and single limit haptic', () {
    testWidgets(
      'Limit haptic only triggers once when rotating continuously against boundary',
      (WidgetTester tester) async {
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

        expect(scrollController.offset, 0.0);

        // 1. First rotation attempt past top boundary (offset = 0)
        mockPlatform.emitScrollEvent(-50.0);
        await tester.pump();

        final initialLimitCalls = mockPlatform.hapticCalls
            .where((c) => c == WearOsRotaryHapticType.limit)
            .length;
        expect(initialLimitCalls, 1, reason: 'Must trigger limit haptic on first hit');

        // 2. Further continuous turns into the same boundary must NOT vibrate again
        for (int i = 0; i < 5; i++) {
          mockPlatform.emitScrollEvent(-50.0);
          await tester.pump(const Duration(milliseconds: 30));
        }

        final repeatedLimitCalls = mockPlatform.hapticCalls
            .where((c) => c == WearOsRotaryHapticType.limit)
            .length;
        expect(
          repeatedLimitCalls,
          1,
          reason: 'Continuous rotation against boundary must NOT repeat limit vibration',
        );

        // 3. Move away from boundary (scroll downwards)
        mockPlatform.emitScrollEvent(100.0);
        await tester.pumpAndSettle();
        expect(scrollController.offset, greaterThan(0.0));

        // 4. Scroll back up and hit top boundary again
        mockPlatform.emitScrollEvent(-200.0);
        await tester.pumpAndSettle();
        expect(scrollController.offset, 0.0);

        final hitAgainLimitCalls = mockPlatform.hapticCalls
            .where((c) => c == WearOsRotaryHapticType.limit)
            .length;
        expect(
          hitAgainLimitCalls,
          2,
          reason: 'Reaching boundary again after moving away should trigger limit haptic once more',
        );

        // 5. Subsequent attempts into wall again do not vibrate
        mockPlatform.emitScrollEvent(-50.0);
        await tester.pump();
        expect(
          mockPlatform.hapticCalls
              .where((c) => c == WearOsRotaryHapticType.limit)
              .length,
          2,
        );
      },
    );

    testWidgets(
      'Limit haptic in instant mode only triggers once when rotating against boundary',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: WearOsScrollbar(
                  controller: scrollController,
                  enableSmoothScroll: false,
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

        expect(scrollController.offset, 0.0);

        // First hit at 0.0
        mockPlatform.emitScrollEvent(-50.0);
        await tester.pump();
        expect(
          mockPlatform.hapticCalls
              .where((c) => c == WearOsRotaryHapticType.limit)
              .length,
          1,
        );

        // Repeated hits at 0.0 in instant mode
        mockPlatform.emitScrollEvent(-50.0);
        await tester.pump();
        mockPlatform.emitScrollEvent(-50.0);
        await tester.pump();
        expect(
          mockPlatform.hapticCalls
              .where((c) => c == WearOsRotaryHapticType.limit)
              .length,
          1,
        );
      },
    );

    testWidgets(
      'Fast rotary spinning triggers fling inertia with physical decay',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: WearOsScrollbar(
                  controller: scrollController,
                  enableSmoothScroll: true,
                  enableFling: true,
                  rotarySensitivity: 0.4,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 200,
                    itemBuilder: (context, index) =>
                        ListTile(title: Text('Item $index')),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(scrollController.offset, 0.0);

        // Emit a rapid burst of rotary scroll events (spinning fast)
        // 5 events of 80px separated by 10ms (raw delta = 5 * 80 * 0.4 = 160px)
        for (int i = 0; i < 5; i++) {
          mockPlatform.emitScrollEvent(80.0);
          await tester.pump(const Duration(milliseconds: 10));
        }

        // Wait for fling debounce (40ms) and step into fling simulation
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 100));

        // Complete the fling simulation
        await tester.pumpAndSettle();

        // With fling inertia, the final offset should have glided well beyond the raw delta sum of 160px
        expect(
          scrollController.offset,
          greaterThan(200.0),
          reason: 'Fast spin should fling with inertia beyond the raw event delta sum',
        );
      },
    );

    testWidgets(
      'enableFling: false disables fling inertia and only moves by event sum',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: WearOsScrollbar(
                  controller: scrollController,
                  enableSmoothScroll: true,
                  enableFling: false,
                  rotarySensitivity: 0.4,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 200,
                    itemBuilder: (context, index) =>
                        ListTile(title: Text('Item $index')),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(scrollController.offset, 0.0);

        for (int i = 0; i < 5; i++) {
          mockPlatform.emitScrollEvent(80.0);
          await tester.pump(const Duration(milliseconds: 10));
        }

        await tester.pumpAndSettle();

        // 5 * 80.0 * 0.4 = 160.0
        expect(
          scrollController.offset,
          closeTo(160.0, 0.1),
          reason: 'When enableFling is false, scroll must stop exactly at accumulated delta',
        );
      },
    );

    testWidgets(
      'Fling hitting list boundary stops at maxScrollExtent and triggers limit haptic once',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: WearOsScrollbar(
                  controller: scrollController,
                  enableSmoothScroll: true,
                  enableFling: true,
                  hapticFeedback: WearOsHapticFeedback.rotaryTick,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 10,
                    itemExtent: 50.0, // total 500px, viewport 200px -> maxScroll = 300px
                    itemBuilder: (context, index) =>
                        ListTile(title: Text('Item $index')),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(scrollController.offset, 0.0);

        // Fast fling downwards
        for (int i = 0; i < 6; i++) {
          mockPlatform.emitScrollEvent(100.0);
          await tester.pump(const Duration(milliseconds: 10));
        }

        await tester.pumpAndSettle();

        // Hit the bottom limit (maxScrollExtent = 300.0)
        expect(scrollController.offset, 300.0);
        expect(
          mockPlatform.hapticCalls
              .where((c) => c == WearOsRotaryHapticType.limit)
              .length,
          1,
          reason: 'Fling hitting bottom boundary must trigger limit haptic once',
        );

        // Spinning further down while at the bottom must NOT trigger another limit haptic
        mockPlatform.emitScrollEvent(50.0);
        await tester.pump();
        expect(
          mockPlatform.hapticCalls
              .where((c) => c == WearOsRotaryHapticType.limit)
              .length,
          1,
        );
      },
    );
  });
}

