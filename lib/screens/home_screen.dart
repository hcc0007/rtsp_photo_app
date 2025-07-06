import 'package:flutter/material.dart';
import '../widgets/photo_gallery.dart';
import '../config/app_config.dart';
import 'settings_screen.dart';
import 'log_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String rtspUrl = AppConfig.defaultRtspUrl;
  bool? _lastIsLoggedIn;

  // 新增：时间相关状态
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _now = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 8,
            fontSize: 64,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.red[700],
        toolbarHeight: 120,
        actionsPadding: EdgeInsets.only(right: 24),
        elevation: 0,
        actions: _buildActionButtons(),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 主内容
            Column(
              children: [
                // RTSP视频流区域 - 占据屏幕上方30%
                Expanded(flex: 2, child: _buildRtspVideo()),

                SizedBox(height: 100),

                // 照片展示区域 - 占据屏幕下方70%
                Expanded(flex: 3, child: PhotoGallery()),

                // 时间
                _buildDateNowInfo(),

                // 底部公司拦
                _buildBottomCompanyInfo(),
              ],
            ),

            // 悬浮的时间卡片，右下角
            // Positioned(right: 12, bottom: 12, child: _buildDateNowInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCompanyInfo() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 200, height: 2, color: Colors.black),
          SizedBox(width: 30),
          Text(
            AppConfig.company,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontFamily: 'PingFang SC',
            ),
          ),
          SizedBox(width: 30),
          Container(width: 200, height: 2, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildDateNowInfo() {
    // 格式化时间、日期、星期
    String timeStr = _now.toLocal().toString().substring(11, 19); // HH:mm:ss
    String dateStr = "${_now.year}/${_now.month}/${_now.day}";
    const weekDays = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"];
    String weekStr = weekDays[_now.weekday % 7];

    return Container(
      padding: EdgeInsets.only(right: 24, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width / 12,
              fontWeight: FontWeight.w300,
              letterSpacing: -4,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width / 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(width: 16),
              Text(
                weekStr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width / 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRtspVideo() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(left: 24, right: 24, top: 6, bottom: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '监控画面预留区',
        style: TextStyle(
          color: Colors.white,
          fontSize: MediaQuery.of(context).size.width / 20,
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    return [
      // 登录状态指示器
      Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: authProvider.isLoggedIn
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: authProvider.isLoggedIn ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  authProvider.isLoggedIn ? Icons.check_circle : Icons.warning,
                  color: authProvider.isLoggedIn ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  authProvider.isLoggedIn ? '已登录' : '未登录',
                  style: TextStyle(
                    color: authProvider.isLoggedIn
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // 版本号
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
      // 下拉菜单
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        tooltip: '更多选项',
        onSelected: (value) async {
          switch (value) {
            case 'logs':
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogScreen()),
              );
              break;
            case 'settings':
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _loadSettings(); // 返回时重新加载设置
              break;
            case 'user_info':
              _handleUserInfoAction();
              break;
            case 'logout':
              _handleLogoutAction();
              break;
            case 'debug_toggle':
              _toggleDebugMode();
              break;
          }
        },
        itemBuilder: (context) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final items = <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'logs',
              child: Row(
                children: [
                  Icon(Icons.list_alt),
                  SizedBox(width: 8),
                  Text('日志'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('配置'),
                ],
              ),
            ),

            // 用户信息
            PopupMenuItem<String>(
              value: 'user_info',
              child: Row(
                children: [
                  Icon(
                    authProvider.isLoggedIn ? Icons.person : Icons.login,
                    color: authProvider.isLoggedIn ? Colors.green : null,
                  ),
                  const SizedBox(width: 8),
                  Text(authProvider.isLoggedIn ? '用户信息' : '登录'),
                ],
              ),
            ),
          ];

          // 只有在登录状态下才显示退出登录选项
          if (authProvider.isLoggedIn) {
            items.add(
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('退出登录'),
                  ],
                ),
              ),
            );
          }

          items.add(
            PopupMenuItem<String>(
              value: 'debug_toggle',
              child: Row(
                children: [
                  const Icon(Icons.bug_report),
                  const SizedBox(width: 8),
                  Text('Debug模式${PhotoGallery.debugMode ? '(已开启)' : '(已关闭)'}'),
                ],
              ),
            ),
          );

          return items;
        },
      ),
    ];
  }

  void _handleUserInfoAction() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      // 如果已登录，显示用户信息
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('用户信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('用户名: ${authProvider.userInfo?.username ?? '未知'}'),
              const SizedBox(height: 8),
              Text('登录状态: 已登录'),
              if (authProvider.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  '错误信息: ${authProvider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } else {
      // 如果未登录，显示登录对话框
      final loginResult = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => LoginDialog(),
      );

      if (loginResult != null) {
        final username = loginResult['username']!;
        final password = loginResult['password']!;

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
    }
  }

  void _handleLogoutAction() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
      await authProvider.logout();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已退出登录'), backgroundColor: Colors.orange),
      );
    }
  }

  void _toggleDebugMode() {
    PhotoGallery.debugMode = !PhotoGallery.debugMode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(PhotoGallery.debugMode ? 'Debug模式已开启' : 'Debug模式已关闭'),
        backgroundColor: PhotoGallery.debugMode ? Colors.green : Colors.grey,
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
