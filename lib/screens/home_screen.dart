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
    });

    // 异步加载用户设置的配置
    final userRtspUrl = await AppConfig.getRtspUrl();

    if (mounted) {
      setState(() {
        rtspUrl = userRtspUrl;
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
              // 显示登录对话框
              final loginResult = await showDialog<Map<String, String>>(
                context: context,
                barrierDismissible: false,
                builder: (context) => LoginDialog(),
              );

              if (loginResult != null) {
                final username = loginResult['username']!;
                final password = loginResult['password']!;

                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                final loginSuccess = await authProvider.login(
                  username: username,
                  password: password,
                );

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
              flex: 1,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '监控画面预留区',
                  style: TextStyle(color: Colors.white, fontSize: MediaQuery.of(context).size.width / 20),
                ),
              ),
            ),

            // 照片展示区域 - 占据屏幕下方70%
            Expanded(flex: 2, child: PhotoGallery()),
          ],
        ),
      ),
    );
  }
}

class LoginDialog extends StatefulWidget {
  @override
  _LoginDialogState createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // 控制密码显示/隐藏

  @override
  void initState() {
    super.initState();
    // 使用AppConfig中的默认用户名和密码
    _usernameController.text = AppConfig.username;
    _passwordController.text = AppConfig.password;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('用户登录'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });

                    // 返回用户名和密码
                    Navigator.of(context).pop({
                      'username': _usernameController.text.trim(),
                      'password': _passwordController.text,
                    });
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('登录'),
        ),
      ],
    );
  }
}
