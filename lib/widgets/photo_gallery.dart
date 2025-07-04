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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: PersonInfo.getRecordTypeColor(pushData.recordType),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircleAvatar(
              radius: 36,
              backgroundImage: imageUrl.isNotEmpty ? null : null,
              backgroundColor: Colors.grey[300],
              child: imageUrl.isEmpty
                  ? const Icon(Icons.person, size: 36, color: Colors.white)
                  : SenseImage(objectKey: imageUrl, width: 72, height: 72),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: PersonInfo.getRecordTypeTextColor(pushData.recordType),
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
    return StreamBuilder<Map<String, dynamic>>(
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
          return SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Center(
              child: Text('暂无人脸推送', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _pushDataList
                  .map((face) => FaceCard(pushData: face))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
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
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text('暂无人群信息', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
