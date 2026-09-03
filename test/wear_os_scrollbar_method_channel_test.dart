import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar_method_channel.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelWearOsScrollbar platform = MethodChannelWearOsScrollbar();
  const MethodChannel channel = MethodChannel('wear_os_scrollbar/rotary');

  test('rotaryScrollEvents stream exists and is correct type', () {
    expect(platform.rotaryScrollEvents, isNotNull);
    expect(platform.rotaryScrollEvents, isInstanceOf<Stream<double>>());
  });

  test('rotaryScrollEvents maps events correctly', () async {
    final events = <double>[];
    final subscription = platform.rotaryScrollEvents.listen((event) {
      events.add(event);
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeSuccessEnvelope(42.0),
          (data) {},
        );

    await Future.delayed(Duration.zero);
    expect(events, [42.0]);
    await subscription.cancel();
  });

  test(
    'performRotaryHaptic invokes performHapticFeedback on methods channel',
    () async {
      final log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
            log.add(call);
            return null;
          });

      await platform.performRotaryHaptic(type: WearOsRotaryHapticType.tick);
      await platform.performRotaryHaptic(type: WearOsRotaryHapticType.limit);

      expect(log, hasLength(2));
      expect(log[0].method, 'performHapticFeedback');
      expect(log[0].arguments, {'type': 'tick'});
      expect(log[1].method, 'performHapticFeedback');
      expect(log[1].arguments, {'type': 'limit'});
    },
  );

  test('performRotaryHaptic handles PlatformException gracefully', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, (call) async {
          throw PlatformException(
            code: 'UNAVAILABLE',
            message: 'Haptics not available',
          );
        });

    // Should catch PlatformException and print error without throwing
    await platform.performRotaryHaptic(type: WearOsRotaryHapticType.tick);
  });
}
