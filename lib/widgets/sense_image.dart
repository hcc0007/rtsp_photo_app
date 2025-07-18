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

// 全局图片缓存
class ImageCache {
  static final Map<String, Uint8List> _cache = {};
  
  static Uint8List? get(String key) {
    return _cache[key];
  }
  
  static void set(String key, Uint8List data) {
    _cache[key] = data;
  }
  
  static bool contains(String key) {
    return _cache.containsKey(key);
  }
  
  static void clear() {
    _cache.clear();
  }
}

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

    // 检查缓存
    if (ImageCache.contains(widget.objectKey)) {
      setState(() {
        _imageBytes = ImageCache.get(widget.objectKey);
        _isLoading = false;
        _errorMessage = null;
      });
      _logger.info('[${widget.id ?? _ts}] 从缓存加载图片: ${widget.objectKey}');
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
        final imageData = Uint8List.fromList(response.data);
        
        // 验证图片数据有效性
        if (imageData.length < 10) {
          setState(() {
            _isLoading = false;
            _errorMessage = '图片数据太小，可能不是有效图片 (${imageData.length} 字节)';
          });
          _logger.severe('[${widget.id ?? _ts}] 图片加载失败：$_errorMessage');
          return;
        }
        
        // 检查是否为常见图片格式的魔数
        final isValidImage = _isValidImageData(imageData);
        if (!isValidImage) {
          setState(() {
            _isLoading = false;
            _errorMessage = '图片数据格式无效，可能不是图片文件';
          });
          _logger.severe('[${widget.id ?? _ts}] 图片加载失败：$_errorMessage');
          return;
        }
        
        setState(() {
          _imageBytes = imageData;
          _isLoading = false;
          _errorMessage = null;
        });
        
        // 添加到缓存
        ImageCache.set(widget.objectKey, imageData);
        
        _logger.info(
          '[${widget.id ?? _ts}] 图片数据设置成功，大小: ${_imageBytes!.length} 字节，已缓存',
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
      
      // 记录详细的错误信息用于调试
      _logger.severe('[${widget.id ?? _ts}] 错误详情:');
      _logger.severe('[${widget.id ?? _ts}] - URL: $url');
      _logger.severe('[${widget.id ?? _ts}] - ObjectKey: ${widget.objectKey}');
      _logger.severe('[${widget.id ?? _ts}] - Token: ${token?.substring(0, token.length > 10 ? 10 : token.length)}...');
      _logger.severe('[${widget.id ?? _ts}] - 错误类型: ${e.runtimeType}');
    }
  }

  @override
  void didUpdateWidget(SenseImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 检查objectKey是否发生变化
    if (oldWidget.objectKey != widget.objectKey) {
      _lastObjectKey = widget.objectKey;
      _loadImage();
    }
  }

  /// 验证图片数据是否为有效的图片格式
  bool _isValidImageData(Uint8List data) {
    if (data.length < 4) return false;
    
    // 检查常见图片格式的魔数
    // JPEG: FF D8 FF
    if (data.length >= 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
      return true;
    }
    
    // PNG: 89 50 4E 47
    if (data.length >= 4 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) {
      return true;
    }
    
    // GIF: 47 49 46 38 (GIF8)
    if (data.length >= 4 && data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x38) {
      return true;
    }
    
    // WebP: 52 49 46 46 ... 57 45 42 50
    if (data.length >= 12 && 
        data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
        data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50) {
      return true;
    }
    
    // 如果不是已知格式，记录前几个字节用于调试
    final hexBytes = data.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    _logger.warning('[${widget.id ?? _ts}] 未知图片格式，前8字节: $hexBytes');
    
    // 对于未知格式，暂时允许通过（可能是其他格式）
    return true;
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
        _logger.severe('[${widget.id ?? _ts}] 渲染失败详情:');
        _logger.severe('[${widget.id ?? _ts}] - ObjectKey: ${widget.objectKey}');
        _logger.severe('[${widget.id ?? _ts}] - 数据大小: ${_imageBytes!.length} 字节');
        _logger.severe('[${widget.id ?? _ts}] - 前8字节: ${_imageBytes!.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
        _logger.severe('[${widget.id ?? _ts}] - 错误类型: ${error.runtimeType}');
        
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
                SizedBox(height: 4),
                Text(
                  '图片加载失败',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
