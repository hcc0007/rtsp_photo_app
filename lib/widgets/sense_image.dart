import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:rtsp_photo_app/providers/auth_provider.dart';
import 'package:rtsp_photo_app/services/http_client.dart';
import 'package:logging/logging.dart';

final _logger = Logger('SenseImage');

class SenseImage extends StatefulWidget {
  final _apiClient = ApiClient();
  final String objectKey;
  final double? width;
  final double? height;
  final BoxFit fit;

  SenseImage({
    super.key,
    required this.objectKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<SenseImage> createState() => _SenseImageState();
}

class _SenseImageState extends State<SenseImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.objectKey.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '图片标识为空';
      });
      return;
    }

    final url = '${widget._apiClient.baseUrl}/gateway/sys/api/v1/images/${widget.objectKey}';
    final authInfo = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).authService;
    final token = authInfo.token;
    
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '未登录或token无效';
      });
      _logger.warning('图片加载失败：未登录或token无效');
      return;
    }

    final headers = {ApiClient.tokenKey: token};
    final ts = DateTime.now().millisecondsSinceEpoch;
    _logger.info('[$ts] 开始加载图片 ==> url: $url, objectKey: ${widget.objectKey}');
    
    try {
      final response = await Dio().request(
        url,
        options: Options(
          method: 'GET', 
          headers: {ApiClient.tokenKey: token},
          // responseType: ResponseType.bytes, // 明确指定响应类型为字节
        ),
      );
      
      _logger.info('[$ts] 图片加载成功 ==> 响应状态: ${response.statusCode}, 数据大小: ${response.data?.length ?? 0} 字节');
      
      if (response.data != null && response.data is List<int>) {
        setState(() {
          _imageBytes = Uint8List.fromList(response.data);
          _isLoading = false;
          _errorMessage = null;
        });
        _logger.info('[$ts] 图片数据设置成功，大小: ${_imageBytes!.length} 字节');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '服务器返回的数据格式无效';
        });
        _logger.severe('[$ts] 图片加载失败：服务器返回的数据格式无效');
      }
    } catch (e, stack) {
      setState(() {
        _isLoading = false;
        _errorMessage = '图片加载失败: $e';
      });
      _logger.severe('[$ts] 图片加载失败: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '加载中...',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 24,
                color: Colors.grey[600],
              ),
              SizedBox(height: 4),
              Text(
                '加载失败',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_imageBytes == null || _imageBytes!.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 24,
                color: Colors.grey[600],
              ),
              SizedBox(height: 4),
              Text(
                '无图片',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Image.memory(
      _imageBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        _logger.severe('Image.memory 渲染失败: $error');
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 24,
                  color: Colors.grey[600],
                ),
                SizedBox(height: 4),
                Text(
                  '图片损坏',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
