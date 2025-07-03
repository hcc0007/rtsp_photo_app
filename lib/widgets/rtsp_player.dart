import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class RtspPlayer extends StatefulWidget {
  final String rtspUrl;
  
  const RtspPlayer({
    super.key,
    required this.rtspUrl,
  });

  @override
  State<RtspPlayer> createState() => _RtspPlayerState();
}

class _RtspPlayerState extends State<RtspPlayer> {
  late VlcPlayerController _videoPlayerController;
  bool _isPlaying = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      _videoPlayerController = VlcPlayerController.network(
        widget.rtspUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
      );
      
      // 监听播放状态
      _videoPlayerController.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _videoPlayerController.value.isPlaying;
            _isInitialized = true;
          });
        }
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = '初始化播放器失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }
    
    if (!_isInitialized) {
      return _buildLoadingWidget();
    }
    
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // VLC播放器
          VlcPlayer(
            controller: _videoPlayerController,
            aspectRatio: 16 / 9,
            placeholder: _buildLoadingWidget(),
          ),
          
          // 播放状态指示器
          if (!_isPlaying)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '连接中...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '未知错误',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _initializePlayer();
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
    _videoPlayerController.dispose();
    super.dispose();
  }
} 