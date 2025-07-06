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
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 每行5个
        childAspectRatio: 0.7, // 宽高比
        crossAxisSpacing: 8, // 水平间距
        mainAxisSpacing: 8, // 垂直间距
      ),
      itemCount: dataList.length,
      itemBuilder: (context, index) {
        return FaceCard(pushData: dataList[index]);
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
    // 根据类型，展示不同图片
    final imageUrl = recordType == kRecordTypeNormal
        ? pushData.particular.portrait.picUrl
        : pushData.portraitImage.url;

    // 添加调试日志
    _logger.info(
      '[DEBUG] FaceCard构建: objectId=${pushData.objectId}, imageUrl=$imageUrl, name=$name, recordType=$recordType',
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
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? SenseImage(
                          objectKey: imageUrl,
                          id: 'objectId_${pushData.objectId}',
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
                          ),
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

                // TODO：准删除
                // child: Text(pushData.objectId),
                // TODO：注释不允许删除
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
