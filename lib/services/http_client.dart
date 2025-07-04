import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:rtsp_photo_app/config/app_config.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('HttpClient');

class ApiClient {
  static String tokenKey = 'aurora-auth';
  late final Dio _dio;

  String? _authToken;
  String _baseUrl = 'http://192.168.3.169:8080'; // 默认基础URL

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      ),
    );

    // 添加拦截器用于日志记录
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) {
          if (object is String) {
            _logger.info(object);
          } else {
            _logger.info(object.toString());
          }
        },
      ),
    );

    // 在 Web 环境中不需要禁用证书验证
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) {
              _logger.info('调试模式：忽略证书验证 $host:$port');
              return true;
            };
        return client;
      };
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _getAuthHeaders(headers)),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: Options(headers: _getAuthHeaders(headers)),
        onSendProgress: onSendProgress,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        options: Options(headers: _getAuthHeaders(headers)),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {Map<String, String>? headers}) async {
    try {
      return await _dio.delete(
        path,
        options: Options(headers: _getAuthHeaders(headers)),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return Exception('Connection timeout');
        case DioExceptionType.receiveTimeout:
          return Exception('Receive timeout');
        case DioExceptionType.badResponse:
          return Exception('Server error: ${error.response?.statusCode}');
        default:
          return Exception('Network error: ${error.message}');
      }
    }
    return Exception('Unknown error: $error');
  }

  Map<String, String> _getAuthHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{'Content-Type': 'application/json'};

    // 添加认证token
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers[tokenKey] = _authToken!;
    }

    // 添加自定义头部
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  // 设置认证token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  // 清除认证token
  void clearAuthToken() {
    _authToken = null;
  }

  // 设置基础URL
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    _dio.options.baseUrl = baseUrl;
  }

  // 获取当前基础URL
  String get baseUrl => _baseUrl;
}
