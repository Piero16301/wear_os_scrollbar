import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wear_os_scrollbar_method_channel.dart';

abstract class WearOsScrollbarPlatform extends PlatformInterface {
  /// Constructs a WearOsScrollbarPlatform.
  WearOsScrollbarPlatform() : super(token: _token);

  static final Object _token = Object();

  static WearOsScrollbarPlatform _instance = MethodChannelWearOsScrollbar();

  /// The default instance of [WearOsScrollbarPlatform] to use.
  ///
  /// Defaults to [MethodChannelWearOsScrollbar].
  static WearOsScrollbarPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WearOsScrollbarPlatform] when
  /// they register themselves.
  static set instance(WearOsScrollbarPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream of rotary scroll events from the native platform
  Stream<double> get rotaryScrollEvents {
    throw UnimplementedError('rotaryScrollEvents has not been implemented.');
  }
}
