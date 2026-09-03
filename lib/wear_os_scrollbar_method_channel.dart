/// The method channel implementation for wear_os_scrollbar.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wear_os_scrollbar_platform_interface.dart';

/// An implementation of [WearOsScrollbarPlatform] that uses method channels.
class MethodChannelWearOsScrollbar extends WearOsScrollbarPlatform {
  /// Creates a [MethodChannelWearOsScrollbar].
  MethodChannelWearOsScrollbar();

  /// The Event channel used to interact with the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('wear_os_scrollbar/rotary');

  /// The Method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wear_os_scrollbar/methods');

  Stream<double>? _rotaryScrollEvents;

  @override
  /// Stream of rotary scroll events from the native platform.
  Stream<double> get rotaryScrollEvents {
    _rotaryScrollEvents ??= eventChannel.receiveBroadcastStream().map(
      (dynamic event) => (event as num).toDouble(),
    );
    return _rotaryScrollEvents!;
  }

  @override
  Future<void> performRotaryHaptic({
    WearOsRotaryHapticType type = WearOsRotaryHapticType.tick,
  }) async {
    try {
      await methodChannel.invokeMethod<void>('performHapticFeedback', {
        'type': type.name,
      });
    } on PlatformException catch (e) {
      debugPrint('Error performing rotary haptic feedback: $e');
    }
  }
}
