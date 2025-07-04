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
  
  // 过滤控制
  Map<String, int> _lastPersonTime = {}; // 记录每个人的最后推送时间
  Map<String, Timer> _displayTimers = {}; // 记录显示定时器
  Map<String, int> _displayStartTime = {}; // 记录显示开始时间

  List<PushData> get pushData => _pushData;
  String? get error => _error;
  
  // 获取过滤记录数量（用于调试）
  int get filterRecordCount => _lastPersonTime.length;
  Map<String, int> get lastPersonTime => Map.unmodifiable(_lastPersonTime);

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

  /// 获取人员唯一标识（优先使用faceId，其次使用objectId）
  String _getPersonIdentifier(PushData data) {
    // 优先使用faceId，如果没有则使用objectId
    final faceId = data.applet.face.faceId;
    if (faceId.isNotEmpty) {
      return faceId;
    }
    return data.objectId;
  }

  /// 检查是否应该过滤掉这个推送数据（异步热加载）
  Future<bool> _shouldFilterPushData(PushData data) async {
    final personId = _getPersonIdentifier(data);
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final filterWindow = await AppConfig.getPersonFilterTimeWindow();
    
    print('检查过滤: personId=$personId, 当前时间=$currentTime, 过滤窗口=${filterWindow}ms');
    
    // 检查是否在过滤时间窗口内
    if (_lastPersonTime.containsKey(personId)) {
      final lastTime = _lastPersonTime[personId]!;
      final timeDiff = currentTime - lastTime;
      print('发现重复人员: personId=$personId, 上次时间=$lastTime, 时间差=${timeDiff}ms');
      
      if (timeDiff < filterWindow) {
        print('过滤推送数据: personId=$personId, 时间差=${timeDiff}ms < ${filterWindow}ms');
        return true; // 过滤掉
      } else {
        print('时间已过期，允许推送: personId=$personId, 时间差=${timeDiff}ms >= ${filterWindow}ms');
      }
    } else {
      print('新人员，允许推送: personId=$personId');
    }
    
    // 更新最后推送时间
    _lastPersonTime[personId] = currentTime;
    print('更新最后推送时间: personId=$personId, 时间=$currentTime');
    return false;
  }

  /// 根据人脸类型获取显示时间（异步热加载）
  Future<int> _getDisplayTime(PushData data) async {
    final strangerType = await AppConfig.getRecordTypeStranger();
    final knownType = await AppConfig.getRecordTypeKnown();
    final strangerTime = await AppConfig.getStrangerDisplayTime();
    final knownTime = await AppConfig.getKnownPersonDisplayTime();
    switch (data.recordType) {
      case var t when t == strangerType:
        return strangerTime;
      case var t when t == knownType:
        return knownTime;
      default:
        return knownTime;
    }
  }

  /// 设置显示定时器（异步热加载）
  Future<void> _setDisplayTimer(PushData data) async {
    final personId = _getPersonIdentifier(data);
    final displayTime = await _getDisplayTime(data);
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    _displayStartTime[personId] = currentTime;
    _displayTimers[personId]?.cancel();
    _displayTimers[personId] = Timer(Duration(milliseconds: displayTime), () {
      _removePushData(personId);
    });
  }

  /// 添加新的推送数据（异步热加载）
  Future<void> addPushDataAsync(PushData data) async {
    print('addPushData: objectId=${data.objectId}, createTime=${data.createTime}, recordType=${data.recordType}');
    if (await _shouldFilterPushData(data)) {
      print('过滤掉重复的人脸推送数据');
      return;
    }
    _pushData.insert(0, data);
    if (_pushData.length > 50) {
      _pushData = _pushData.take(50).toList();
    }
    await _setDisplayTimer(data);
    notifyListeners();
  }

  /// 兼容原同步接口，内部自动异步
  void addPushData(PushData data) {
    addPushDataAsync(data);
  }

  /// 移除推送数据
  void _removePushData(String personId) {
    _pushData.removeWhere((data) => _getPersonIdentifier(data) == personId);
    _displayTimers.remove(personId);
    _displayStartTime.remove(personId);
    notifyListeners();
  }

  /// 清理过期的过滤记录
  void cleanupExpiredFilters() {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = <String>[];
    
    _lastPersonTime.forEach((personId, lastTime) {
      if (currentTime - lastTime > AppConfig.personFilterTimeWindow) {
        expiredKeys.add(personId);
      }
    });
    
    for (final key in expiredKeys) {
      _lastPersonTime.remove(key);
    }
    print('清理了 ${expiredKeys.length} 个过期的过滤记录');
  }
  
  /// 清空所有过滤记录（用于测试）
  void clearAllFilters() {
    final count = _lastPersonTime.length;
    _lastPersonTime.clear();
    print('清空了所有过滤记录，共 $count 条');
  }

  @override
  void dispose() {
    stopLongPolling();
    // 取消所有定时器
    for (final timer in _displayTimers.values) {
      timer.cancel();
    }
    _displayTimers.clear();
    super.dispose();
  }
}
