import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wear_os_scrollbar_platform_interface.dart';

/// An implementation of [WearOsScrollbarPlatform] that uses method channels.
class MethodChannelWearOsScrollbar extends WearOsScrollbarPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wear_os_scrollbar');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
