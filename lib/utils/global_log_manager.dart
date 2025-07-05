import 'package:logging/logging.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GlobalLogManager {
  static final GlobalLogManager _instance = GlobalLogManager._internal();
  factory GlobalLogManager() => _instance;
  GlobalLogManager._internal();

  final List<String> _logs = [];
  final int _maxLogs = 1000; // 最大日志数量

  List<String> get logs => List.unmodifiable(_logs);

  static void initialize() {
    // 日志系统初始化（必须最早执行）
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // 全局统一日志池 - 只监听一次
      GlobalLogManager().addLog(record);

      // 格式化日志输出
      final timestamp =
          '${record.time.hour.toString().padLeft(2, '0')}:'
          '${record.time.minute.toString().padLeft(2, '0')}:'
          '${record.time.second.toString().padLeft(2, '0')}';

      // 根据日志级别使用不同的颜色和图标
      String prefix;
      switch (record.level) {
        case Level.SEVERE:
          prefix = '🔴 [ERROR]';
          break;
        case Level.WARNING:
          prefix = '🟡 [WARN]';
          break;
        case Level.INFO:
          prefix = '🔵 [INFO]';
          break;
        case Level.FINE:
          prefix = '🟢 [DEBUG]';
          break;
        default:
          prefix = '⚪ [LOG]';
      }

      // 输出到控制台
      print('$prefix $timestamp [${record.loggerName}] ${record.message}');

      // 如果有异常信息，也输出
      if (record.error != null) {
        print('   🔍 异常详情: ${record.error}');
      }
      if (record.stackTrace != null) {
        print('   📍 堆栈跟踪: ${record.stackTrace}');
      }
    });
  }

  void addLog(LogRecord record) {
    final logEntry = _formatLogRecord(record);
    // 将新日志插入到列表开头，实现倒序
    _logs.insert(0, logEntry);

    // 限制日志数量
    if (_logs.length > _maxLogs) {
      _logs.removeRange(_maxLogs - 100, _logs.length);
    }
  }

  void clearLogs() {
    _logs.clear();
  }

  String _formatLogRecord(LogRecord record) {
    final timestamp =
        '${record.time.hour.toString().padLeft(2, '0')}:'
        '${record.time.minute.toString().padLeft(2, '0')}:'
        '${record.time.second.toString().padLeft(2, '0')}';

    String levelStr;
    switch (record.level) {
      case Level.SEVERE:
        levelStr = 'ERROR';
        break;
      case Level.WARNING:
        levelStr = 'WARN';
        break;
      case Level.INFO:
        levelStr = 'INFO';
        break;
      case Level.FINE:
        levelStr = 'DEBUG';
        break;
      default:
        levelStr = 'LOG';
    }

    return '[$timestamp] [${record.loggerName}] $levelStr: ${record.message}';
  }

  int get logCount => _logs.length;

  // 获取最新的日志（用于显示）
  List<String> getLatestLogs(int count) {
    if (_logs.length <= count) {
      return _logs;
    }
    return _logs.sublist(0, count);
  }

  // 导出日志到文件
  Future<String?> exportLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String();
      final file = File('${directory.path}/app_logs_$timestamp.txt');

      final logContent = _logs.join('\n');
      await file.writeAsString(logContent);

      return file.path;
    } catch (e) {
      print('导出日志失败: $e');
      return null;
    }
  }

  // 获取日志统计信息
  Map<String, int> getLogStatistics() {
    final stats = <String, int>{};
    for (final log in _logs) {
      if (log.contains('ERROR')) {
        stats['ERROR'] = (stats['ERROR'] ?? 0) + 1;
      } else if (log.contains('WARN')) {
        stats['WARN'] = (stats['WARN'] ?? 0) + 1;
      } else if (log.contains('INFO')) {
        stats['INFO'] = (stats['INFO'] ?? 0) + 1;
      } else if (log.contains('DEBUG')) {
        stats['DEBUG'] = (stats['DEBUG'] ?? 0) + 1;
      }
    }
    return stats;
  }

  // 按级别过滤日志
  List<String> filterLogsByLevel(String level) {
    return _logs.where((log) => log.contains(level)).toList();
  }

  // 按关键词搜索日志
  List<String> searchLogs(String keyword) {
    return _logs
        .where((log) => log.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
  }
}
