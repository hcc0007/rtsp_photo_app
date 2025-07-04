import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/http_client.dart';
import 'auth_provider.dart';
import '../config/app_config.dart';
import '../models/push_data.dart';
import '../utils/mock_data.dart';

class PushProvider with ChangeNotifier {
  final ApiClient _httpClient = ApiClient();
  bool _running = false;
  List<PushData> _pushData = [];
  String? _error;
  int? _currentUserId;

  List<PushData> get pushData => _pushData;
  String? get error => _error;

  /// 监听 AuthProvider 状态变化，自动启动/停止长轮询
  void handleAuth(AuthProvider authProvider) {
    final userInfo = authProvider.userInfo;
    final isLoggedIn = authProvider.isLoggedIn;
    final userId = userInfo?.userId;
    if (isLoggedIn && userId != null) {
      // startLongPolling(userId: userId);
    } else {
      stopLongPolling();
    }
  }

  Future<void> startLongPolling({required int userId}) async {
    if (_currentUserId == userId && _running) return; // 已经在轮询同一个用户
    stopLongPolling();
    _currentUserId = userId;
    _running = true;
    while (_running && _currentUserId == userId) {
      try {
        // 如果是mock模式，直接推送模拟数据
        if (AppConfig.showMockData) {
          mockPushData(MockData.getMockPushData());
        } else {
          final res = await _httpClient.post(
            '/pss/push_data',
            data: {'userId': userId},
          );
          final responseData = res.data as Map<String, dynamic>;
          if (responseData['success'] == true) {
            final data = responseData['data'];
            if (data is List) {
              for (var e in data) {
                addPushData(PushData.fromJson(e as Map<String, dynamic>));
              }
            } else if (data is Map) {
              addPushData(PushData.fromJson(data as Map<String, dynamic>));
            } else {
              // 不做任何处理
            }
            _error = null;
            notifyListeners();
          } else {
            _error = responseData['message'] ?? '推送失败';
            notifyListeners();
          }
        }
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  void stopLongPolling() {
    _running = false;
    _currentUserId = null;
  }

  /// 手动模拟推送数据（用于前端测试）
  void mockPushData(List<PushData> data) {
    _pushData = data;
    notifyListeners();
  }

  /// 添加新的推送数据
  void addPushData(PushData data) {
    print('addPushData: objectId=${data.objectId}, createTime=${data.createTime}');
    _pushData.insert(0, data);
    if (_pushData.length > 50) {
      _pushData = _pushData.take(50).toList();
    }
    notifyListeners();

    // // 检查是否已存在相同的数据（避免重复）
    // bool exists = _pushData.any((item) =>
    //   item.objectId == data.objectId &&
    //   item.createTime == data.createTime
    // );

    // if (!exists) {
    //   _pushData.insert(0, data); // 在列表开头插入新数据
    //   // 限制列表长度，避免内存占用过多
    //   if (_pushData.length > 50) {
    //     _pushData = _pushData.take(50).toList();
    //   }
    //   notifyListeners();
    // }
  }

  @override
  void dispose() {
    stopLongPolling();
    super.dispose();
  }
}
