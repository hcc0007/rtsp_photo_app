import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtsp_photo_app/models/push_data.dart';
import '../providers/push_provider.dart';
import '../services/push_server_service.dart';
import '../widgets/sense_image.dart';
import '../config/app_config.dart';
import 'package:logging/logging.dart';
import 'dart:async';

final _logger = Logger('PhotoGallery');

const String kRecordTypeStranger = 'portrait_stranger';
const String kRecordTypeNormal = 'portrait_normal';

class PhotoGallery extends StatefulWidget {
  const PhotoGallery({super.key});

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  // 调试模式，开发时可以设为 true
  static const bool _debugMode = false;

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
        _logger.info('[$ts] 原始数据: $newData');
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
            Provider.of<PushProvider>(
              context,
              listen: false,
            ).addPushData(pushData);
            _logger.info('[$ts] 已调用addPushData');
          } catch (e) {
            _logger.severe('[$ts] 调用addPushData时出错: $e');
          }
        }
      } catch (e) {
        // 静默处理解析错误，不显示错误界面，继续显示现有数据
        _logger.severe('[$ts] 人脸推送数据：解析失败 $e');
        _logger.severe('[$ts] 原始数据: $newData');

        // 调试模式下显示错误信息
        if (_debugMode && mounted) {
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.red[900]!, Colors.red[800]!, Colors.red[700]!],
        ),
      ),
      child: Consumer<PushProvider>(
        builder: (context, provider, child) {
          final pushDataList = provider.pushData;

          if (pushDataList.isEmpty) {
            return SizedBox();
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 白名单区域
                SizedBox(height: 170, child: _buildWhiteList(pushDataList)),

                const SizedBox(height: 8),

                // 陌生人区域
                SizedBox(height: 348, child: _buildStrangerList(pushDataList)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStrangerList(List<PushData> pushDataList) {
    return _buildPersonGrid(
      pushDataList.where((data) => data.recordType == kRecordTypeStranger).toList(),
    );
  }

  Widget _buildWhiteList(List<PushData> pushDataList) {
    return _buildPersonGrid(
      pushDataList.where((data) => data.recordType == kRecordTypeNormal).toList(),
    );
  }

  Widget _buildPersonGrid(List<PushData> dataList) {
    if (dataList.isEmpty) {
      return _buildEmptyDataList();
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 每行5个
        childAspectRatio: 0.8, // 宽高比
        crossAxisSpacing: 8, // 水平间距
        mainAxisSpacing: 8, // 垂直间距
      ),
      itemCount: dataList.length,
      itemBuilder: (context, index) {
        return FaceCard(pushData: dataList[index]);
      },
    );
  }

  Widget _buildEmptyDataList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            '暂无数据',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
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
    final imageUrl = pushData.portraitImage.url;
    final name = pushData.name;
    final recordType = pushData.recordType;

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
                margin: EdgeInsets.only(top: 10),
                // 网格布局样式（当前使用）
                width: MediaQuery.of(context).size.width / 7,
                height: MediaQuery.of(context).size.width / 7,
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
                  child: imageUrl.isNotEmpty
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
        return Colors.grey[600]!;
      case kRecordTypeNormal:
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
