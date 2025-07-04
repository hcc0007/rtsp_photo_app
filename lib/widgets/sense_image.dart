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

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final url =
        '${widget._apiClient.baseUrl}/gateway/sys/api/v1/images/${widget.objectKey}';
    final authInfo = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).authService;
    final token = authInfo.token;
    final headers = {ApiClient.tokenKey: token};
    final ts = DateTime.now().millisecondsSinceEpoch;
    _logger.info('[$ts] load image ==> url: $url, headers: $headers');
    try {
      final response = await Dio().request(
        url,
        options: Options(method: 'GET', headers: {ApiClient.tokenKey: token}),
      );
      _logger.info('[$ts] load image ==> response: ${response.data}');
      setState(() {
        _imageBytes = Uint8List.fromList(response.data!);
      });
    } catch (e, stack) {
      _logger.severe('图片加载失败: $e');
      // 你可以在界面上显示一个错误提示
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes == null) {
      return const CircularProgressIndicator();
    }
    return Image.memory(
      _imageBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
