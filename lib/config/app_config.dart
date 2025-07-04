import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // Mock数据开关
  static const bool showMockData = false; // 设置为true使用mock数据，false使用真实数据
  
  
  // 服务器地址
  static const String defaultServerUrl = 'http://192.168.3.169';
  static const String defaultServerPort = '8080';

  // WebSocket配置
  static const String defaultWebSocketUrl = 'ws://192.168.3.169:8080';

  // RTSP配置
  static const String defaultRtspUrl = 'rtsp://192.168.3.169:8554/mystream';
  
  // API配置
  static const String defaultApiUrl = 'https://your-api-endpoint.com/photos';
  
  // 认证配置
  static const String defaultUsername = 'ops';
  static const String defaultPassword = 'Test@001';
  
  // 刷新间隔配置
  static const int photoRefreshInterval = 1000; // 5秒
  static const int photoAutoPlayInterval = 3000; // 3秒
  static const int tokenRefreshInterval = 25 * 60 * 1000; // 25分钟（在30分钟过期前刷新）
  static const int connectTimeout = 100000; // 连接超时时间
  static const int receiveTimeout = 100000; // 接收超时时间
  
  
  // 视频播放配置
  static const double videoAspectRatio = 16 / 9;
  
  // 界面配置
  static const double videoSectionRatio = 0.3; // 视频区域占比
  static const double photoSectionRatio = 0.7; // 照片区域占比

  // 获取用户设置的服务器地址
  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_url') ?? defaultServerUrl;
  }

  // 获取用户设置的服务器端口
  static Future<String> getServerPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_port') ?? defaultServerPort;
  }

  // 获取用户设置的RTSP地址
  static Future<String> getRtspUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rtsp_url') ?? defaultRtspUrl;
  }

  // 获取用户设置的API地址
  static Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_url') ?? defaultApiUrl;
  }

  // 获取用户设置的token刷新间隔
  static Future<int> getTokenRefreshInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('token_refresh_interval') ?? tokenRefreshInterval;
  }

  // 构建完整的服务器URL
  static Future<String> getFullServerUrl() async {
    final serverUrl = await getServerUrl();
    final serverPort = await getServerPort();
    
    if (serverPort.isNotEmpty) {
      return '$serverUrl:$serverPort';
    } else {
      return 'https://$serverUrl';
    }
  }
} 