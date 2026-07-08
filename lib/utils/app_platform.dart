import "dart:io";

class AppPlatform {
  static bool get isOHOS => Platform.operatingSystem == "ohos";
  static bool get isMobile => Platform.isAndroid || Platform.isIOS || isOHOS;
  static bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  static String get appVersion => isOHOS ? "0.0.1" : "";
  static String get buildNumber => isOHOS ? "1" : "";
  static String get fullVersion => "${appVersion}+${buildNumber}";
  static String get appName => "轻小说文库";
  static String get packageName => "com.opensource.wild";
}
