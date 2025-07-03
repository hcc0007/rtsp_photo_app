import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PhotoProvider with ChangeNotifier {
  List<String> _photos = [];
  bool _isLoading = false;
  String? _error;
  Timer? _timer;
  
  // 配置
  static const String apiUrl = 'https://your-api-endpoint.com/photos'; // 请替换为实际的API地址
  static const int refreshInterval = 5000; // 5秒刷新一次
  
  List<String> get photos => _photos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  PhotoProvider() {
    _startPeriodicFetch();
  }
  
  void _startPeriodicFetch() {
    // 立即获取一次
    fetchPhotos();
    
    // 设置定时器，定期获取
    _timer = Timer.periodic(const Duration(milliseconds: refreshInterval), (timer) {
      fetchPhotos();
    });
  }
  
  Future<void> fetchPhotos() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _photos = data.cast<String>();
        _error = null;
      } else {
        _error = '获取照片失败: ${response.statusCode}';
      }
    } catch (e) {
      _error = '网络错误: $e';
      // 如果网络错误，使用模拟数据
      _photos = [
        'https://picsum.photos/400/300?random=1',
        'https://picsum.photos/400/300?random=2',
        'https://picsum.photos/400/300?random=3',
        'https://picsum.photos/400/300?random=4',
      ];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void updateApiUrl(String newUrl) {
    // 这里可以添加更新API地址的逻辑
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 