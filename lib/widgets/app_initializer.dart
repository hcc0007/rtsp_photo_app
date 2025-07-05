import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../services/system_info_service.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('AppInitializer');

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  bool _isAutoLoginAttempted = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _logger.info('开始初始化应用');

    // 收集系统信息
    await SystemInfoService().collectAndLogSystemInfo();

    // 初始化认证状态
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    // 检查是否有token，如果有则尝试自动登录
    final token = await AppConfig.getToken();
    if (token.isNotEmpty) {
      _logger.info('检测到token，尝试自动登录');
      _attemptAutoLogin(authProvider);
    } else {
      _logger.info('未检测到token，跳过自动登录');
      _isAutoLoginAttempted = true;
    }

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _attemptAutoLogin(AuthProvider authProvider) async {
    try {
      _logger.info('开始自动登录流程');
      
      // 异步执行自动登录，不阻塞UI
      final success = await authProvider.autoLogin();
      
      if (success) {
        _logger.info('自动登录成功');
      } else {
        _logger.warning('自动登录失败: ${authProvider.errorMessage}');
      }
    } catch (e) {
      _logger.severe('自动登录异常: $e');
    } finally {
      // 无论成功失败，都标记为已尝试
      if (mounted) {
        setState(() {
          _isAutoLoginAttempted = true;
        });
      }
    }
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

    // 如果正在尝试自动登录，显示加载状态
    if (!_isAutoLoginAttempted) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在尝试自动登录...'),
            ],
          ),
        ),
      );
    }

    // 初始化完成后直接进入HomeScreen，不需要登录验证
    return const HomeScreen();
  }
}
