import 'package:flutter/material.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';
import 'package:wear_os_scrollbar_example/widgets/card_action.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
      home: Scaffold(
        body: SizedBox.expand(
          child: WearOsScrollbar(
            controller: _controller,
            hapticFeedback: WearOsHapticFeedback.lightImpact,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                controller: _controller,
                itemCount: 20,
                itemBuilder: (context, index) {
                  return WearOsExpressiveItem(
                    scrollController: _controller,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: CardAction(
                        content: Text('Item ${index + 1}'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Tapped on Item ${index + 1}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
