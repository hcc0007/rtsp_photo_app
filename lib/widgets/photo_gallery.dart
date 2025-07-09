import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtsp_photo_app/models/push_data.dart';
import '../providers/push_provider.dart';
import '../services/push_server_service.dart';
import '../widgets/sense_image.dart';
import 'package:logging/logging.dart';
import 'dart:async';

final _logger = Logger('PhotoGallery');

const String kRecordTypeStranger = 'portrait_stranger';
const String kRecordTypeNormal = 'portrait_normal';

class PhotoGallery extends StatefulWidget {
  static bool debugMode = false;
  const PhotoGallery({super.key});

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  // 推送数据流订阅
  StreamSubscription<Map<String, dynamic>>? _pushDataSubscription;

  // 记录上一次的数据，用于精确检测变化
  List<String> _lastDataIds = [];

  @override
  void initState() {
    super.initState();

    // 监听推送数据流
    _pushDataSubscription = PushServerService.pushDataStream.listen((newData) {
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      try {
        _logger.info('[$ts] 人脸推送数据： 开始解析🔍');
        _logger.info('[$ts] 原始数据: ${jsonEncode(newData)}');
        final pushData = PushData.fromJson(newData);
        _logger.info('[$ts] 人脸推送数据： 解析成功🏅');
        _logger.info(
          '[$ts] 解析后数据: objectId=${pushData.objectId}, faceId=${pushData.applet.face.faceId}, recordType=${pushData.recordType}',
        );

        // 直接添加到PushProvider，让过滤逻辑处理重复检查
        if (mounted) {
          _logger.info(
            '[$ts] 准备添加到PushProvider: objectId=${pushData.objectId}',
          );
          try {
            // 调试模式：临时禁用过滤
            if (PhotoGallery.debugMode) {
              Provider.of<PushProvider>(
                context,
                listen: false,
              ).addPushDataWithoutFilter(pushData);
              _logger.info('[$ts] 已调用addPushDataWithoutFilter（调试模式）');
            } else {
              Provider.of<PushProvider>(
                context,
                listen: false,
              ).addPushData(pushData);
              _logger.info('[$ts] 已调用addPushData');
            }
          } catch (e) {
            _logger.severe('[$ts] 调用addPushData时出错: $e');
          }
        }
      } catch (e) {
        // 静默处理解析错误，不显示错误界面，继续显示现有数据
        _logger.severe('[$ts] 人脸推送数据：解析失败 $e');
        _logger.severe('[$ts] 原始数据: $newData');

        // 调试模式下显示错误信息
        if (PhotoGallery.debugMode && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('数据解析失败: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pushDataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildWrapper(context);
  }

  Widget _buildWrapper(BuildContext context) {
    return Consumer<PushProvider>(
      builder: (context, provider, child) {
        final pushDataList = provider.pushData;

        // 检测数据变化并触发动画
        _handleDataChange(pushDataList);

        // 调试模式：显示调试信息
        if (PhotoGallery.debugMode) {
          final debugInfo = provider.getDebugInfo();
          print('=== 调试信息 ===');
          print('推送数据数量: ${debugInfo['pushDataCount']}');
          print('过滤记录数量: ${debugInfo['filterRecordCount']}');
          print('人员类型记录数量: ${debugInfo['personRecordTypesCount']}');
          print('显示定时器数量: ${debugInfo['displayTimersCount']}');
          print('是否运行中: ${debugInfo['isRunning']}');
          print('当前用户ID: ${debugInfo['currentUserId']}');
          print('错误信息: ${debugInfo['error']}');
          print('================');
        }

        if (pushDataList.isEmpty) {
          return PhotoGallery.debugMode
              ? _buildDebugEmptyState(provider)
              : SizedBox();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 调试模式：显示调试按钮
              if (PhotoGallery.debugMode) _buildDebugControls(provider),

              // 白名单区域
              Expanded(flex: 1, child: _buildWhiteList(pushDataList)),

              const SizedBox(height: 8),

              // 陌生人区域
              Expanded(flex: 1, child: _buildStrangerList(pushDataList)),
            ],
          ),
        );
      },
    );
  }

  void _handleDataChange(List<PushData> currentData) {
    final currentIds = currentData.map((data) => data.objectId).toList();
    _lastDataIds = List.from(currentIds);
  }

  Widget _buildDebugEmptyState(PushProvider provider) {
    final debugInfo = provider.getDebugInfo();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bug_report,
            size: 48,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            '调试模式 - 暂无数据',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '推送数据数量: ${debugInfo['pushDataCount']}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          Text(
            '过滤记录数量: ${debugInfo['filterRecordCount']}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          Text(
            '人员类型记录数量: ${debugInfo['personRecordTypesCount']}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          Text(
            '是否运行中: ${debugInfo['isRunning']}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          if (debugInfo['error'] != null)
            Text(
              '错误: ${debugInfo['error']}',
              style: TextStyle(color: Colors.red.withValues(alpha: 0.8)),
            ),
          const SizedBox(height: 16),
          _buildDebugControls(provider),
        ],
      ),
    );
  }

  Widget _buildDebugControls(PushProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              provider.clearAllFilters();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('已清空过滤记录')));
            },
            child: Text('清空过滤'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearAllData();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('已清空所有数据')));
            },
            child: Text('清空数据'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final debugInfo = provider.getDebugInfo();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '数据: ${debugInfo['pushDataCount']}, 过滤: ${debugInfo['filterRecordCount']}, 类型: ${debugInfo['personRecordTypesCount']}',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text('状态'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrangerList(List<PushData> pushDataList) {
    return _buildPersonGrid(
      pushDataList
          .where((data) => data.recordType == kRecordTypeStranger)
          .toList(),
    );
  }

  Widget _buildWhiteList(List<PushData> pushDataList) {
    return _buildPersonGrid(
      pushDataList
          .where((data) => data.recordType == kRecordTypeNormal)
          .toList(),
    );
  }

  Widget _buildPersonGrid(List<PushData> dataList) {
    return StableGridView(dataList: dataList);
  }
}

class StableGridView extends StatefulWidget {
  final List<PushData> dataList;

  const StableGridView({super.key, required this.dataList});

  @override
  State<StableGridView> createState() => _StableGridViewState();
}

class _StableGridViewState extends State<StableGridView>
    with TickerProviderStateMixin {
  // 当前显示的数据（包括正在动画的）
  final List<PushData> _displayData = [];
  // 动画控制器映射
  final Map<String, AnimationController?> _animationControllers = {};
  // 动画状态映射
  final Map<String, bool> _isAnimating = {};
  // 等待插入的队列
  final List<PushData> _pendingData = [];
  // 最大显示条数（5行 x 5列 = 25个）
  static const int maxDisplayCount = 5;

  @override
  void initState() {
    super.initState();
    _updateData();
  }

  @override
  void didUpdateWidget(StableGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateData();
  }

  void _updateData() {
    final currentIds = _displayData.map((data) => data.objectId).toList();
    final newIds = widget.dataList.map((data) => data.objectId).toList();

    // 检测新数据
    final newData = widget.dataList
        .where((data) => !currentIds.contains(data.objectId))
        .toList();

    // 检测要移除的数据
    final toRemoveIds = currentIds.where((id) => !newIds.contains(id)).toList();

    print('=== 数据更新 ===');
    print('当前显示: $currentIds');
    print('新数据: ${newData.map((e) => e.objectId).toList()}');
    print('要移除: $toRemoveIds');
    print('等待队列: ${_pendingData.map((e) => e.objectId).toList()}');

    // 处理要移除的数据：先创建退出动画
    for (final objectId in toRemoveIds) {
      // 确保只对没有在动画中的数据创建退出动画
      if (!_isAnimating.containsKey(objectId) || !_isAnimating[objectId]!) {
        _createExitAnimation(objectId);
      }
    }

    // 如果有数据要移除，为所有其他数据创建向左移动动画
    if (toRemoveIds.isNotEmpty) {
      for (final data in _displayData) {
        final objectId = data.objectId;
        // 不为要移除的数据创建移动动画
        if (!toRemoveIds.contains(objectId) &&
            (!_isAnimating.containsKey(objectId) || !_isAnimating[objectId]!)) {
          _createShiftAnimation(objectId);
        }
      }
    }

    // 处理新数据：检查是否可以插入
    for (final data in newData) {
      if (_displayData.length < maxDisplayCount) {
        // 可以直接插入
        _displayData.add(data);
        if (!_isAnimating.containsKey(data.objectId) ||
            !_isAnimating[data.objectId]!) {
          _createEnterAnimation(data.objectId);
        }
      } else {
        // 添加到等待队列
        if (!_pendingData.any((d) => d.objectId == data.objectId)) {
          _pendingData.add(data);
          print('数据 ${data.objectId} 添加到等待队列');
        }
      }
    }

    setState(() {});
  }

  void _createShiftAnimation(String objectId) {
    print('创建向左移动动画: $objectId');

    final controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animationControllers[objectId] = controller;
    _isAnimating[objectId] = true;

    // 启动向左移动动画
    controller.forward().then((_) {
      // 动画完成后，清理控制器
      if (mounted) {
        _isAnimating[objectId] = false;
        _animationControllers[objectId] = null;
        print('向左移动动画完成: $objectId');
        setState(() {});
      }
    });

    setState(() {});
  }

  void _processPendingData() {
    // 检查等待队列，如果有数据且当前显示数量小于最大数量，则插入
    while (_pendingData.isNotEmpty && _displayData.length < maxDisplayCount) {
      final data = _pendingData.removeAt(0);
      _displayData.add(data);
      print('从等待队列插入数据: ${data.objectId}');

      if (!_isAnimating.containsKey(data.objectId) ||
          !_isAnimating[data.objectId]!) {
        _createEnterAnimation(data.objectId);
      }
    }
  }

  void _createEnterAnimation(String objectId) {
    print('创建进入动画: $objectId');

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animationControllers[objectId] = controller;
    _isAnimating[objectId] = true;

    // 启动进入动画
    controller.forward().then((_) {
      // 动画完成后，保持控制器，不清理
      if (mounted) {
        _isAnimating[objectId] = false;
        print('进入动画完成: $objectId');
        setState(() {});
      }
    });

    setState(() {});
  }

  void _createExitAnimation(String objectId) {
    print('创建退出动画: $objectId');

    final controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animationControllers[objectId] = controller;
    _isAnimating[objectId] = true;

    // 启动退出动画
    controller.forward().then((_) {
      print('退出动画完成: $objectId，开始移除数据');
      // 动画完成后移除数据
      _displayData.removeWhere((data) => data.objectId == objectId);
      _animationControllers.remove(objectId);
      _isAnimating.remove(objectId);

      // 检查等待队列，如果有数据且当前显示数量小于最大数量，则插入
      _processPendingData();

      setState(() {});
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _displayData.length,
      itemBuilder: (context, index) {
        final data = _displayData[index];
        final objectId = data.objectId;
        final controller = _animationControllers[objectId];
        final isEntering = widget.dataList.any((d) => d.objectId == objectId);

        return AnimatedFaceCard(
          pushData: data,
          animationController: controller,
          isEntering: isEntering,
        );
      },
    );
  }

  @override
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller?.dispose();
    }
    _animationControllers.clear();
    super.dispose();
  }
}

class AnimatedFaceCard extends StatelessWidget {
  final PushData pushData;
  final AnimationController? animationController;
  final bool isEntering;

  const AnimatedFaceCard({
    super.key,
    required this.pushData,
    this.animationController,
    required this.isEntering,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        double slideOffset;
        double opacity;

        if (isEntering) {
          // 进入动画：从右侧滑入 + 淡入
          // 从右侧30%位置开始，滑动到原位置(0)
          slideOffset =
              (1.0 - (animationController?.value ?? 1.0)) *
              0.3; // 从右侧30%位置滑入到原位置
          // 透明度在300ms内完成，500ms总时长，所以300/500=0.6
          final value = animationController?.value ?? 1.0;
          opacity = value < 0.6
              ? value /
                    0.6 // 前60%的时间完成透明度动画
              : 1.0; // 之后保持不透明
        } else if (animationController != null &&
            animationController!.value > 0) {
          // 向左移动动画：向左移动一个网格位置
          slideOffset = -(animationController!.value) * 0.2; // 向左移动20%的屏幕宽度
          opacity = 1.0; // 保持不透明
        } else {
          // 退出动画：向左滑出 + 淡出
          slideOffset = -(animationController?.value ?? 0.0) * 0.3; // 向左滑出30%
          opacity = 1.0 - (animationController?.value ?? 0.0); // 从1到0，逐渐变透明
        }

        return Transform.translate(
          offset: Offset(slideOffset * MediaQuery.of(context).size.width, 0),
          child: Opacity(
            opacity: opacity,
            child: FaceCard(pushData: pushData),
          ),
        );
      },
    );
  }
}

class FaceCard extends StatelessWidget {
  final PushData pushData;
  const FaceCard({super.key, required this.pushData});

  @override
  Widget build(BuildContext context) {
    return FaceCardWithDynamicColor(pushData: pushData);
  }
}

class FaceCardWithDynamicColor extends StatelessWidget {
  final PushData pushData;
  const FaceCardWithDynamicColor({super.key, required this.pushData});

  @override
  Widget build(BuildContext context) {
    final name = pushData.name;
    final recordType = pushData.recordType;

    // 优化调试日志 - 详细显示图片URL来源信息
    final avatarShow = pushData.particular.portrait.avatarShow;
    final portraitImageUrl = pushData.portraitImage.url;

    // 根据类型，展示不同图片
    final imageUrl = recordType == kRecordTypeNormal
        ? avatarShow
        : portraitImageUrl;

    _logger.info(
      '[${pushData.objectId}] FaceCard构建: objectId=${pushData.objectId}, recordType=$recordType, name=$name',
    );
    _logger.info(
      '[${pushData.objectId}] 图片URL详情: 最终使用=$imageUrl, avatarShow=$avatarShow, portraitImageUrl=$portraitImageUrl',
    );

    return FutureBuilder<Color>(
      future: _getRecordTypeColor(recordType),
      builder: (context, snapshot) {
        final color = snapshot.data ?? Colors.grey[600]!;

        return Container(
          // 网格布局样式（当前使用）
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 头像区域
              Container(
                margin: EdgeInsets.only(top: 30),
                // 网格布局样式（当前使用）
                width: MediaQuery.of(context).size.width / 6,
                height: MediaQuery.of(context).size.width / 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SenseImage(
                    objectKey: imageUrl ?? '',
                    id: 'objectId_${pushData.objectId}',
                  ),
                ),
              ),

              // 姓名
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                    topRight: Radius.circular(10),
                    topLeft: Radius.circular(10),
                  ),
                  color: Colors.white,
                ),
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: MediaQuery.of(context).size.width / 40,
                    fontWeight: FontWeight.w300,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Color> _getRecordTypeColor(String recordType) async {
    switch (recordType) {
      case kRecordTypeStranger:
        return Colors.grey[400]!;
      case kRecordTypeNormal:
        return Colors.blue[400]!;
      default:
        return Colors.grey[400]!;
    }
  }
}
