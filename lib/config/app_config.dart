class AppConfig {
  // RTSP配置
  static const String defaultRtspUrl = 'rtsp://your-rtsp-url:554/stream';
  
  // API配置
  static const String defaultApiUrl = 'https://your-api-endpoint.com/photos';
  
  // 刷新间隔配置
  static const int photoRefreshInterval = 5000; // 5秒
  static const int photoAutoPlayInterval = 3000; // 3秒
  
  // 视频播放配置
  static const double videoAspectRatio = 16 / 9;
  
  // 界面配置
  static const double videoSectionRatio = 0.6; // 视频区域占比
  static const double photoSectionRatio = 0.4; // 照片区域占比
} 