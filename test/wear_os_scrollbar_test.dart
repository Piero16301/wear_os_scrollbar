import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar_platform_interface.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWearOsScrollbarPlatform
    with MockPlatformInterfaceMixin
    implements WearOsScrollbarPlatform {
  final StreamController<double> _controller =
      StreamController<double>.broadcast();

  @override
  Stream<double> get rotaryScrollEvents => _controller.stream;

  void emitScrollEvent(double delta) {
    _controller.add(delta);
  }
}

class ExtendsWearOsScrollbarPlatform extends WearOsScrollbarPlatform {}

void main() {
  final WearOsScrollbarPlatform initialPlatform =
      WearOsScrollbarPlatform.instance;

  test('$MethodChannelWearOsScrollbar is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWearOsScrollbar>());
  });

  test('Default implementation of rotaryScrollEvents throws UnimplementedError',
      () {
    expect(() => ExtendsWearOsScrollbarPlatform().rotaryScrollEvents,
        throwsUnimplementedError);
  });

  test('Mock platform interface streaming', () async {
    MockWearOsScrollbarPlatform fakePlatform = MockWearOsScrollbarPlatform();
    WearOsScrollbarPlatform.instance = fakePlatform;

    final events = <double>[];
    final subscription = fakePlatform.rotaryScrollEvents.listen((event) {
      events.add(event);
    });

    fakePlatform.emitScrollEvent(10.0);
    fakePlatform.emitScrollEvent(-5.0);

    await Future.delayed(Duration.zero);
    expect(events, [10.0, -5.0]);
    await subscription.cancel();
  });
}
