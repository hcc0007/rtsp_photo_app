import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../services/system_info_service.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('AppInitializer');

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _logger.info('开始初始化应用');

    // 收集系统信息
    await SystemInfoService().collectAndLogSystemInfo();

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在初始化应用...'),
            ],
          ),
        ),
      );
    }

    // 初始化完成后直接进入HomeScreen，不需要登录验证
    return const HomeScreen();
  }
}
