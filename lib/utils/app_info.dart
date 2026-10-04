import 'package:package_info_plus/package_info_plus.dart';
import 'package:wild/utils/app_platform.dart';
import 'package:wild/utils/app_version.dart';

class AppInfo {
  static PackageInfo? _packageInfo;
  static String? _version;
  static String? _buildNumber;

  static Future<void> init() async {
    if (AppPlatform.isOHOS) {
      // 鸿蒙版：统一引用全局版本常量，避免多处硬编码。
      _version = AppVersion.version;
      _buildNumber = AppVersion.buildNumber;
      return;
    }
    _packageInfo = await PackageInfo.fromPlatform();
    _version = _packageInfo?.version;
    _buildNumber = _packageInfo?.buildNumber;
  }

  /// 获取应用版本号 (例如: 0.0.15)
  static String get version => _version ?? AppVersion.version;

  /// 获取构建号 (例如: 15)
  static String get buildNumber => _buildNumber ?? AppVersion.buildNumber;

  /// 获取完整版本号 (例如: 0.0.15+15)
  static String get fullVersion => AppVersion.full;

  /// 获取应用名称
  static String get appName => _packageInfo?.appName ?? '';

  /// 获取应用包名
  static String get packageName => _packageInfo?.packageName ?? '';
}
