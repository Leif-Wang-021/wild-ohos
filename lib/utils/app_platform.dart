import "dart:io";

import "app_version.dart";

class AppPlatform {
  static bool get isOHOS => Platform.operatingSystem == "ohos";
  static bool get isMobile => Platform.isAndroid || Platform.isIOS || isOHOS;
  static bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  // 统一引用全局版本常量，避免版本号不一致。
  static String get appVersion => isOHOS ? AppVersion.version : "";
  static String get buildNumber => isOHOS ? AppVersion.buildNumber : "";
  static String get fullVersion => AppVersion.full;
  static String get appName => "轻小说文库";
  static String get packageName => "com.opensource.wild";
}
