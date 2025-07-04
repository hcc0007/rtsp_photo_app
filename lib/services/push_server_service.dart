import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:logging/logging.dart';

class PushServerService {
  static final Logger _logger = Logger('PushServerService');
  static HttpServer? _server;
  static bool _isRunning = false;

  // Stream 控制器，用于管理推送数据流
  static final StreamController<Map<String, dynamic>> _pushDataController =
      StreamController<Map<String, dynamic>>.broadcast();

  // 推送数据流，供 StreamBuilder 使用
  static Stream<Map<String, dynamic>> get pushDataStream =>
      _pushDataController.stream;

  // 回调函数，用于处理接收到的推送数据
  static Function(Map<String, dynamic>)? onDataReceived;

  // 启动服务器
  static Future<void> startServer({int port = 8080}) async {
    if (_isRunning) {
      _logger.info('服务器已经在运行中');
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;

      _logger.info('推送服务器已启动，端口: $port');
      _logger.info('API 端点: POST http://localhost:$port/front/push');
      _logger.info('状态端点: GET http://localhost:$port/status');

      // 处理请求
      _server!.listen((HttpRequest request) {
        _handleRequest(request);
      });
    } catch (e) {
      _logger.severe('启动服务器失败: $e');
      rethrow;
    }
  }

  // 处理 HTTP 请求
  static void _handleRequest(HttpRequest request) {
    final path = request.uri.path;
    final method = request.method;

    _logger.info('收到请求: $method $path');

    // 设置 CORS 头
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );
    request.response.headers.add(
      'Access-Control-Allow-Headers',
      'Content-Type',
    );

    if (method == 'OPTIONS') {
      request.response.statusCode = 200;
      request.response.close();
      return;
    }

    switch (path) {
      case '/status':
        if (method == 'GET') {
          _handleStatusRequest(request);
        } else {
          _sendErrorResponse(request, 405, 'Method not allowed');
        }
        break;

      case '/front/push':
        if (method == 'POST') {
          _logger.info('收到推送数据: ', request);
          _handlePushRequest(request);
        } else {
          _sendErrorResponse(request, 405, 'Method not allowed');
        }
        break;

      default:
        _sendErrorResponse(request, 404, 'Not found');
        break;
    }
  }

  // 处理状态请求
  static void _handleStatusRequest(HttpRequest request) {
    final response = {
      'status': 'running',
      'timestamp': DateTime.now().toIso8601String(),
    };

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(response))
      ..close();
  }

  // 处理推送请求
  static void _handlePushRequest(HttpRequest request) async {
    try {
      // 正确读取请求体
      final bodyBytes = await request.fold<List<int>>(
        <int>[],
        (list, chunk) => list..addAll(chunk),
      );
      final body = utf8.decode(bodyBytes);
      final data = jsonDecode(body);
      // _logger.info('收到原始推送数据类型: \\${data.runtimeType}\\，内容: \\${data.toString()}');

      _logger.info(
        '收到推送数据 ====> objectId: ${data['objectId'] ?? 'unknown'}, createTime: ${data['createTime'] ?? 'unknown'}',
      );

      // 通过 Stream 发送数据
      _pushDataController.add(data);

      // 调用回调函数
      if (onDataReceived != null) {
        onDataReceived!(data);
      }

      final response = {
        'success': true,
        'message': '数据推送成功',
        'timestamp': DateTime.now().toIso8601String(),
      };

      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response))
        ..close();
    } catch (e) {
      _logger.severe('处理推送数据时出错: $e');
      _sendErrorResponse(request, 400, '数据格式错误: $e');
    }
  }

  // 发送错误响应
  static void _sendErrorResponse(
    HttpRequest request,
    int statusCode,
    String message,
  ) {
    final response = {
      'success': false,
      'error': message,
      'statusCode': statusCode,
    };

    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(response))
      ..close();
  }

  // 停止服务器
  static Future<void> stopServer() async {
    if (!_isRunning || _server == null) {
      _logger.info('服务器未运行');
      return;
    }
    try {
      await _server!.close();
      _server = null;
      _isRunning = false;
      _logger.info('推送服务器已停止');
    } catch (e) {
      _logger.severe('停止服务器失败: $e');
      rethrow;
    }
  }

  // 释放资源
  static void dispose() {
    _pushDataController.close();
  }
}
