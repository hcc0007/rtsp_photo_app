import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../lib/providers/auth_provider.dart';
import '../lib/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestServerUrlUpdate extends StatefulWidget {
  const TestServerUrlUpdate({super.key});

  @override
  State<TestServerUrlUpdate> createState() => _TestServerUrlUpdateState();
}

class _TestServerUrlUpdateState extends State<TestServerUrlUpdate> {
  String _currentServerUrl = '';
  String _currentServerPort = '';
  String _newServerUrl = '192.168.1.100';
  String _newServerPort = '9090';

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final serverUrl = await AppConfig.getServerUrl();
    final serverPort = await AppConfig.getServerPort();
    setState(() {
      _currentServerUrl = serverUrl;
      _currentServerPort = serverPort;
    });
  }

  Future<void> _updateServerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _newServerUrl);
    await prefs.setString('server_port', _newServerPort);
    
    // 重新初始化认证服务
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.reinitialize();
    
    // 重新加载设置
    await _loadCurrentSettings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('服务器地址已更新'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.autoLogin();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '登录成功' : '登录失败: ${authProvider.errorMessage}'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务器地址更新测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当前设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('服务器地址: $_currentServerUrl'),
            Text('服务器端口: $_currentServerPort'),
            const SizedBox(height: 16),
            
            const Text(
              '新设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: '新服务器地址',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _newServerUrl),
              onChanged: (value) => _newServerUrl = value,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: '新服务器端口',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _newServerPort),
              onChanged: (value) => _newServerPort = value,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                ElevatedButton(
                  onPressed: _updateServerSettings,
                  child: const Text('更新服务器地址'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _testLogin,
                  child: const Text('测试登录'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '登录状态',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('登录状态: ${authProvider.isLoggedIn ? '已登录' : '未登录'}'),
                    if (authProvider.userInfo != null)
                      Text('用户: ${authProvider.userInfo!.username}'),
                    if (authProvider.errorMessage != null)
                      Text('错误: ${authProvider.errorMessage}', style: const TextStyle(color: Colors.red)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 