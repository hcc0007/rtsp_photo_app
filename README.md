# RTSP视频流和照片展示应用

这是一个使用Flutter开发的Android应用，用于在大屏幕上显示RTSP视频流和照片展示。

## 功能特性

### 1. RTSP视频流播放
- 支持H264编码的RTSP视频流
- 使用VLC播放器进行硬件加速解码
- 自适应屏幕尺寸，适合大屏显示
- 自动重连和错误处理

### 2. 照片展示
- 通过API接口实时获取照片列表
- 自动轮播展示照片
- 支持手动切换照片
- 图片缓存和错误处理

### 3. 设置功能
- 可配置RTSP地址
- 可配置照片API地址
- 设置本地持久化存储

## 安装和运行

### 环境要求
- Flutter SDK 3.8.1+
- Android Studio / VS Code
- Android设备或模拟器

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd rtsp_photo_app
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

## 配置说明

### RTSP地址配置
在设置页面中配置您的RTSP视频流地址，格式如下：
```
rtsp://your-rtsp-server:554/stream
```

### API地址配置
配置获取照片列表的API接口地址，API应返回JSON格式的字符串数组：
```json
[
  "https://example.com/photo1.jpg",
  "https://example.com/photo2.jpg",
  "https://example.com/photo3.jpg"
]
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── config/
│   └── app_config.dart      # 应用配置
├── providers/
│   └── photo_provider.dart  # 照片数据管理
├── screens/
│   ├── home_screen.dart     # 主屏幕
│   └── settings_screen.dart # 设置页面
└── widgets/
    ├── rtsp_player.dart     # RTSP播放器组件
    └── photo_gallery.dart   # 照片展示组件
```

## 依赖包

- `flutter_vlc_player`: RTSP视频流播放
- `http`: HTTP请求
- `cached_network_image`: 图片缓存和加载
- `provider`: 状态管理
- `shared_preferences`: 本地存储

## 使用说明

1. 启动应用后，点击右上角的设置按钮
2. 在设置页面配置您的RTSP地址和API地址
3. 保存设置并返回主界面
4. 应用将自动连接RTSP流并获取照片数据
5. 视频流显示在上方，照片轮播显示在下方

## 注意事项

- 确保RTSP服务器支持H264编码
- 确保API接口返回正确的JSON格式
- 网络连接稳定以确保视频流和照片正常加载
- 建议在大屏设备上使用以获得最佳显示效果

## 故障排除

### 视频流无法播放
- 检查RTSP地址是否正确
- 确认网络连接正常
- 验证RTSP服务器是否在线

### 照片无法加载
- 检查API地址是否正确
- 确认API返回格式是否正确
- 检查网络连接

### 应用崩溃
- 检查Flutter环境是否正确安装
- 确认所有依赖包已正确安装
- 查看控制台错误信息

## 许可证

本项目采用MIT许可证。
