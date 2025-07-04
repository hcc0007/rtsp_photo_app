import 'package:flutter/material.dart';
import '../widgets/rtsp_player.dart';
import '../widgets/photo_gallery.dart';
import '../config/app_config.dart';
import 'settings_screen.dart';
import 'log_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String rtspUrl = AppConfig.defaultRtspUrl;
  String apiUrl = AppConfig.defaultApiUrl;
  bool? _lastIsLoggedIn;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final pushProvider = Provider.of<PushProvider>(context, listen: false);
    if (_lastIsLoggedIn != authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          pushProvider.handleAuth(authProvider);
        }
      });
      _lastIsLoggedIn = authProvider.isLoggedIn;
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      rtspUrl = AppConfig.defaultRtspUrl;
      apiUrl = AppConfig.defaultApiUrl;
    });

    // 异步加载用户设置的配置
    final userRtspUrl = await AppConfig.getRtspUrl();
    final userApiUrl = await AppConfig.getApiUrl();

    if (mounted) {
      setState(() {
        rtspUrl = userRtspUrl;
        apiUrl = userApiUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[700],
      appBar: AppBar(
        title: const Text(
          'WELCOME',
          style: TextStyle(color: Colors.white, letterSpacing: 5),
        ),
        backgroundColor: Colors.red[700],
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '版本号: 1.0.0',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogScreen()),
              );
            },
            icon: const Icon(Icons.list_alt, color: Colors.white),
            tooltip: '日志',
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _loadSettings(); // 返回时重新加载设置
            },
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: '配置',
          ),
          IconButton(
            onPressed: () async {
              // 弹出登录对话框
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              
              if (AppConfig.showMockData) {
                // 使用Mock数据登录
                await authProvider.mockLogin();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mock登录成功'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                // 使用真实数据登录
                final loginSuccess = await authProvider.autoLogin();
                if (!mounted) return;
                if (loginSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('登录成功'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('登录失败: ${authProvider.errorMessage}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.login, color: Colors.white),
            tooltip: '登录',
          ),
          IconButton(
            onPressed: () async {
              // 弹出确认登出对话框
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认登出'),
                  content: const Text('确定要退出登录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('确认登出'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已退出登录'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: '退出登录',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // RTSP视频流区域 - 占据屏幕上方30%
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: RtspPlayer(rtspUrl: rtspUrl),
              ),
            ),

            // 照片展示区域 - 占据屏幕下方70%
            Expanded(
              flex: 6,
              child: PhotoGallery(),
            ),

            Container(
              width: double.infinity,
              height: 50,
              color: Colors.white,
              child: Center(
                child: Text(
                  '单位名称',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
