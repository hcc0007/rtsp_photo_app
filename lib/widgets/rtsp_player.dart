import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RtspPlayer extends StatefulWidget {
  final String rtspUrl;

  const RtspPlayer({super.key, required this.rtspUrl});

  @override
  State<RtspPlayer> createState() => _RtspPlayerState();
}

class _RtspPlayerState extends State<RtspPlayer> {
  VlcPlayerController? _videoPlayerController;
  bool _isPlaying = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // 新增：日志和状态
  List<String> _logs = [];
  String _status = '准备连接';
  Timer? _timeoutTimer;
  bool _networkOk = false;
  bool _connecting = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _logDeviceAndNetworkInfo();
    _checkInternetPermissionAndStart();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && _isInitialized) {
        try {
          final value = _videoPlayerController!.value;
          _addLog(
            'VLC状态: isPlaying=${value.isPlaying}, hasError=${value.hasError}, position=${value.position}, duration=${value.duration}, errorMsg=${value.errorDescription}',
          );
        } catch (e) {
          _addLog('VLC状态获取异常: $e');
        }
      }
    });
  }

  void _addLog(String msg) {
    final now = DateTime.now();
    final timeStr =
        '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}] ';
    print(timeStr + msg);
    // 可以在这里添加全局日志记录
    // 暂时使用print输出
    setState(() {
      _logs.add(timeStr + msg);
      if (_logs.length > 10) _logs.removeAt(0);
    });
  }

  Future<void> _logDeviceAndNetworkInfo() async {
    try {
      // 设备信息
      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceStr = '';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceStr =
            '设备: ${androidInfo.brand} ${androidInfo.model} Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceStr =
            '设备: ${iosInfo.name} ${iosInfo.model} iOS ${iosInfo.systemVersion}';
      }
      _addLog(deviceStr);
      // App版本
      final packageInfo = await PackageInfo.fromPlatform();
      _addLog('App版本: ${packageInfo.version}+${packageInfo.buildNumber}');
      // 网络类型
      final connectivityResult = await Connectivity().checkConnectivity();
      _addLog('网络类型: ${connectivityResult.toString()}');
    } catch (e) {
      _addLog('设备/网络信息获取异常: $e');
    }
  }

  Future<void> _checkInternetPermissionAndStart() async {
    // Android: 检查INTERNET权限（实际上INTERNET权限是普通权限，安装时自动授予，但我们可以检测并记录）
    bool hasPermission = true;
    String platformMsg = '';
    try {
      if (Platform.isAndroid) {
        // 通过PlatformChannel检测权限（虽然INTERNET权限一般不会被拒绝）
        const platform = MethodChannel('rtsp_photo_app/permissions');
        final result = await platform.invokeMethod('checkInternetPermission');
        hasPermission = result == true;
        platformMsg = 'Android权限检测: $hasPermission';
      } else {
        platformMsg = '非Android平台，无需检测INTERNET权限';
      }
    } catch (e) {
      hasPermission = false;
      platformMsg = '权限检测异常: $e';
    }
    _addLog('权限检测: $platformMsg');
    if (!hasPermission) {
      setState(() {
        _errorMessage = '未获取INTERNET权限，无法连接视频流';
        _status = '权限不足';
        _connecting = false;
      });
      return;
    }
    _startConnectProcess();
  }

  Future<void> _startConnectProcess() async {
    setState(() {
      _status = '检测网络连通性...';
      _logs.clear();
      _networkOk = false;
      _connecting = true;
      _errorMessage = null;
      _isInitialized = false;
    });
    _addLog('即将连接: ${widget.rtspUrl}');
    // 1. 网络检测
    final uri = Uri.parse(widget.rtspUrl);
    String host = uri.host;
    int port = uri.port > 0 ? uri.port : 554;
    _addLog('检测网络: $host:$port');
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      _addLog('网络连通: $host:$port');
      setState(() {
        _networkOk = true;
        _status = '网络正常，准备连接视频流...';
      });
    } catch (e) {
      _addLog('网络不可达: $host:$port, 错误: $e');
      setState(() {
        _networkOk = false;
        _status = '网络不可达，无法连接视频流';
        _errorMessage = '网络不可达: $host:$port';
        _connecting = false;
      });
      return;
    }
    // 2. 开始连接，启动超时计时器
    _addLog('开始连接RTSP流...');
    setState(() {
      _status = '正在连接视频流...';
    });
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      _addLog('连接超时（5分钟）');
      setState(() {
        _errorMessage = '连接超时（5分钟）';
        _status = '连接超时';
        _connecting = false;
      });
    });
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      if (_isInitialized) return;
      _videoPlayerController = VlcPlayerController.network(
        widget.rtspUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
      );
      _videoPlayerController!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _videoPlayerController!.value.isPlaying;
            _isInitialized = true;
            if (_isPlaying) {
              _addLog('视频流连接成功，正在播放');
              _status = '播放中';
              _timeoutTimer?.cancel();
              _connecting = false;
            } else {
              _status = '连接中...';
            }
          });
        }
      });
    } catch (e) {
      _addLog('初始化播放器失败: $e');
      setState(() {
        _errorMessage = '初始化播放器失败: $e';
        _status = '初始化失败';
        _connecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.withValues(alpha: 0.3),
      child: Stack(
        children: [
          if (_errorMessage != null)
            _buildErrorWidget()
          else if (!_isInitialized || _videoPlayerController == null)
            _buildLoadingWidget()
          else
            VlcPlayer(
              controller: _videoPlayerController!,
              aspectRatio: 16 / 9,
              placeholder: _buildLoadingWidget(),
            ),
          // 状态和日志面板
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              width: 200,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '状态: $_status',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '日志:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    ..._logs
                        .map(
                          (e) => Text(
                            e,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              '正在连接视频流...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '未知错误',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _startConnectProcess();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _statusTimer?.cancel();
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
