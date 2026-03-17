import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wear_os_scrollbar_platform_interface.dart';

/// An implementation of [WearOsScrollbarPlatform] that uses method channels.
class MethodChannelWearOsScrollbar extends WearOsScrollbarPlatform {
  /// The Event channel used to interact with the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('wear_os_scrollbar/rotary');

  Stream<double>? _rotaryScrollEvents;

  @override
  Stream<double> get rotaryScrollEvents {
    _rotaryScrollEvents ??= eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => event as double);
    return _rotaryScrollEvents!;
  }
}
