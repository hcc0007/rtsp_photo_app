import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/log_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/push_provider.dart';
import 'widgets/app_initializer.dart';
import 'services/push_server_service.dart';
import 'utils/global_log_manager.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 日志系统初始化（必须最早执行）
  try {
    GlobalLogManager.initialize();
  } catch (e) {
    print('❌ 日志系统初始化失败: $e');
  }

  // 初始化AppConfig（在日志系统之后，其他服务之前）
  try {
    await AppConfig.initialize();
    print('✅ AppConfig初始化完成');
  } catch (e) {
    print('❌ AppConfig初始化失败: $e');
  }

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
        ChangeNotifierProvider(create: (_) => PushProvider()),
      ],
      child: MaterialApp(
        title: 'SenseAI',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
        routes: {LogScreen.routeName: (context) => const LogScreen()},
      ),
    );
  }
}
