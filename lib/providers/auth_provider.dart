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

    notifyListeners();
  }

  // 自动登录
  Future<bool> autoLogin({
    String? username,
    String? password,
    String? serverIp,
    String? apiPort,
  }) async {
    // 如果已经登录，直接返回成功
    if (_isLoggedIn) {
      _logger.info('用户已登录，跳过自动登录');
      return true;
    }

    final loginUsername = username ?? AppConfig.username;
    final loginPassword = password ?? AppConfig.password;

    _logger.info('开始自动登录');
    _logger.info('用户名: $loginUsername');
    _logger.info('服务器: ${_authService.baseUrl}');

    // 不设置loading状态，避免阻塞UI
    _clearError();

    try {
      final result = await _authService.login(
        account: loginUsername,
        password: loginPassword,
      );

      _logger.info('登录结果: $result');

      if (result['success']) {
        _isLoggedIn = true;
        // 登录成功后不赋值 _userInfo，也不调用 refreshUserInfo
        _clearError();

        _logger.info('自动登录成功');

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
    }
  }

  // 手动登录
  Future<bool> login({
    required String username,
    required String password,
    String? serverIp,
    String? apiPort,
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
        // 登录成功后不赋值 _userInfo，也不调用 refreshUserInfo
        _clearError();

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

  // 登出
  Future<void> logout() async {
    _logger.info('开始登出操作');
    await _authService.logout();
    _isLoggedIn = false;
    _userInfo = null;
    _clearError();

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
}
