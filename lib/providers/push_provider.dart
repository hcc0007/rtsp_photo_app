import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';
import '../config/app_config.dart';
import '../models/push_data.dart';

final Logger _logger = Logger('PushProvider');

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

  /// 获取人员唯一标识
  /// 白名单人员：使用 portraitId
  /// 陌生人：使用 objectId
  String _getPersonIdentifier(PushData data) {
    if (data.recordType == kRecordTypeNormal) {
      // 白名单人员：使用 portraitId
      final portraitId = data.particular.portrait.portraitId?.toString() ?? data.objectId;
      if (data.particular.portrait.portraitId == null) {
        _logger.warning(
          '[${data.objectId}] ⚠️⚠️⚠️ 白名单人员缺少portraitId，使用objectId作为替代: objectId=${data.objectId}',
        );
      }
      return portraitId;
    } else {
      // 陌生人：使用 objectId
      return data.objectId;
    }
  }

  /// 检查是否应该过滤掉这个推送数据（异步热加载）
  Future<bool> _shouldFilterPushData(PushData data) async {
    final personId = _getPersonIdentifier(data);
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // 快速检查：如果已经存在记录，先进行快速过滤判断
    if (_lastPersonTime.containsKey(personId)) {
      final lastTime = _lastPersonTime[personId]!;
      final timeDiff = currentTime - lastTime;
      
      // 获取过滤时间窗口
      final filterWindow = await _getFilterTimeWindowByRecordType(data.recordType);
      
      final keyInfo = data.recordType == kRecordTypeNormal 
          ? 'portraitId=${data.particular.portrait.portraitId ?? data.objectId}'
          : 'objectId=${data.objectId}';
      _logger.info(
        '[${data.objectId}] 检查过滤🔍🔍🔍: personId=$personId ($keyInfo), recordType=${data.recordType}, 当前时间=$currentTime, 过滤窗口=${filterWindow}ms',
      );
      
      _logger.info('[${data.objectId}] 发现重复人员: personId=$personId ($keyInfo), 上次时间=$lastTime, 时间差=${timeDiff}ms');

      if (timeDiff < filterWindow) {
        _logger.info(
          '[${data.objectId}] 快速过滤推送数据: personId=$personId ($keyInfo), recordType=${data.recordType}, 时间差=${timeDiff}ms < ${filterWindow}ms',
        );
        return true; // 过滤掉
      } else {
        _logger.info(
          '[${data.objectId}] 时间已过期，允许推送: personId=$personId ($keyInfo), recordType=${data.recordType}, 时间差=${timeDiff}ms >= ${filterWindow}ms',
        );
      }
    } else {
      final keyInfo = data.recordType == kRecordTypeNormal 
          ? 'portraitId=${data.particular.portrait.portraitId ?? data.objectId}'
          : 'objectId=${data.objectId}';
      _logger.info(
        '[${data.objectId}] 检查过滤🔍🔍🔍: personId=$personId ($keyInfo), recordType=${data.recordType}, 当前时间=$currentTime, 新人员',
      );
      _logger.info('[${data.objectId}] 新人员，允许推送: personId=$personId ($keyInfo), recordType=${data.recordType}');
    }

    // 更新最后推送时间
    _lastPersonTime[personId] = currentTime;
    final keyInfo = data.recordType == kRecordTypeNormal 
        ? 'portraitId=${data.particular.portrait.portraitId ?? data.objectId}'
        : 'objectId=${data.objectId}';
    _logger.info(
      '[${data.objectId}] 更新最后推送时间: personId=$personId ($keyInfo), recordType=${data.recordType}, 时间=$currentTime',
    );
    return false;
  }

  /// 根据人脸类型获取过滤时间窗口（异步热加载）
  Future<int> _getFilterTimeWindowByRecordType(String recordType) async {
    final strangerFilterTime = await AppConfig.getStrangerFilterTimeWindow();
    final normalFilterTime = await AppConfig.getNormalPersonFilterTimeWindow();
    switch (recordType) {
      case kRecordTypeStranger:
        return strangerFilterTime;
      case kRecordTypeNormal:
        return normalFilterTime;
      default:
        return normalFilterTime;
    }
  }

  /// 根据人脸类型获取显示时间（异步热加载）
  Future<int> _getDisplayTime(PushData data) async {
    final strangerTime = await AppConfig.getStrangerDisplayTime();
    final normalTime = await AppConfig.getNormalPersonDisplayTime();
    switch (data.recordType) {
      case kRecordTypeStranger:
        return strangerTime;
      case kRecordTypeNormal:
        return normalTime;
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
      _removePushData(personId, data.recordType, displayTime);
    });
    
    // 获取过滤时间窗口
    _getFilterTimeWindowByRecordType(data.recordType).then((filterTime) {
      final keyInfo = data.recordType == kRecordTypeNormal 
          ? 'portraitId=${data.particular.portrait.portraitId ?? data.objectId}'
          : 'objectId=${data.objectId}';
      _logger.info(
        '[${data.objectId}] ⏰⏰⏰ 设置显示定时器: personId=$personId ($keyInfo), recordType=${data.recordType}, 配置显示时间=${displayTime}ms, 过滤时间窗口=${filterTime}ms, 开始时间=$currentTime',
      );
    });
  }

  /// 添加新的推送数据（异步热加载）
  Future<void> addPushDataAsync(PushData data) async {
    _logger.info('[${data.objectId}] === addPushDataAsync 开始🏃🏃🏃 ===');
    _logger.info(
      '[${data.objectId}] addPushData: objectId=${data.objectId}, createTime=${data.createTime}, recordType=${data.recordType}',
    );

    final shouldFilter = await _shouldFilterPushData(data);
    _logger.info('[${data.objectId}] 过滤检查结果: shouldFilter=$shouldFilter');

    // 如果是要被过滤的数据，要被return
    if (shouldFilter) {
      _logger.info('[${data.objectId}] 过滤掉重复的人脸推送数据');
      return;
    }

    _logger.info('[${data.objectId}] 开始添加数据到列表，当前列表长度: ${_pushData.length}');
    _pushData.add(data); // 从右边插入（最新数据）
    _logger.info('[${data.objectId}] 数据已添加到列表，新长度: ${_pushData.length}');

    // 根据人员类型限制展示数量
    await _limitDisplayCountByRecordType(data.recordType);

    await _setDisplayTimer(data);
    _logger.info('[${data.objectId}] 显示定时器已设置');

    notifyListeners();
    _logger.info('[${data.objectId}] 已通知监听器');
    _logger.info('[${data.objectId}] === addPushDataAsync 结束 ===');
  }

  /// 根据人员类型限制展示数量（异步热加载）
  Future<void> _limitDisplayCountByRecordType(String recordType) async {
    final strangerMaxCount = await AppConfig.getStrangerMaxDisplayCount();
    final normalMaxCount = await AppConfig.getNormalPersonMaxDisplayCount();
    int maxCount;
    if (recordType == kRecordTypeStranger) {
      maxCount = strangerMaxCount;
    } else if (recordType == kRecordTypeNormal) {
      maxCount = normalMaxCount;
    } else {
      maxCount = normalMaxCount;
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
      // 从左边（最旧的数据）开始移除
      final toRemoveData = filteredData.take(toRemove).toList();
      for (final removeData in toRemoveData) {
        final personId = _getPersonIdentifier(removeData);
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final startTime = _displayStartTime[personId] ?? currentTime;
        final actualDisplayTime = currentTime - startTime;
        
        // 获取过滤时间窗口
        _getFilterTimeWindowByRecordType(removeData.recordType).then((filterTime) {
          final keyInfo = removeData.recordType == kRecordTypeNormal 
              ? 'portraitId=${removeData.particular.portrait.portraitId ?? removeData.objectId}'
              : 'objectId=${removeData.objectId}';
          _logger.info(
            '[${removeData.objectId}] 🗑️🗑️🗑️ 数量限制移出人脸: personId=$personId ($keyInfo), recordType=${removeData.recordType}, 显示时长=${actualDisplayTime}ms, 过滤时间窗口=${filterTime}ms, 原因=超过最大显示数量',
          );
        });
        
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

  /// 调试方法：临时禁用过滤，直接添加数据
  void addPushDataWithoutFilter(PushData data) {
    print('=== addPushDataWithoutFilter 开始 ===');
    print(
      'addPushDataWithoutFilter: objectId=${data.objectId}, createTime=${data.createTime}, recordType=${data.recordType}',
    );

    print('开始添加数据到列表，当前列表长度: ${_pushData.length}');
    _pushData.add(data); // 从右边插入（最新数据）
    print('数据已添加到列表，新长度: ${_pushData.length}');

    notifyListeners();
    print('已通知监听器');
    print('=== addPushDataWithoutFilter 结束 ===');
  }

  /// 调试方法：获取当前状态信息
  Map<String, dynamic> getDebugInfo() {
    return {
      'pushDataCount': _pushData.length,
      'filterRecordCount': _lastPersonTime.length,
      'displayTimersCount': _displayTimers.length,
      'displayStartTimeCount': _displayStartTime.length,
      'isRunning': _running,
      'currentUserId': _currentUserId,
      'error': _error,
      'lastPersonTime': Map.from(_lastPersonTime),
    };
  }

  /// 调试方法：验证过滤时间配置
  Future<void> logFilterTimeConfig() async {
    final strangerFilterTime = await AppConfig.getStrangerFilterTimeWindow();
    final normalFilterTime = await AppConfig.getNormalPersonFilterTimeWindow();
    
    _logger.info('=== 过滤时间配置验证 ===');
    _logger.info('陌生人过滤时间窗口: ${strangerFilterTime}ms');
    _logger.info('白名单人员过滤时间窗口: ${normalFilterTime}ms');
    _logger.info('当前过滤记录数量: ${_lastPersonTime.length}');
    _logger.info('过滤记录详情: ${_lastPersonTime}');
    _logger.info('========================');
  }

  /// 调试方法：清空所有数据
  void clearAllData() {
    print('清空所有推送数据');
    _pushData.clear();

    // 取消所有定时器
    for (final timer in _displayTimers.values) {
      timer.cancel();
    }
    _displayTimers.clear();
    _displayStartTime.clear();

    notifyListeners();
  }

  /// 移除推送数据
  void _removePushData(String personId, [String? recordType, int? displayTime]) {
    final removedData = _pushData.where((data) => _getPersonIdentifier(data) == personId).toList();
    if (removedData.isNotEmpty) {
      final data = removedData.first;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final startTime = _displayStartTime[personId] ?? currentTime;
      final actualDisplayTime = currentTime - startTime;
      
      // 获取过滤时间窗口
      _getFilterTimeWindowByRecordType(data.recordType).then((filterTime) {
        final keyInfo = data.recordType == kRecordTypeNormal 
            ? 'portraitId=${data.particular.portrait.portraitId ?? data.objectId}'
            : 'objectId=${data.objectId}';
        _logger.info(
          '[${data.objectId}] 🗑️🗑️🗑️ 移出人脸: personId=$personId ($keyInfo), recordType=${data.recordType}, 显示时长=${actualDisplayTime}ms, 过滤时间窗口=${filterTime}ms',
        );
      });
    }
    
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
    final normalFilterTime = await AppConfig.getNormalPersonFilterTimeWindow();

    print('开始清理过期过滤记录...');
    print('陌生人过滤时间窗口: ${strangerFilterTime}ms');
    print('白名单人员过滤时间窗口: ${normalFilterTime}ms');

    _lastPersonTime.forEach((personId, lastTime) {
      final timeDiff = currentTime - lastTime;
      
      // 从personId中提取recordType（格式：objectId_recordType）
      final parts = personId.split('_');
      final recordType = parts.length > 1 ? parts.last : kRecordTypeNormal;

      // 根据人员类型获取对应的过滤时间窗口
      int filterTimeWindow;
      if (recordType == kRecordTypeStranger) {
        filterTimeWindow = strangerFilterTime;
      } else if (recordType == kRecordTypeNormal) {
        filterTimeWindow = normalFilterTime;
      } else {
        // 如果无法确定类型，使用最长的过滤时间窗口（兼容旧数据）
        filterTimeWindow = [
          strangerFilterTime,
          normalFilterTime,
        ].reduce((a, b) => a > b ? a : b);
      }

      if (timeDiff > filterTimeWindow) {
        expiredKeys.add(personId);
        print(
          '发现过期记录: personId=$personId, recordType=$recordType, 时间差=${timeDiff}ms > ${filterTimeWindow}ms',
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
