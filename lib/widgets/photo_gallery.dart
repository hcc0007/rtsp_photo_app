import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtsp_photo_app/models/push_data.dart';
import '../providers/photo_provider.dart';
import '../models/person_info.dart';
import '../providers/push_provider.dart';
import '../services/push_server_service.dart';
import '../widgets/sense_image.dart';

class FaceCard extends StatelessWidget {
  final PushData pushData;
  const FaceCard({super.key, required this.pushData});

  @override
  Widget build(BuildContext context) {
    final imageUrl = pushData.imgUrl;
    final name = pushData.name;
    final recordType = pushData.recordType;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red[800], // 大红色背景
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 头像区域
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? SenseImage(objectKey: imageUrl, width: 80, height: 80)
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          
          // 姓名
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // 人脸类型标签
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRecordTypeColor(recordType),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              PersonInfo.getRecordTypeText(recordType),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // 时间信息
          Text(
            PersonInfo.formatTime(pushData.capturedTime),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRecordTypeColor(String recordType) {
    switch (recordType) {
      case 'portrait_stranger':
        return Colors.red[600]!;
      case 'portrait_known':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

class PhotoGallery extends StatefulWidget {
  const PhotoGallery({super.key});

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  @override
  Widget build(BuildContext context) {
    final pushProvider = Provider.of<PushProvider>(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red[900]!,
            Colors.red[800]!,
            Colors.red[700]!,
          ],
        ),
      ),
      child: StreamBuilder<Map<String, dynamic>>(
        stream: PushServerService.pushDataStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final newData = snapshot.data!;
            final pushData = PushData.fromJson(newData);
            bool exists = pushProvider.pushData.any(
              (item) =>
                  item.objectId == pushData.objectId &&
                  item.createTime == pushData.createTime,
            );
            if (!exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<PushProvider>(
                  context,
                  listen: false,
                ).addPushData(pushData);
              });
            }
          }

          final _pushDataList = pushProvider.pushData;

          if (_pushDataList.isEmpty) {
            return Container(
              height: double.infinity,
              width: double.infinity,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.face_retouching_off,
                      size: 64,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无人脸推送',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '等待人脸识别推送...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.face,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '人脸推送记录',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_pushDataList.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 人脸卡片列表
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _pushDataList
                          .map((face) => FaceCard(pushData: face))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red[900]!,
            Colors.red[800]!,
            Colors.red[700]!,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              '正在加载人群信息...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red[900]!,
            Colors.red[800]!,
            Colors.red[700]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Provider.of<PhotoProvider>(
                  context,
                  listen: false,
                ).fetchPersonInfos();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red[800],
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red[900]!,
            Colors.red[800]!,
            Colors.red[700]!,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text(
              '暂无人群信息',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
