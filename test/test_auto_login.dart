import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../lib/providers/auth_provider.dart';
import '../lib/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 开始测试自动登录功能...');
  print('🔧 Mock数据模式: ${AppConfig.showMockData}');
  print('👤 默认用户名: ${AppConfig.defaultUsername}');
  print('🔑 默认密码: ${AppConfig.defaultPassword}');
  
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
      title: '自动登录测试',
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
  @override
  void initState() {
    super.initState();
    _testAutoLogin();
  }

  Future<void> _testAutoLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    print('🔄 初始化认证提供者...');
    await authProvider.initialize();
    
    print('🔐 检查登录状态: ${authProvider.isLoggedIn}');
    
    if (!authProvider.isLoggedIn) {
      print('🚀 开始自动登录...');
      final success = await authProvider.autoLogin();
      print('📊 自动登录结果: $success');
      
      if (success) {
        print('✅ 登录成功! 用户信息: ${authProvider.userInfo?.username}');
      } else {
        print('❌ 登录失败! 错误信息: ${authProvider.errorMessage}');
      }
    } else {
      print('✅ 已经登录! 用户信息: ${authProvider.userInfo?.username}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自动登录测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (authProvider.isLoading)
                  const CircularProgressIndicator()
                else if (authProvider.isLoggedIn)
                  const Icon(Icons.check_circle, color: Colors.green, size: 64)
                else
                  const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  authProvider.isLoading
                      ? '正在登录...'
                      : authProvider.isLoggedIn
                          ? '登录成功!'
                          : '登录失败',
                  style: const TextStyle(fontSize: 18),
                ),
                if (authProvider.userInfo != null) ...[
                  const SizedBox(height: 8),
                  Text('用户: ${authProvider.userInfo!.username}'),
                  Text('昵称: ${authProvider.userInfo!.nickname}'),
                ],
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '错误: ${authProvider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _testAutoLogin(),
                  child: const Text('重新测试'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 