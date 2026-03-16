
import 'wear_os_scrollbar_platform_interface.dart';

class WearOsScrollbar {
  Future<String?> getPlatformVersion() {
    return WearOsScrollbarPlatform.instance.getPlatformVersion();
  }
}
