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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _logger.info('开始初始化应用');
    
    // 收集系统信息
    await SystemInfoService().collectAndLogSystemInfo();
    
    // 初始化认证状态
    await authProvider.initialize();

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

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在登录...'),
                ],
              ),
            ),
          );
        }

        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        } else {
          // 登录失败，显示错误信息
          return Scaffold(
            appBar: AppBar(
              title: const Text('WELCOME'),
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LogScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  tooltip: '日志',
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  tooltip: '配置',
                ),
              ],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '登录失败',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authProvider.errorMessage ?? '未知错误',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        authProvider.clearError();
                        _initializeApp();
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
