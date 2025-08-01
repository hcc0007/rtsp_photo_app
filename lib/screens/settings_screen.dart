import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 服务端地址
  final _serverUrlController = TextEditingController();
  // 端口
  final _serverPortController = TextEditingController();
  // rtsp
  final _rtspController = TextEditingController();

  // 白名单 - 显示在大屏幕的时间
  final _normalPersonDisplayController = TextEditingController();
  // 陌生人 - 显示在大屏幕的时间
  final _strangerDisplayController = TextEditingController();

  // 白名单 - 同一人的人脸 过滤时间
  final _normalPersonFilterTimeController = TextEditingController();
  // 陌生人 - 同一人的人脸 过滤时间
  final _strangerFilterTimeController = TextEditingController();

  // 白名单 - 最大展示数量
  final _normalPersonMaxDisplayController = TextEditingController();
  // 陌生人 - 最大展示数量
  final _strangerMaxDisplayController = TextEditingController();

  // 日志最大数量
  final _logMaxCountController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // 只能从appConfig中读取
      _serverUrlController.text = AppConfig.apiUrl;
      _serverPortController.text = AppConfig.apiPort;
      _rtspController.text = AppConfig.defaultRtspUrl;
      _normalPersonDisplayController.text = AppConfig.normalPersonDisplayTime
          .toString();
      _strangerDisplayController.text = AppConfig.strangerDisplayTime
          .toString();
      _normalPersonFilterTimeController.text = AppConfig
          .normalPersonFilterTimeWindow
          .toString();
      _strangerFilterTimeController.text = AppConfig.strangerFilterTimeWindow
          .toString();
      _normalPersonMaxDisplayController.text = AppConfig
          .normalPersonMaxDisplayCount
          .toString();
      _strangerMaxDisplayController.text = AppConfig.strangerMaxDisplayCount
          .toString();
      _logMaxCountController.text = AppConfig.logMaxCount.toString();
    } catch (e) {
      print('加载设置失败: $e');
    }
    _isLoading = false;
  }

  Future<void> _saveSettings() async {
    print('保存设置 ====> ${_serverUrlController.text}');

    // 从AppConfig中设置
    await AppConfig.setServerUrl(_serverUrlController.text);
    await AppConfig.setServerPort(_serverPortController.text);
    await AppConfig.setRtspUrl(_rtspController.text);
    await AppConfig.setNormalPersonDisplayTime(
      int.parse(_normalPersonDisplayController.text),
    );
    await AppConfig.setStrangerDisplayTime(
      int.parse(_strangerDisplayController.text),
    );
    await AppConfig.setNormalPersonFilterTimeWindow(
      int.parse(_normalPersonFilterTimeController.text),
    );
    await AppConfig.setStrangerFilterTimeWindow(
      int.parse(_strangerFilterTimeController.text),
    );
    await AppConfig.setNormalPersonMaxDisplayCount(
      int.parse(_normalPersonMaxDisplayController.text),
    );
    await AppConfig.setStrangerMaxDisplayCount(
      int.parse(_strangerMaxDisplayController.text),
    );
    await AppConfig.setLogMaxCount(
      int.parse(_logMaxCountController.text),
    );

    // 重新初始化AppConfig以使用新的配置
    try {
      await AppConfig.initialize();
      // 更新界面显示的配置值
      setState(() {
        _loadSettings();
      });
    } catch (e) {
      print('重新初始化AppConfig失败: $e');
    }

    // 重新初始化认证服务以使用新的服务器地址
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.reinitialize();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存，配置已更新'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: AppConfig.theme,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _saveSettings, icon: const Icon(Icons.save)),
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
                  borderSide: BorderSide(color: AppConfig.theme!),
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
                  borderSide: BorderSide(color: AppConfig.theme!),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                  borderSide: BorderSide(color: AppConfig.theme!),
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
              '• RTSP地址：输入您的RTSP视频流地址，支持H264编码\n'
              '• 设置保存后需要重启应用生效',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            const Text(
              '人脸推送过滤配置',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _normalPersonDisplayController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '白名单人员显示时间（毫秒）',
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
                  borderSide: BorderSide(color: AppConfig.theme!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _strangerDisplayController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '陌生人显示时间（毫秒）',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: '10000',
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
                  borderSide: BorderSide(color: AppConfig.theme!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '根据人员类型的过滤时间窗口',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _strangerFilterTimeController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '陌生人过滤时间（毫秒）',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: '120000',
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
                  borderSide: BorderSide(color: AppConfig.theme!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _normalPersonFilterTimeController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '白名单人员过滤时间（毫秒）',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: '120000',
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
                  borderSide: BorderSide(color: AppConfig.theme!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '展示数量限制',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _normalPersonMaxDisplayController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '白名单人员最大展示数量',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: '10',
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
                  borderSide: BorderSide(color: AppConfig.theme!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _strangerMaxDisplayController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '陌生人最大展示数量',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: '10',
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
                  borderSide: BorderSide(color: AppConfig.theme!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '日志配置',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _logMaxCountController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '日志最大数量',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: '10000',
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
                  borderSide: BorderSide(color: AppConfig.theme!),
                ),
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
    _normalPersonDisplayController.dispose();
    _strangerDisplayController.dispose();
    _strangerFilterTimeController.dispose();
    _normalPersonFilterTimeController.dispose();
    _normalPersonMaxDisplayController.dispose();
    _strangerMaxDisplayController.dispose();
    _logMaxCountController.dispose();
    super.dispose();
  }
}
