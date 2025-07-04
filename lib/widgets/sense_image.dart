import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:rtsp_photo_app/providers/auth_provider.dart';
import 'package:rtsp_photo_app/services/http_client.dart';

class SenseImage extends StatefulWidget {
  final String objectKey;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SenseImage({
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
    final url = '/gateway/sys/api/v1/images/${widget.objectKey}';
    final authInfo = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).authService;
    final token = authInfo.token;
    final response = await Dio().get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {ApiClient.tokenKey: token},
      ),
    );
    setState(() {
      _imageBytes = Uint8List.fromList(response.data!);
    });
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
