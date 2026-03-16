import 'package:flutter_test/flutter_test.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar_platform_interface.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWearOsScrollbarPlatform
    with MockPlatformInterfaceMixin
    implements WearOsScrollbarPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WearOsScrollbarPlatform initialPlatform = WearOsScrollbarPlatform.instance;

  test('$MethodChannelWearOsScrollbar is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWearOsScrollbar>());
  });

  test('getPlatformVersion', () async {
    WearOsScrollbar wearOsScrollbarPlugin = WearOsScrollbar();
    MockWearOsScrollbarPlatform fakePlatform = MockWearOsScrollbarPlatform();
    WearOsScrollbarPlatform.instance = fakePlatform;

    expect(await wearOsScrollbarPlugin.getPlatformVersion(), '42');
  });
}
