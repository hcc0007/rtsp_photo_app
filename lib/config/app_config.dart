import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'dart:convert';

final Logger _logger = Logger('AppConfig');

class AppConfig {
  static final Map<String, dynamic> _default = {
    'apiPort': '8080',
    'apiUrl': 'http://192.168.3.169',
    'defaultRtspUrl': 'rtsp://192.168.3.169:8554/mystream',
    'tokenRefreshInterval': 25 * 60 * 1000,
    'connectTimeout': 100000,
    'receiveTimeout': 100000,
    'strangerDisplayTime': 10000,
    'normalPersonDisplayTime': 5000,
    'strangerFilterTimeWindow': 30000,
    'normalPersonFilterTimeWindow': 45000,
    'normalPersonMaxDisplayCount': 5,
    'strangerMaxDisplayCount': 10,
    'username': 'ops',
    'password': 'Test@001',
    'token': '',
    'logLevel': 'INFO',
    'logEnabled': true,
    'logToFile': false,
    'logMaxFileSize': 10 * 1024 * 1024,
    'logMaxFileCount': 5,
    'company': '云南省委',
    'videoAspectRatio': 16 / 9,
    'videoSectionRatio': 0.3,
    'photoSectionRatio': 0.7,
  };
  static String company = '云南省委';

  // 人脸推送过滤配置
  static int strangerDisplayTime = 10000; // 陌生人显示时间（毫秒）
  static int normalPersonDisplayTime = 5000; // 普通人员显示时间（毫秒）

  // 根据人员类型的过滤时间窗口配置
  static int strangerFilterTimeWindow = 30000; // 陌生人过滤时间窗口（毫秒）
  static int normalPersonFilterTimeWindow = 45000; // 普通人员过滤时间窗口（毫秒）

  // 展示数量限制配置
  static int normalPersonMaxDisplayCount = 5; // 普通人员最大展示数量
  static int strangerMaxDisplayCount = 10; // 陌生人最大展示数量

  // 服务器地址
  static String apiUrl = 'http://192.168.3.169';
  static String apiPort = '8080';

  // RTSP配置
  static String defaultRtspUrl = 'rtsp://192.168.3.169:8554/mystream';

  // 认证配置
  static String username = 'ops';
  static String password = 'Test@001';
  static String token = '';

  // 刷新间隔配置
  static int photoRefreshInterval = 1000; // 1秒
  static int photoAutoPlayInterval = 3000; // 3秒
  static int tokenRefreshInterval = 25 * 60 * 1000; // 25分钟（在30分钟过期前刷新）
  static int connectTimeout = 100000; // 连接超时时间
  static int receiveTimeout = 100000; // 接收超时时间

  // 视频播放配置
  static const double videoAspectRatio = 16 / 9;

  // 界面配置
  static const double videoSectionRatio = 0.3; // 视频区域占比
  static const double photoSectionRatio = 0.7; // 照片区域占比

  // 缓存键名常量
  static const String _keyServerUrl = 'server_url';
  static const String _keyServerPort = 'server_port';
  static const String _keyRtspUrl = 'rtsp_url';
  static const String _keyTokenRefreshInterval = 'token_refresh_interval';
  static const String _keyStrangerDisplayTime = 'stranger_display_time';
  static const String _keyNormalPersonDisplayTime =
      'normal_person_display_time';

  // 根据人员类型的过滤时间窗口配置键名
  static const String _keyStrangerFilterTimeWindow =
      'stranger_filter_time_window';
  static const String _keyNormalPersonFilterTimeWindow =
      'normal_person_filter_time_window';

  // 展示数量限制配置键名
  static const String _keyNormalPersonMaxDisplayCount =
      'normal_person_max_display_count';
  static const String _keyStrangerMaxDisplayCount =
      'stranger_max_display_count';

  // Logger配置常量
  static const String _keyLogLevel = 'log_level';
  static const String _keyLogEnabled = 'log_enabled';
  static const String _keyLogToFile = 'log_to_file';
  static const String _keyLogMaxFileSize = 'log_max_file_size';
  static const String _keyLogMaxFileCount = 'log_max_file_count';

  // Logger默认配置
  static const Level defaultLogLevel = Level.INFO;
  static const bool defaultLogEnabled = true;
  static const bool defaultLogToFile = false;
  static const int defaultLogMaxFileSize = 10 * 1024 * 1024; // 10MB
  static const int defaultLogMaxFileCount = 5;

  // userName、password、token 缓存键名
  static const String _keyUserName = 'user_name';
  static const String _keyPassword = 'password';
  static const String _keyToken = 'token';
  static const String _keyUserInfo = 'user_info';

  // 初始化配置
  static Future<void> initialize() async {
    print('AppConfig 初始化开始');
    try {
      _logger.info('开始初始化AppConfig...');

      final prefs = await SharedPreferences.getInstance();

      // 检查并设置默认值（如果不存在）
      await _setDefaultIfNotExists(prefs, _keyServerUrl, _default['apiUrl']);
      await _setDefaultIfNotExists(prefs, _keyServerPort, _default['apiPort']);
      await _setDefaultIfNotExists(
        prefs,
        _keyRtspUrl,
        _default['defaultRtspUrl'],
      );
      await _setDefaultIfNotExists(
        prefs,
        _keyTokenRefreshInterval,
        _default['tokenRefreshInterval'],
      );
      await _setDefaultIfNotExists(
        prefs,
        _keyStrangerDisplayTime,
        _default['strangerDisplayTime'],
      );
      await _setDefaultIfNotExists(
        prefs,
        _keyNormalPersonDisplayTime,
        _default['normalPersonDisplayTime'],
      );

      // 设置根据人员类型的过滤时间窗口默认值
      await _setDefaultIfNotExists(
        prefs,
        _keyStrangerFilterTimeWindow,
        _default['strangerFilterTimeWindow'],
      );
      await _setDefaultIfNotExists(
        prefs,
        _keyNormalPersonFilterTimeWindow,
        _default['normalPersonFilterTimeWindow'],
      );

      // 设置展示数量限制默认值
      await _setDefaultIfNotExists(
        prefs,
        _keyNormalPersonMaxDisplayCount,
        _default['normalPersonMaxDisplayCount'],
      );
      await _setDefaultIfNotExists(
        prefs,
        _keyStrangerMaxDisplayCount,
        _default['strangerMaxDisplayCount'],
      );

      // 用户名、密码、token
      await _setDefaultIfNotExists(prefs, _keyUserName, _default['username']);
      await _setDefaultIfNotExists(prefs, _keyPassword, _default['password']);
      await _setDefaultIfNotExists(prefs, _keyToken, _default['token']);

      // 初始化Logger配置
      await _setDefaultIfNotExists(prefs, _keyLogLevel, defaultLogLevel.name);
      await _setDefaultIfNotExists(prefs, _keyLogEnabled, defaultLogEnabled);
      await _setDefaultIfNotExists(prefs, _keyLogToFile, defaultLogToFile);
      await _setDefaultIfNotExists(
        prefs,
        _keyLogMaxFileSize,
        defaultLogMaxFileSize,
      );
      await _setDefaultIfNotExists(
        prefs,
        _keyLogMaxFileCount,
        defaultLogMaxFileCount,
      );

      updateAppConfig();

      _logger.info('AppConfig初始化完成');

      // 输出当前配置信息
      await _logCurrentConfig();
    } catch (e, stackTrace) {
      _logger.severe('AppConfig初始化失败', e, stackTrace);
      rethrow;
    }
    print('AppConfig 初始化结束');
  }

  static Future<void> updateAppConfig() async {
    // 获取配置值
    apiUrl = await getServerUrl();
    apiPort = await getServerPort();
    defaultRtspUrl = await getRtspUrl();
    strangerDisplayTime = await getStrangerDisplayTime();
    normalPersonDisplayTime = await getNormalPersonDisplayTime();
    strangerFilterTimeWindow = await getStrangerFilterTimeWindow();
    normalPersonFilterTimeWindow = await getNormalPersonFilterTimeWindow();
    normalPersonMaxDisplayCount = await getNormalPersonMaxDisplayCount();
    // 同步 userName、password、token
    username = await getUserName();
    password = await getPassword();
    token = await getToken();
  }

  // 设置默认值（如果不存在）
  static Future<void> _setDefaultIfNotExists(
    SharedPreferences prefs,
    String key,
    dynamic defaultValue,
  ) async {
    if (!prefs.containsKey(key)) {
      if (defaultValue is String) {
        await prefs.setString(key, defaultValue);
      } else if (defaultValue is int) {
        await prefs.setInt(key, defaultValue);
      } else if (defaultValue is bool) {
        await prefs.setBool(key, defaultValue);
      }
      _logger.fine('设置默认值: $key = $defaultValue');
    }
  }

  // 输出当前配置信息
  static Future<void> _logCurrentConfig() async {
    _logger.info('当前配置信息:');
    _logger.info('服务器地址: ${await getServerUrl()}');
    _logger.info('服务器端口: ${await getServerPort()}');
    _logger.info('RTSP地址: ${await getRtspUrl()}');
    _logger.info('陌生人显示时间: ${await getStrangerDisplayTime()}ms');
    _logger.info('普通人员显示时间: ${await getNormalPersonDisplayTime()}ms');
  }

  // 重置所有配置为默认值
  static Future<void> resetToDefaults() async {
    try {
      _logger.info('重置所有配置为默认值...');

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyServerUrl, _default['apiUrl']);
      await prefs.setString(_keyServerPort, _default['apiPort']);
      await prefs.setString(_keyRtspUrl, _default['defaultRtspUrl']);
      await prefs.setInt(
        _keyTokenRefreshInterval,
        _default['tokenRefreshInterval'],
      );
      await prefs.setInt(
        _keyStrangerDisplayTime,
        _default['strangerDisplayTime'],
      );
      await prefs.setInt(
        _keyNormalPersonDisplayTime,
        _default['normalPersonDisplayTime'],
      );

      // 重置根据人员类型的过滤时间窗口配置
      await prefs.setInt(
        _keyStrangerFilterTimeWindow,
        _default['strangerFilterTimeWindow'],
      );
      await prefs.setInt(
        _keyNormalPersonFilterTimeWindow,
        _default['normalPersonFilterTimeWindow'],
      );

      // 重置展示数量限制配置
      await prefs.setInt(
        _keyNormalPersonMaxDisplayCount,
        _default['normalPersonMaxDisplayCount'],
      );
      await prefs.setInt(
        _keyStrangerMaxDisplayCount,
        _default['strangerMaxDisplayCount'],
      );

      updateAppConfig();

      _logger.info('配置已重置为默认值');
    } catch (e, stackTrace) {
      _logger.severe('重置配置失败', e, stackTrace);
      rethrow;
    }
  }

  // 获取用户设置的服务器地址
  static Future<String> getServerUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_keyServerUrl);
      _logger.fine('获取服务器地址: $value');
      return (value == null || value.isEmpty) ? _default['apiUrl'] : value;
    } catch (e) {
      _logger.warning('获取服务器地址失败，使用默认值', e);
      return _default['apiUrl'];
    }
  }

  // 获取用户设置的服务器端口
  static Future<String> getServerPort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_keyServerPort);
      _logger.fine('获取服务器端口: $value');
      return (value == null || value.isEmpty) ? _default['apiPort'] : value;
    } catch (e) {
      _logger.warning('获取服务器端口失败，使用默认值', e);
      return _default['apiPort'];
    }
  }

  // 获取用户设置的RTSP地址
  static Future<String> getRtspUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_keyRtspUrl) ?? _default['defaultRtspUrl'];
      _logger.fine('获取RTSP地址: $value');
      return value;
    } catch (e) {
      _logger.warning('获取RTSP地址失败，使用默认值', e);
      return _default['defaultRtspUrl'];
    }
  }

  // 构建完整的服务器URL
  static Future<String> getFullServerUrl() async {
    try {
      final apiUrl = await getServerUrl();
      final apiPort = await getServerPort();

      String fullUrl;
      if (apiPort.isNotEmpty) {
        fullUrl = '$apiUrl:$apiPort';
      } else {
        fullUrl = 'https://$apiUrl';
      }

      return fullUrl;
    } catch (e) {
      _logger.warning('构建服务器URL失败', e);
      return '$apiUrl:$apiPort';
    }
  }

  static Future<int> getStrangerDisplayTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value =
          prefs.getInt(_keyStrangerDisplayTime) ??
          _default['strangerDisplayTime'];
      _logger.fine('获取陌生人显示时间: ${value}ms');
      return value;
    } catch (e) {
      _logger.warning('获取陌生人显示时间失败，使用默认值', e);
      return _default['strangerDisplayTime'];
    }
  }

  static Future<int> getNormalPersonDisplayTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value =
          prefs.getInt(_keyNormalPersonDisplayTime) ??
          _default['normalPersonDisplayTime'];
      _logger.fine('获取普通人员显示时间: ${value}ms');
      return value;
    } catch (e) {
      _logger.warning('获取普通人员显示时间失败，使用默认值', e);
      return _default['normalPersonDisplayTime'];
    }
  }

  // 根据人员类型获取过滤时间窗口
  static Future<int> getStrangerFilterTimeWindow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value =
          prefs.getInt(_keyStrangerFilterTimeWindow) ??
          _default['strangerFilterTimeWindow'];
      _logger.fine('获取陌生人过滤时间窗口: ${value}ms');
      return value;
    } catch (e) {
      _logger.warning('获取陌生人过滤时间窗口失败，使用默认值', e);
      return _default['strangerFilterTimeWindow'];
    }
  }

  static Future<int> getNormalPersonFilterTimeWindow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value =
          prefs.getInt(_keyNormalPersonFilterTimeWindow) ??
          _default['normalPersonFilterTimeWindow'];
      _logger.fine('获取普通人员过滤时间窗口: ${value}ms');
      return value;
    } catch (e) {
      _logger.warning('获取普通人员过滤时间窗口失败，使用默认值', e);
      return _default['normalPersonFilterTimeWindow'];
    }
  }

  // 获取展示数量限制
  static Future<int> getNormalPersonMaxDisplayCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value =
          prefs.getInt(_keyNormalPersonMaxDisplayCount) ??
          _default['normalPersonMaxDisplayCount'];
      _logger.fine('获取普通人员最大展示数量: $value');
      return value;
    } catch (e) {
      _logger.warning('获取普通人员最大展示数量失败，使用默认值', e);
      return _default['normalPersonMaxDisplayCount'];
    }
  }

  static Future<int> getStrangerMaxDisplayCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value =
          prefs.getInt(_keyStrangerMaxDisplayCount) ??
          _default['strangerMaxDisplayCount'];
      _logger.fine('获取陌生人最大展示数量: $value');
      return value;
    } catch (e) {
      _logger.warning('获取陌生人最大展示数量失败，使用默认值', e);
      return strangerMaxDisplayCount;
    }
  }

  // 设置服务器地址
  static Future<void> setServerUrl(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyServerUrl, value);
      _logger.info('设置服务器地址: $value');
    } catch (e) {
      _logger.severe('设置服务器地址失败', e);
      rethrow;
    }
  }

  // 设置服务器端口
  static Future<void> setServerPort(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyServerPort, value);
      _logger.info('设置服务器端口: $value');
    } catch (e) {
      _logger.severe('设置服务器端口失败', e);
      rethrow;
    }
  }

  // 设置RTSP地址
  static Future<void> setRtspUrl(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRtspUrl, value);
      _logger.info('设置RTSP地址: $value');
    } catch (e) {
      _logger.severe('设置RTSP地址失败', e);
      rethrow;
    }
  }

  // 设置陌生人显示时间
  static Future<void> setStrangerDisplayTime(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyStrangerDisplayTime, value);
      _logger.info('设置陌生人显示时间: ${value}ms');
    } catch (e) {
      _logger.severe('设置陌生人显示时间失败', e);
      rethrow;
    }
  }

  // 设置普通人员显示时间
  static Future<void> setNormalPersonDisplayTime(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyNormalPersonDisplayTime, value);
      _logger.info('设置普通人员显示时间: ${value}ms');
    } catch (e) {
      _logger.severe('设置普通人员显示时间失败', e);
      rethrow;
    }
  }

  // 设置陌生人过滤时间窗口
  static Future<void> setStrangerFilterTimeWindow(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyStrangerFilterTimeWindow, value);
      _logger.info('设置陌生人过滤时间窗口: ${value}ms');
    } catch (e) {
      _logger.severe('设置陌生人过滤时间窗口失败', e);
      rethrow;
    }
  }

  // 设置普通人员过滤时间窗口
  static Future<void> setNormalPersonFilterTimeWindow(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyNormalPersonFilterTimeWindow, value);
      _logger.info('设置普通人员过滤时间窗口: ${value}ms');
    } catch (e) {
      _logger.severe('设置普通人员过滤时间窗口失败', e);
      rethrow;
    }
  }

  // 设置普通人员最大展示数量
  static Future<void> setNormalPersonMaxDisplayCount(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyNormalPersonMaxDisplayCount, value);
      _logger.info('设置普通人员最大展示数量: $value');
    } catch (e) {
      _logger.severe('设置普通人员最大展示数量失败', e);
      rethrow;
    }
  }

  // 设置陌生人最大展示数量
  static Future<void> setStrangerMaxDisplayCount(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyStrangerMaxDisplayCount, value);
      _logger.info('设置陌生人最大展示数量: $value');
    } catch (e) {
      _logger.severe('设置陌生人最大展示数量失败', e);
      rethrow;
    }
  }

  // 设置 userName
  static Future<void> setUserName(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserName, value);
      username = value;
      _logger.info('设置userName: $value');
    } catch (e) {
      _logger.severe('设置userName失败', e);
      rethrow;
    }
  }

  // 获取 userName
  static Future<String> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_keyUserName) ?? '';
      _logger.fine('获取userName: $value');
      username = value;
      return value;
    } catch (e) {
      _logger.warning('获取userName失败，使用空字符串', e);
      return '';
    }
  }

  // 设置 password
  static Future<void> setPassword(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPassword, value);
      password = value;
      _logger.info('设置password: $value');
    } catch (e) {
      _logger.severe('设置password失败', e);
      rethrow;
    }
  }

  // 获取 password
  static Future<String> getPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_keyPassword) ?? '';
      _logger.fine('获取password: $value');
      password = value;
      return value;
    } catch (e) {
      _logger.warning('获取password失败，使用空字符串', e);
      return '';
    }
  }

  // 获取 token
  static Future<String> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_keyToken) ?? '';
      _logger.fine('获取token: $value');
      token = value;
      return value;
    } catch (e) {
      _logger.warning('获取token失败，使用空字符串', e);
      return '';
    }
  }

  // 设置 token
  static Future<void> setToken(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, value);
      token = value;
      _logger.info('设置token: $value');
    } catch (e) {
      _logger.severe('设置token失败', e);
      rethrow;
    }
  }

  // 获取用户信息
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString(_keyUserInfo);
      if (userInfoString != null) {
        final userInfo = json.decode(userInfoString) as Map<String, dynamic>;
        _logger.fine('获取用户信息成功');
        return userInfo;
      }
      _logger.fine('用户信息不存在');
      return null;
    } catch (e) {
      _logger.warning('获取用户信息失败', e);
      return null;
    }
  }

  // 设置用户信息
  static Future<void> setUserInfo(Map<String, dynamic> userInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserInfo, json.encode(userInfo));
      _logger.info('设置用户信息成功');
    } catch (e) {
      _logger.severe('设置用户信息失败', e);
      rethrow;
    }
  }

  // 清除用户信息
  static Future<void> clearUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserInfo);
      _logger.info('清除用户信息成功');
    } catch (e) {
      _logger.severe('清除用户信息失败', e);
      rethrow;
    }
  }
}
