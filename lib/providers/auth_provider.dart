import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../models/user_info.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger('AuthProvider');
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  UserInfo? _userInfo;
  Timer? _tokenRefreshTimer;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  UserInfo? get userInfo => _userInfo;
  AuthService get authService => _authService;

  // 初始化认证状态
  Future<void> initialize() async {
    _logger.info('开始初始化认证状态');
    await _authService.initialize();
    _isLoggedIn = _authService.isLoggedIn;
    final userInfoMap = _authService.userInfo;
    _userInfo = userInfoMap != null ? UserInfo.fromJson(userInfoMap) : null;
    
    _logger.info('认证状态初始化完成 - 登录状态: $_isLoggedIn');
    
    // 如果已登录，启动token刷新定时器
    if (_isLoggedIn) {
      _logger.info('用户已登录，启动token刷新定时器');
      _startTokenRefreshTimer();
    }
    
    notifyListeners();
  }

  // 自动登录
  Future<bool> autoLogin({
    String? username,
    String? password,
    String? serverIp,
    String? serverPort,
  }) async {
    final loginUsername = username ?? AppConfig.defaultUsername;
    final loginPassword = password ?? AppConfig.defaultPassword;
    
    _logger.info('开始自动登录');
    _logger.info('用户名: $loginUsername');
    _logger.info('服务器: ${_authService.baseUrl}');
    
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.login(
        account: loginUsername,
        password: loginPassword,
      );

      _logger.info('登录结果: $result');

      if (result['success']) {
        _isLoggedIn = true;
        _userInfo = UserInfo.fromJson(result['data']);
        _clearError();
        
        _logger.info('自动登录成功');
        
        // 启动token刷新定时器
        _startTokenRefreshTimer();
        
        notifyListeners();
        return true;
      } else {
        final errorMsg = result['message'] ?? '登录失败';
        _logger.warning('自动登录失败: $errorMsg');
        _setError(errorMsg);
        return false;
      }
    } catch (e) {
      _logger.severe('自动登录异常: $e');
      _setError('登录异常: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 手动登录
  Future<bool> login({
    required String username,
    required String password,
    String? serverIp,
    String? serverPort,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.login(
        account: username,
        password: password,
      );

      if (result['success']) {
        _isLoggedIn = true;
        _userInfo = UserInfo.fromJson(result['data']);
        _clearError();
        
        // 启动token刷新定时器
        _startTokenRefreshTimer();
        
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? '登录失败');
        return false;
      }
    } catch (e) {
      _setError('登录异常: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 刷新用户信息（用于保持token有效）
  Future<bool> refreshUserInfo() async {
    if (!_isLoggedIn) return false;

    try {
      _logger.fine('开始刷新用户信息');
      final result = await _authService.getUserDetail();
      
      if (result['success']) {
        _userInfo = UserInfo.fromJson(result['data']);
        _logger.fine('用户信息刷新成功');
        notifyListeners();
        return true;
      } else {
        _logger.warning('刷新用户信息失败: ${result['message']}');
        // 如果获取用户信息失败，可能是token过期
        if (result['code'] == 401 || result['code'] == 403) {
          _logger.warning('Token可能已过期，执行登出操作');
          await logout();
        }
        return false;
      }
    } catch (e) {
      _logger.severe('刷新用户信息异常: $e');
      return false;
    }
  }

  // 登出
  Future<void> logout() async {
    _logger.info('开始登出操作');
    await _authService.logout();
    _isLoggedIn = false;
    _userInfo = null;
    _clearError();
    
    // 停止token刷新定时器
    _stopTokenRefreshTimer();
    
    _logger.info('登出操作完成');
    notifyListeners();
  }

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 设置错误信息
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // 清除错误信息
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 清除错误信息（公开方法）
  void clearError() {
    _clearError();
  }

  // 重新初始化认证服务（用于设置更改后）
  Future<void> reinitialize() async {
    _logger.info('重新初始化认证服务');
    await _authService.reinitialize();
  }

  // 启动token刷新定时器
  void _startTokenRefreshTimer() async {
    _stopTokenRefreshTimer(); // 先停止之前的定时器
    
    // 获取用户设置的token刷新间隔
    final refreshInterval = await AppConfig.getTokenRefreshInterval();
    _logger.info('启动token刷新定时器，间隔: ${refreshInterval}ms');
    
    // 使用用户设置的间隔刷新token
    _tokenRefreshTimer = Timer.periodic(
      Duration(milliseconds: refreshInterval),
      (timer) async {
        if (_isLoggedIn) {
          final success = await refreshUserInfo();
          if (!success) {
            // 如果刷新失败，停止定时器
            _logger.warning('Token刷新失败，停止定时器');
            _stopTokenRefreshTimer();
          }
        } else {
          // 如果未登录，停止定时器
          _logger.info('用户未登录，停止token刷新定时器');
          _stopTokenRefreshTimer();
        }
      },
    );
  }

  // 停止token刷新定时器
  void _stopTokenRefreshTimer() {
    if (_tokenRefreshTimer != null) {
      _logger.info('停止token刷新定时器');
      _tokenRefreshTimer?.cancel();
      _tokenRefreshTimer = null;
    }
  }

  // 模拟登录成功（用于测试）
  Future<bool> mockLogin() async {
    _logger.info('开始模拟登录');
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.mockLogin();

      if (result['success']) {
        _isLoggedIn = true;
        _userInfo = UserInfo.fromJson(result['data']);
        _clearError();
        
        _logger.info('模拟登录成功');
        
        // 启动token刷新定时器
        _startTokenRefreshTimer();
        
        notifyListeners();
        return true;
      } else {
        _logger.warning('模拟登录失败: ${result['message']}');
        _setError(result['message'] ?? '模拟登录失败');
        return false;
      }
    } catch (e) {
      _logger.severe('模拟登录异常: $e');
      _setError('模拟登录异常: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
} 