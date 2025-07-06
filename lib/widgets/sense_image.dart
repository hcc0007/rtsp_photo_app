import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:provider/provider.dart';
import 'package:rtsp_photo_app/providers/auth_provider.dart';
import 'package:rtsp_photo_app/services/api_client.dart';
import 'package:rtsp_photo_app/config/app_config.dart';
import 'package:logging/logging.dart';
import 'dart:io';

final _logger = Logger('SenseImage');

class SenseImage extends StatefulWidget {
  final String objectKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? id;

  SenseImage({
    super.key,
    required this.objectKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.id,
  });

  @override
  State<SenseImage> createState() => _SenseImageState();
}

class _SenseImageState extends State<SenseImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _errorMessage;
  String? _lastServerUrl;
  String? _lastObjectKey;
  final String _ts = DateTime.now().millisecondsSinceEpoch.toString();

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
      _logger.warning('[${widget.id ?? _ts}] 图片加载失败：$_errorMessage');
      return;
    }

    // 动态获取服务器地址
    final apiUrl = await AppConfig.getFullServerUrl();

    // 检查服务器地址和objectKey是否发生变化
    if (_lastServerUrl != null &&
        _lastServerUrl == apiUrl &&
        _lastObjectKey != null &&
        _lastObjectKey == widget.objectKey &&
        _imageBytes != null) {
      // 服务器地址和objectKey都没有变化，且图片已加载，不需要重新加载
      return;
    }

    _lastServerUrl = apiUrl;
    _lastObjectKey = widget.objectKey;
    final url = '$apiUrl/gateway/sys/api/v1/images/${widget.objectKey}';

    final authInfo = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).authService;
    final token = authInfo.token;
    final headers = {ApiClient.tokenKey: token};

    _logger.info(
      '[${widget.id ?? _ts}]  开始加载图片 ==> url: $url, objectKey: ${widget.objectKey}, headers: $headers',
    );

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '未登录或token无效';
      });
      _logger.warning('[${widget.id ?? _ts}] 图片加载失败：$_errorMessage');
      return;
    }

    try {
      final dio = Dio();
      // 忽略自签名证书校验，仅开发环境使用！
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) {
              _logger.info('调试模式：忽略证书验证 $host:$port');
              return true;
            };
        return client;
      };
      final response = await dio.request(
        url,
        options: Options(
          method: 'GET',
          headers: headers,
          responseType: ResponseType.bytes, // 明确指定响应类型为字节
        ),
      );

      _logger.info(
        '[${widget.id ?? _ts}] 图片加载成功 ==> 响应状态: ${response.statusCode}, 数据大小: ${response.data?.length ?? 0} 字节',
      );

      if (response.data != null && response.data is List<int>) {
        setState(() {
          _imageBytes = Uint8List.fromList(response.data);
          _isLoading = false;
          _errorMessage = null;
        });
        _logger.info(
          '[${widget.id ?? _ts}] 图片数据设置成功，大小: ${_imageBytes!.length} 字节',
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '服务器返回的数据格式无效';
        });
        _logger.severe('[${widget.id ?? _ts}] 图片加载失败：$_errorMessage');
      }
    } catch (e, stack) {
      setState(() {
        _isLoading = false;
        _errorMessage = '$e\n$stack';
      });
      _logger.severe('[${widget.id ?? _ts}] 图片加载失败: $_errorMessage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AppConfig.getFullServerUrl(),
      builder: (context, snapshot) {
        // 如果服务器地址发生变化，重新加载图片
        if (snapshot.hasData && snapshot.data != null) {
          final currentServerUrl = snapshot.data!;
          // 检查服务器地址是否发生变化
          if (_lastServerUrl != null && _lastServerUrl != currentServerUrl) {
            // 服务器地址发生变化，重新加载图片
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _loadImage();
              }
            });
          } else if (_lastServerUrl == null) {
            // 首次加载
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _loadImage();
              }
            });
          }
        }

        // 检查objectKey是否发生变化
        if (_lastObjectKey != null && _lastObjectKey != widget.objectKey) {
          // objectKey发生变化，重新加载图片
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadImage();
            }
          });
        }

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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[400]!,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '加载中...',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
                  Icon(Icons.person, size: 48, color: Colors.grey[600]),
                  // SizedBox(height: 4),
                  // Text(
                  //   '加载失败',
                  //   style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  // ),
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
                  Icon(Icons.person, size: 48, color: Colors.grey[600]),
                  // Icon(
                  //   Icons.image_not_supported,
                  //   size: 24,
                  //   color: Colors.grey[600],
                  // ),
                  // SizedBox(height: 4),
                  // Text(
                  //   '无图片',
                  //   style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  // ),
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
                  Icon(Icons.person, size: 48, color: Colors.grey[600]),
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
                  Icon(Icons.person, size: 48, color: Colors.grey[600]),
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
            _logger.severe('[${widget.id ?? _ts}] Image.memory 渲染失败: $error');
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
                    Icon(Icons.person, size: 48, color: Colors.grey[600]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
