import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import '../lib/providers/auth_provider.dart';
import '../lib/config/app_config.dart';
import '../lib/utils/global_log_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日志系统
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    GlobalLogManager().addLog(record);
    
    final timestamp = '${record.time.hour.toString().padLeft(2, '0')}:'
        '${record.time.minute.toString().padLeft(2, '0')}:'
        '${record.time.second.toString().padLeft(2, '0')}';
    
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
    
    print('$prefix $timestamp [${record.loggerName}] ${record.message}');
  });
  
  print('🧪 开始测试日志系统...');
  print('🔧 Mock数据模式: ${AppConfig.showMockData}');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const TestApp(),
    ),
  );
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日志系统测试',
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final GlobalLogManager _logManager = GlobalLogManager();
  final Logger _testLogger = Logger('TestScreen');

  @override
  void initState() {
    super.initState();
    _generateTestLogs();
    _testAutoLogin();
  }

  void _generateTestLogs() {
    _testLogger.info('开始生成测试日志');
    _testLogger.fine('这是一条调试信息');
    _testLogger.warning('这是一条警告信息');
    
    try {
      throw Exception('这是一个测试异常');
    } catch (e, stackTrace) {
      _testLogger.severe('捕获到测试异常', e, stackTrace);
    }
    
    _testLogger.info('测试日志生成完成');
  }

  Future<void> _testAutoLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    _testLogger.info('开始测试自动登录功能');
    await authProvider.initialize();
    
    if (!authProvider.isLoggedIn) {
      _testLogger.info('用户未登录，尝试自动登录');
      final success = await authProvider.autoLogin();
      _testLogger.info('自动登录结果: $success');
    } else {
      _testLogger.info('用户已登录');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _logManager.getLogStatistics();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志系统测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              _generateTestLogs();
            },
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLogs,
            tooltip: '导出日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计信息
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Text('总日志数: ${_logManager.logCount}'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (stats['ERROR'] != null)
                      Text('错误: ${stats['ERROR']}', style: const TextStyle(color: Colors.red)),
                    if (stats['WARN'] != null)
                      Text('警告: ${stats['WARN']}', style: const TextStyle(color: Colors.orange)),
                    if (stats['INFO'] != null)
                      Text('信息: ${stats['INFO']}', style: const TextStyle(color: Colors.blue)),
                    if (stats['DEBUG'] != null)
                      Text('调试: ${stats['DEBUG']}', style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          // 最新日志
          Expanded(
            child: ListView.builder(
              itemCount: _logManager.getLatestLogs(20).length,
              itemBuilder: (context, index) {
                final logs = _logManager.getLatestLogs(20);
                final log = logs[index];
                
                Color textColor = Colors.black;
                if (log.contains('ERROR')) {
                  textColor = Colors.red;
                } else if (log.contains('WARN')) {
                  textColor = Colors.orange;
                } else if (log.contains('INFO')) {
                  textColor = Colors.blue;
                } else if (log.contains('DEBUG')) {
                  textColor = Colors.green;
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLogs() async {
    final filePath = await _logManager.exportLogs();
    if (filePath != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('日志已导出到: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('导出日志失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 