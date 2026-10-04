import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:wild/utils/app_version.dart';

// 状态
class UpdateState extends Equatable {
  final VersionInfo? updateInfo;
  final bool hasCheckedOnStartup;

  const UpdateState({this.updateInfo, this.hasCheckedOnStartup = false});

  @override
  List<Object?> get props => [updateInfo, hasCheckedOnStartup];

  UpdateState copyWith({VersionInfo? updateInfo, bool? hasCheckedOnStartup}) {
    return UpdateState(
      updateInfo: updateInfo ?? this.updateInfo,
      hasCheckedOnStartup: hasCheckedOnStartup ?? this.hasCheckedOnStartup,
    );
  }
}

// 更新信息
class VersionInfo extends Equatable {
  final String version;
  final String url;
  final String body;

  const VersionInfo({
    required this.version,
    required this.url,
    required this.body,
  });

  @override
  List<Object?> get props => [version, url, body];
}

// Cubit
class UpdateCubit extends Cubit<UpdateState> {
  static const String _owner = 'Leif-Wang-021';
  static const String _repo = 'wild-ohos';
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  UpdateCubit() : super(const UpdateState());

  Future<VersionInfo?> checkUpdate({bool force = false}) async {
    // 如果已经检查过且不强制检查，则直接返回当前更新信息
    if (state.hasCheckedOnStartup && !force) {
      if (kDebugMode) {
        print('Update check skipped: already checked on startup');
      }
      return state.updateInfo;
    }

    if (kDebugMode) {
      print('Checking for updates...');
      print('Request URL: $_apiUrl');
      print('User-Agent: ${AppVersion.userAgent}');
    }

    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'User-Agent': AppVersion.userAgent},
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'] as String;
        final currentVersion = AppVersion.releaseTag;

        if (kDebugMode) {
          print('Current version: $currentVersion');
          print('Latest version: $latestVersion');
        }

        if (_compareVersions(latestVersion, currentVersion) > 0) {
          if (kDebugMode) {
            print('New version available: $latestVersion');
          }
          final info = VersionInfo(
            version: latestVersion,
            url: data['html_url'] as String,
            body: data['body'] as String,
          );
          emit(state.copyWith(updateInfo: info, hasCheckedOnStartup: true));
          return info;
        } else {
          if (kDebugMode) {
            print('No new version available');
          }
        }
      } else {
        if (kDebugMode) {
          print('Update check failed: HTTP ${response.statusCode}');
        }
      }
      // 即使没有更新，也标记为已检查
      emit(state.copyWith(hasCheckedOnStartup: true));
    } catch (e) {
      if (kDebugMode) {
        print('Update check failed with error: $e');
      }
    }
    return null;
  }

  // 比较版本号，返回 1 表示有新版本，0 表示相同，-1 表示当前版本更新
  int _compareVersions(String version1, String version2) {
    final v1Parts = _versionParts(version1);
    final v2Parts = _versionParts(version2);

    final maxLength =
        v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    for (var i = 0; i < maxLength; i++) {
      final v1 = i < v1Parts.length ? v1Parts[i] : 0;
      final v2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (v1 > v2) return 1;
      if (v1 < v2) return -1;
    }

    return 0;
  }

  List<int> _versionParts(String version) {
    return version
        .replaceFirst(RegExp(r'^v'), '')
        .split(RegExp(r'[^0-9]+'))
        .where((part) => part.isNotEmpty)
        .map(int.parse)
        .toList();
  }
}
