import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';
import '../config/app_config.dart';
import '../models/push_data.dart';

const String kRecordTypeStranger = 'portrait_stranger';
const String kRecordTypeNormal = 'portrait_normal';

class PushProvider with ChangeNotifier {
  final ApiClient _httpClient = ApiClient();
  bool _running = false;
  final List<PushData> _pushData =
      []; // mockData.map((e) => PushData.fromJson(e)).toList();
  String? _error;
  int? _currentUserId;

  // 过滤控制
  Map<String, int> _lastPersonTime = {}; // 记录每个人的最后推送时间 - 防止短时间内重复推送同一个人的人脸识别结果
  Map<String, Timer> _displayTimers = {}; // 记录显示定时器 - 控制每个人脸识别结果在界面上的显示时长
  Map<String, int> _displayStartTime = {}; // 记录显示开始时间 - 记录每个人脸识别结果开始显示的时间

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
      startLongPolling(userId: userId);
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

  /// 获取人员唯一标识 objectId
  String _getPersonIdentifier(PushData data) {
    return data.objectId;
  }

  /// 检查是否应该过滤掉这个推送数据（异步热加载）
  Future<bool> _shouldFilterPushData(PushData data) async {
    final personId = _getPersonIdentifier(data);
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // 根据人员类型获取对应的过滤时间窗口
    final filterWindow = await _getFilterTimeWindowByRecordType(
      data.recordType,
    );

    print(
      '检查过滤: personId=$personId, recordType=${data.recordType}, 当前时间=$currentTime, 过滤窗口=${filterWindow}ms',
    );

    // 检查是否在过滤时间窗口内
    if (_lastPersonTime.containsKey(personId)) {
      final lastTime = _lastPersonTime[personId]!;
      final timeDiff = currentTime - lastTime;
      print('发现重复人员: personId=$personId, 上次时间=$lastTime, 时间差=${timeDiff}ms');

      if (timeDiff < filterWindow) {
        print(
          '过滤推送数据: personId=$personId, recordType=${data.recordType}, 时间差=${timeDiff}ms < ${filterWindow}ms',
        );
        return true; // 过滤掉
      } else {
        print(
          '时间已过期，允许推送: personId=$personId, recordType=${data.recordType}, 时间差=${timeDiff}ms >= ${filterWindow}ms',
        );
      }
    } else {
      print('新人员，允许推送: personId=$personId, recordType=${data.recordType}');
    }

    // 更新最后推送时间
    _lastPersonTime[personId] = currentTime;
    print(
      '更新最后推送时间: personId=$personId, recordType=${data.recordType}, 时间=$currentTime',
    );
    return false;
  }

  /// 根据人脸类型获取过滤时间窗口（异步热加载）
  Future<int> _getFilterTimeWindowByRecordType(String recordType) async {
    final strangerFilterTime = await AppConfig.getStrangerFilterTimeWindow();
    final knownFilterTime = await AppConfig.getKnownPersonFilterTimeWindow();
    final normalFilterTime = await AppConfig.getNormalPersonFilterTimeWindow();
    switch (recordType) {
      case kRecordTypeStranger:
        return strangerFilterTime;
      case kRecordTypeNormal:
        return knownFilterTime;
      default:
        return normalFilterTime;
    }
  }

  /// 根据人脸类型获取显示时间（异步热加载）
  Future<int> _getDisplayTime(PushData data) async {
    final strangerTime = await AppConfig.getStrangerDisplayTime();
    final knownTime = await AppConfig.getKnownPersonDisplayTime();
    final normalTime = await AppConfig.getNormalPersonDisplayTime();
    switch (data.recordType) {
      case kRecordTypeStranger:
        return strangerTime;
      case kRecordTypeNormal:
        return knownTime;
      default:
        return normalTime;
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
    print('=== addPushDataAsync 开始 ===');
    print(
      'addPushData: objectId=${data.objectId}, createTime=${data.createTime}, recordType=${data.recordType}',
    );

    final shouldFilter = await _shouldFilterPushData(data);
    print('过滤检查结果: shouldFilter=$shouldFilter');

    if (shouldFilter) {
      print('过滤掉重复的人脸推送数据');
      return;
    }

    print('开始添加数据到列表，当前列表长度: ${_pushData.length}');
    _pushData.insert(0, data);
    print('数据已添加到列表，新长度: ${_pushData.length}');

    // 根据人员类型限制展示数量
    await _limitDisplayCountByRecordType(data.recordType);

    await _setDisplayTimer(data);
    print('显示定时器已设置');

    notifyListeners();
    print('已通知监听器');
    print('=== addPushDataAsync 结束 ===');
  }

  /// 根据人员类型限制展示数量（异步热加载）
  Future<void> _limitDisplayCountByRecordType(String recordType) async {
    final strangerMaxCount = await AppConfig.getStrangerMaxDisplayCount();
    final knownMaxCount = await AppConfig.getKnownPersonMaxDisplayCount();
    int maxCount;
    if (recordType == kRecordTypeStranger) {
      maxCount = strangerMaxCount;
    } else if (recordType == kRecordTypeNormal) {
      maxCount = knownMaxCount;
    } else {
      maxCount = knownMaxCount;
    }
    List<PushData> filteredData;
    if (recordType == kRecordTypeStranger) {
      filteredData = _pushData
          .where((data) => data.recordType == kRecordTypeStranger)
          .toList();
    } else {
      filteredData = _pushData
          .where((data) => data.recordType == kRecordTypeNormal)
          .toList();
    }
    if (filteredData.length > maxCount) {
      final toRemove = filteredData.length - maxCount;
      final toRemoveData = filteredData.take(toRemove).toList();
      for (final removeData in toRemoveData) {
        final personId = _getPersonIdentifier(removeData);
        _displayTimers[personId]?.cancel();
        _displayTimers.remove(personId);
        _displayStartTime.remove(personId);
        _pushData.remove(removeData);
      }
    }
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
  Future<void> cleanupExpiredFilters() async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = <String>[];

    // 获取各类型的过滤时间窗口
    final strangerFilterTime = await AppConfig.getStrangerFilterTimeWindow();
    final knownFilterTime = await AppConfig.getKnownPersonFilterTimeWindow();
    final normalFilterTime = await AppConfig.getNormalPersonFilterTimeWindow();

    print('开始清理过期过滤记录...');
    print('陌生人过滤时间窗口: ${strangerFilterTime}ms');
    print('白名单过滤时间窗口: ${knownFilterTime}ms');
    print('普通人员过滤时间窗口: ${normalFilterTime}ms');

    _lastPersonTime.forEach((personId, lastTime) {
      final timeDiff = currentTime - lastTime;

      // 根据人员类型判断是否过期
      // 注意：这里我们无法直接知道personId对应的人员类型，所以使用最长的过滤时间窗口
      // 在实际应用中，可能需要维护一个personId到recordType的映射
      final maxFilterTime = [
        strangerFilterTime,
        knownFilterTime,
        normalFilterTime,
      ].reduce((a, b) => a > b ? a : b);

      if (timeDiff > maxFilterTime) {
        expiredKeys.add(personId);
        print(
          '发现过期记录: personId=$personId, 时间差=${timeDiff}ms > ${maxFilterTime}ms',
        );
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
