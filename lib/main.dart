import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'providers/photo_provider.dart';
import 'screens/log_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/push_provider.dart';
import 'widgets/app_initializer.dart';
import 'services/push_server_service.dart';
import 'utils/global_log_manager.dart';

void main() async {
  // 日志系统初始化（必须最早执行）
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // 全局统一日志池 - 只监听一次
    GlobalLogManager().addLog(record);
    
    // 格式化日志输出
    final timestamp = '${record.time.hour.toString().padLeft(2, '0')}:'
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
  
  // 启动推送服务器
  try {
    await PushServerService.startServer(port: 8080);
    print('推送服务器已启动在端口 8080');
  } catch (e) {
    print('启动推送服务器失败: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => PushProvider()),
      ],
      child: MaterialApp(
        title: 'RTSP视频流和照片展示',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
        routes: {LogScreen.routeName: (context) => const LogScreen()},
      ),
    );
  }
}
