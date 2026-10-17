import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wear_os_scrollbar_example/main.dart' as app;
import 'package:wear_os_scrollbar_example/main.dart';
import 'package:wear_os_scrollbar_example/widgets/card_action.dart';

void main() {
  testWidgets('Renders the list of items', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 100'), findsNothing);
  });

  testWidgets('Shows a snackbar when an item is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Item 1'));
    await tester.pump();

    expect(find.text('Tapped on Item 1'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Replaces the previous snackbar when another item is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Item 1'));
    await tester.pump();
    await tester.tap(find.text('Item 2'));
    await tester.pump();

    expect(find.text('Tapped on Item 2'), findsOneWidget);
  });

  testWidgets('Disposes the app without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpWidget(const SizedBox.shrink());

    expect(find.byType(MyApp), findsNothing);
  });

  testWidgets('main runs the app', (WidgetTester tester) async {
    app.main();
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });

  group('CardAction', () {
    Widget wrap(Widget child) {
      return MaterialApp(home: Scaffold(body: child));
    }

    testWidgets('Renders the title above the content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(const CardAction(title: 'Title', content: Text('Content'))),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('Renders only the content without title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(const CardAction(content: Text('Content'))));

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('Calls onPressed when tapped', (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          CardAction(content: const Text('Content'), onPressed: () => taps++),
        ),
      );

      await tester.tap(find.text('Content'));

      expect(taps, 1);
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
