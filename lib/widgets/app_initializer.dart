import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/log_screen.dart';
import '../config/app_config.dart';
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
    
    // 注释掉认证相关的初始化
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // await authProvider.initialize();

    // 如果未登录，尝试自动登录
    // if (!authProvider.isLoggedIn) {
    //   _logger.info('用户未登录，尝试自动登录');
    //   if (AppConfig.showMockData) {
    //     _logger.info('使用Mock数据模式进行登录');
    //     // 使用mock数据
    //     await authProvider.mockLogin();
    //   } else {
    //     _logger.info('使用真实数据模式进行登录');
    //     // 使用真实数据
    //     final autoLoginSuccess = await authProvider.autoLogin();
    //     _logger.info('自动登录结果: ${autoLoginSuccess ? '成功' : '失败'}');
    //     // 如果自动登录失败
    //     if (!autoLoginSuccess) {
    //       _logger.warning('自动登录失败: ${authProvider.errorMessage}');
    //     }
    //   }
    // } else {
    //   _logger.info('用户已登录，跳过自动登录');
    // }

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
