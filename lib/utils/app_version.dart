/// 应用版本号的唯一来源（single source of truth）。
///
/// 所有显示/比较版本号的地方都必须引用此处，避免多处硬编码不一致。
/// 发布新版本时只需修改本文件（同时同步 pubspec.yaml 与 ohos 的 app.json5）。
class AppVersion {
  AppVersion._();

  /// 语义版本号，例如 `0.0.16`。
  static const String version = '0.0.16';

  /// 构建号，例如 `16`。
  static const String buildNumber = '16';

  /// 鸿蒙移植版的修订序号（同一上游版本多次打包时递增）。
  static const int ohosReleaseRevision = 1;

  /// 完整版本号，例如 `0.0.16+16`。
  static const String full = '$version+$buildNumber';

  /// 关于页展示用，例如 `0.0.16-ohos+16`。
  static const String display = '$version-ohos+$buildNumber';

  /// GitHub Release 的标签，例如 `v0.0.16-ohos.1`。
  static const String releaseTag = 'v$version-ohos.$ohosReleaseRevision';

  /// 用于 User-Agent 等，例如 `0.0.16+16`。
  static String get userAgent => 'Wild/$full';
}
