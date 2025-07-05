import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_client.dart';
import 'package:logging/logging.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';
import '../config/app_config.dart';

class AuthService {
  static final String _tokenKey = ApiClient.tokenKey;
  static const String _userInfoKey = 'user_info';

  // 单例模式
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Logger _logger = Logger('AuthService');

  final ApiClient _httpClient = ApiClient();
  String? _token;
  Map<String, dynamic>? _userInfo;

  // 获取token
  String? get token => _token;

  // 获取用户信息
  Map<String, dynamic>? get userInfo => _userInfo;

  // 检查是否已登录
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // 获取基础URL
  String get baseUrl => _httpClient.baseUrl;

  // 初始化服务
  Future<void> initialize() async {
    await _loadTokenFromStorage();
    await _loadUserInfoFromStorage();
    _httpClient.setAuthToken(_token);

    // 设置基础URL
    final serverUrl = await _getServerUrl();
    _httpClient.setBaseUrl(serverUrl);
  }

  // 重新初始化服务（用于设置更改后）
  Future<void> reinitialize() async {
    // 重新设置基础URL
    final serverUrl = await _getServerUrl();
    _httpClient.setBaseUrl(serverUrl);
    _logger.info('重新初始化AuthService，新的服务器URL: $serverUrl');
  }

  // 获取服务器URL
  Future<String> _getServerUrl() async {
    // 从AppConfig获取用户设置的服务器URL
    final serverUrl = await AppConfig.getServerUrl();
    final serverPort = await AppConfig.getServerPort();

    if (serverPort.isNotEmpty) {
      return '$serverUrl:$serverPort';
    } else {
      return serverUrl;
    }
  }

  // 从本地存储加载token
  Future<void> _loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  // 从本地存储加载用户信息
  Future<void> _loadUserInfoFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString(_userInfoKey);
    if (userInfoString != null) {
      _userInfo = json.decode(userInfoString);
    }
  }

  // 保存token到本地存储
  Future<void> _saveTokenToStorage(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 保存用户信息到本地存储
  Future<void> _saveUserInfoToStorage(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userInfoKey, json.encode(userInfo));
  }

  // 获取RSA公钥和rsaId
  Future<Map<String, String>?> _fetchRsaPub() async {
    try {
      final response = await _httpClient.get('/gateway/auth/api/v1/rsapub');
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        return {
          'publicKey': data['publicKey'] as String,
          'rsaId': data['rsaId'] as String,
        };
      }
      return null;
    } catch (e) {
      _logger.severe('获取RSA公钥失败: $e');
      return null;
    }
  }

  // 用RSA公钥加密密码
  String _encryptPasswordRsa(String password, String publicKeyPem) {
    final correctPem =
        '-----BEGIN PUBLIC KEY-----\n$publicKeyPem\n-----END PUBLIC KEY-----';
    try {
      final parser = RSAKeyParser();
      final publicKey = parser.parse(correctPem) as RSAPublicKey;
      final encrypter = Encrypter(
        RSA(publicKey: publicKey, encoding: RSAEncoding.PKCS1),
      );
      final encrypted = encrypter.encrypt(password);
      return encrypted.base64;
    } catch (e) {
      _logger.severe('RSA加密失败: $e');
      return '';
    }
  }

  // 模拟登录成功（用于测试）
  Future<Map<String, dynamic>> mockLogin() async {
    await Future.delayed(const Duration(seconds: 1));

    final mockUserInfo = {
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'username': 'admin',
      'nickname': '管理员',
      'email': 'admin@example.com',
      'role': 'admin',
      'permissions': ['read', 'write', 'admin'],
      'userId': 1,
    };

    await _updateUserSession(mockUserInfo);
    return {'success': true, 'message': '模拟登录成功', 'data': mockUserInfo};
  }

  // 登录
  Future<Map<String, dynamic>> login({
    required String account,
    required String password,
  }) async {
    try {
      _logger.info('登录账号表单: username: $account, password: $password');
      // 1. 获取RSA公钥和rsaId
      final rsaInfo = await _fetchRsaPub();
      if (rsaInfo == null) {
        return {'success': false, 'message': '获取加密公钥失败'};
      }

      // 2. 用公钥加密密码
      final encryptedPassword = _encryptPasswordRsa(password, rsaInfo['publicKey']!);
      if (encryptedPassword.isEmpty) {
        return {'success': false, 'message': '密码加密失败'};
      }

      final loginData = {
          'account': account,
          'password': encryptedPassword,
          'rsaId': rsaInfo['rsaId'],
          'grantType': 'password',
        };

      _logger.info('登录请求数据: $loginData');

      // 3. 发送登录请求
      final response = await _httpClient.post(
        '/gateway/auth/api/v1/login',
        data: loginData,
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true) {
        await _updateUserSession(responseData['data']);
        return {
          'success': true,
          'message': '登录成功',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
          'code': responseData['code'],
        };
      }
    } catch (e) {
      _logger.severe('登录失败: $e');
      return {'success': false, 'message': '登录失败: $e'};
    }
  }

  // 查询用户详情
  Future<Map<String, dynamic>> getUserDetail() async {
    if (!isLoggedIn) {
      return {'success': false, 'message': '用户未登录'};
    }

    try {
      final response = await _httpClient.get(
        '/gateway/auth/api/v1/user/detail',
      );
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        await _updateUserSession(responseData['data']);
        return {
          'success': true,
          'message': '获取用户信息成功',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
          'code': responseData['code'],
        };
      }
    } catch (e) {
      _logger.severe('获取用户详情失败: $e');
      return {'success': false, 'message': '获取用户详情失败: $e'};
    }
  }

  // 更新用户会话信息
  Future<void> _updateUserSession(Map<String, dynamic> userData) async {
    _token = userData['token'];
    _userInfo = userData;
    _httpClient.setAuthToken(_token);

    await _saveTokenToStorage(_token!);
    await _saveUserInfoToStorage(userData);
  }

  // 登出
  Future<void> logout() async {
    _token = null;
    _userInfo = null;

    // 清除HttpClient的认证token
    _httpClient.clearAuthToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userInfoKey);
  }
}
