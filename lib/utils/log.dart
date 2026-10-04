import 'dart:io';

import 'package:flutter/foundation.dart';

/// 日志级别。
enum LogLevel { error, warning, info }

/// 单条日志。
class LogItem {
  final LogLevel level;
  final String title;
  final String content;
  final DateTime time = DateTime.now();

  LogItem(this.level, this.title, this.content);

  @override
  String toString() =>
      '[${level.name.toUpperCase()}] $title ${time.toIso8601String()}\n$content\n\n';
}

/// 应用日志工具。
///
/// 参考 Venera 项目的日志实现：同时输出到控制台（debugPrint，带颜色）和
/// 持久化文件 `<dataRoot>/logs.txt`，并保留最近若干条内存日志便于在应用内查看。
class Log {
  static final List<LogItem> _logs = <LogItem>[];
  static List<LogItem> get logs => _logs;

  static const int maxLogLength = 3000;
  static const int maxLogNumber = 500;

  static bool ignoreLimitation = false;
  static bool isMuted = false;

  static IOSink? _file;
  static String? _dirPath;

  /// 设置日志目录（通常在应用初始化时调用一次）。
  static void init(String dirPath) {
    _dirPath = dirPath;
    _ensureFile();
  }

  static void _ensureFile() {
    if (_file != null || _dirPath == null) return;
    try {
      final dir = Directory(_dirPath!);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${_dirPath!}${Platform.pathSeparator}logs.txt');
      _file = file.openWrite(mode: FileMode.writeOnlyAppend);
    } catch (e) {
      // 日志文件不可用时不影响主流程。
      _file = null;
      debugPrint('[Log] open log file failed: $e');
    }
  }

  static void printWarning(String text) {
    debugPrint('\x1B[33m$text\x1B[0m');
  }

  static void printError(String text) {
    debugPrint('\x1B[31m$text\x1B[0m');
  }

  static void addLog(LogLevel level, String title, String content) {
    if (isMuted) return;
    _ensureFile();

    if (!ignoreLimitation && content.length > maxLogLength) {
      content = '${content.substring(0, maxLogLength)}...';
    }

    final line = '[${level.name.toUpperCase()}] $title $content';
    switch (level) {
      case LogLevel.error:
        printError(line);
      case LogLevel.warning:
        printWarning(line);
      case LogLevel.info:
        if (kDebugMode) debugPrint(line);
    }

    final newLog = LogItem(level, title, content);
    if (_logs.isNotEmpty && _logs.last.toString() == newLog.toString()) {
      return;
    }

    _logs.add(newLog);
    if (_file != null) {
      try {
        _file!.write(newLog.toString());
        _file!.flush();
      } catch (e) {
        // 写入失败时丢弃 sink，下次调用会重建。
        try {
          _file!.close();
        } catch (_) {}
        _file = null;
      }
    }

    if (_logs.length > maxLogNumber) {
      _logs.removeAt(0);
    }
  }

  static void info(String title, String content) {
    addLog(LogLevel.info, title, content);
  }

  static void warning(String title, String content) {
    addLog(LogLevel.warning, title, content);
  }

  static void error(String title, Object content, [Object? stackTrace]) {
    var text = content.toString();
    if (stackTrace != null) {
      text += '\n$stackTrace';
    }
    addLog(LogLevel.error, title, text);
  }

  static void clear() => _logs.clear();
}
