import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _serverPortController = TextEditingController();
  final _rtspController = TextEditingController();
  final _apiController = TextEditingController();
  final _tokenRefreshController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrlController.text = prefs.getString('server_url') ?? AppConfig.defaultServerUrl;
      _serverPortController.text = prefs.getString('server_port') ?? AppConfig.defaultServerPort;
      _rtspController.text = prefs.getString('rtsp_url') ?? AppConfig.defaultRtspUrl;
      _apiController.text = prefs.getString('api_url') ?? AppConfig.defaultApiUrl;
      _tokenRefreshController.text = (prefs.getInt('token_refresh_interval') ?? AppConfig.tokenRefreshInterval).toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverUrlController.text);
    await prefs.setString('server_port', _serverPortController.text);
    await prefs.setString('rtsp_url', _rtspController.text);
    await prefs.setString('api_url', _apiController.text);
    
    // 保存token刷新间隔（转换为毫秒）
    final tokenRefreshInterval = int.tryParse(_tokenRefreshController.text) ?? AppConfig.tokenRefreshInterval;
    await prefs.setInt('token_refresh_interval', tokenRefreshInterval);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '服务器配置',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _serverUrlController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: '服务器地址',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'http://192.168.1.100',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red[400]!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serverPortController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '服务器端口',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: '8080',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red[400]!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenRefreshController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Token刷新间隔（毫秒）',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: '1500000',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red[400]!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'RTSP视频流配置',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rtspController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'RTSP地址',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'rtsp://your-rtsp-url:554/stream',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red[400]!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'API配置',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: '照片API地址',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'https://your-api-endpoint.com/photos',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red[400]!),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '说明',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• 服务器地址：输入您的服务器IP地址或域名\n'
              '• 服务器端口：输入服务器监听的端口号\n'
              '• Token刷新间隔：设置token自动刷新的时间间隔（毫秒）\n'
              '• RTSP地址：输入您的RTSP视频流地址，支持H264编码\n'
              '• API地址：输入获取照片列表的API接口地址\n'
              '• API应返回字符串数组格式的照片URL列表\n'
              '• 设置保存后需要重启应用生效',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _serverPortController.dispose();
    _rtspController.dispose();
    _apiController.dispose();
    _tokenRefreshController.dispose();
    super.dispose();
  }
} 