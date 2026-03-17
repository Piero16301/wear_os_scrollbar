import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar_method_channel.dart';

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
}
