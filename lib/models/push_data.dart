import 'package:rtsp_photo_app/models/person_info.dart';

class PushData extends PersonInfo {
  final String imgUrl;
  final String name;

  PushData({
    required this.imgUrl,
    required this.name,
    required super.serialNumber,
    required super.objectId,
    required super.eventId,
    required super.dataType,
    required super.recordType,
    required super.platformType,
    required super.portraitImage,
    required super.panoramicImage,
    required super.capturedTime,
    required super.receivedTime,
    required super.createTime,
    required super.viewInfo,
    required super.score,
    required super.deviceInfo,
    required super.taskInfo,
    required super.stackeds,
    required super.attrs,
    required super.particular,
    required super.applet,
  });

  factory PushData.fromJson(Map<String, dynamic> json) {
    return PushData(
      imgUrl: json['imgUrl'] ?? '',
      name: json['name'] ?? '未知',
      serialNumber: json['serialNumber'] ?? '',
      objectId: json['objectId'] ?? '',
      eventId: json['eventId'] ?? '',
      dataType: json['dataType'] ?? '',
      recordType: json['recordType'] ?? '',
      platformType: json['platformType'] ?? '',
      portraitImage: PortraitImage(url: json['portraitImage']?['url'] ?? '', format: json['portraitImage']?['format']),
      panoramicImage: PanoramicImage(url: json['panoramicImage']?['url'] ?? '', format: json['panoramicImage']?['format']),
      capturedTime: json['capturedTime'] ?? 0,
      receivedTime: json['receivedTime'] ?? 0,
      createTime: json['createTime'] ?? 0,
      viewInfo: ViewInfo(
        viewed: json['viewInfo']?['viewed'] ?? 0,
        confirmed: json['viewInfo']?['confirmed'] ?? 0,
        username: json['viewInfo']?['username'],
        operateTime: json['viewInfo']?['operateTime'],
      ),
      score: (json['score'] ?? 0).toDouble(),
      deviceInfo: DeviceInfo(
        device: Device(
          identifierId: json['deviceInfo']?['device']?['identifierId'] ?? '',
          deviceName: json['deviceInfo']?['device']?['deviceName'] ?? '',
          deviceCode: json['deviceInfo']?['device']?['deviceCode'] ?? '',
          platformIdentifierId: json['deviceInfo']?['device']?['platformIdentifierId'] ?? '',
          platformType: json['deviceInfo']?['device']?['platformType'] ?? '',
          deviceType: json['deviceInfo']?['device']?['deviceType'] ?? '',
          position: json['deviceInfo']?['device']?['position'] ?? '',
          rtspAddress: json['deviceInfo']?['device']?['rtspAddress'] ?? '',
          rtspDeputyAddress: json['deviceInfo']?['device']?['rtspDeputyAddress'] ?? '',
        ),
        deviceGroup: DeviceGroup(
          identifierId: json['deviceInfo']?['deviceGroup']?['identifierId'] ?? '',
          name: json['deviceInfo']?['deviceGroup']?['name'] ?? '',
          mapUrl: json['deviceInfo']?['deviceGroup']?['mapUrl'] ?? '',
          mapWidth: json['deviceInfo']?['deviceGroup']?['mapWidth'] ?? 0,
          mapHeight: json['deviceInfo']?['deviceGroup']?['mapHeight'] ?? 0,
        ),
      ),
      taskInfo: TaskInfo(
        task: Task(
          taskId: json['taskInfo']?['task']?['taskId'] ?? '',
          taskName: json['taskInfo']?['task']?['taskName'] ?? '',
          taskType: json['taskInfo']?['task']?['taskType'] ?? '',
          detectType: json['taskInfo']?['task']?['detectType'] ?? '',
        ),
        roi: Roi(
          ruleId: json['taskInfo']?['roi']?['ruleId'] ?? '',
          roiId: json['taskInfo']?['roi']?['roiId'],
          roiNum: json['taskInfo']?['roi']?['roiNum'] ?? '',
          roiName: json['taskInfo']?['roi']?['roiName'] ?? '',
          roiType: json['taskInfo']?['roi']?['roiType'],
          extendJson: json['taskInfo']?['roi']?['extendJson'],
          verticeList: (json['taskInfo']?['roi']?['verticeList'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e).map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0)))
              .toList() ?? [],
        ),
      ),
      stackeds: (json['stackeds'] as List<dynamic>?)
          ?.map((e) => Stacked(
                width: e['width'] ?? 0,
                top: e['top'] ?? 0,
                left: e['left'] ?? 0,
                height: e['height'] ?? 0,
              ))
          .toList() ?? [],
      attrs: json['attrs'] ?? {},
      particular: Particular(
        score: (json['particular']?['score'] ?? 0).toDouble(),
        mask: json['particular']?['mask'] ?? '',
        helmet: json['particular']?['helmet'] ?? '',
        associationId: json['particular']?['associationId'] ?? '',
        portraitDb: PortraitDb(
          portraitDbId: json['particular']?['portraitDb']?['portraitDbId'] ?? 0,
          identifierId: json['particular']?['portraitDb']?['identifierId'] ?? '',
          libId: json['particular']?['portraitDb']?['libId'] ?? '',
          libImportType: json['particular']?['portraitDb']?['libImportType'] ?? '',
          featureDbId: json['particular']?['portraitDb']?['featureDbId'] ?? '',
          type: json['particular']?['portraitDb']?['type'] ?? 0,
          name: json['particular']?['portraitDb']?['name'] ?? '',
        ),
        portrait: Portrait(
          identifierId: json['particular']?['portrait']?['identifierId'],
          identity: json['particular']?['portrait']?['identity'],
          name: json['particular']?['portrait']?['name'],
          gender: json['particular']?['portrait']?['gender'],
          phone: json['particular']?['portrait']?['phone'],
          company: json['particular']?['portrait']?['company'],
          dept: json['particular']?['portrait']?['dept'],
          employeeNumber: json['particular']?['portrait']?['employeeNumber'],
          idNumber: json['particular']?['portrait']?['idNumber'],
          remark: json['particular']?['portrait']?['remark'],
          picUrl: json['particular']?['portrait']?['picUrl'],
          activationTime: json['particular']?['portrait']?['activationTime'],
          expirationTime: json['particular']?['portrait']?['expirationTime'],
          activeState: json['particular']?['portrait']?['activeState'],
        ),
      ),
      applet: Applet(
        type: json['applet']?['type'] ?? 0,
        face: Face(
          quality: (json['applet']?['face']?['quality'] ?? 0).toDouble(),
          rectangle: Rectangle(
                      vertices: (json['applet']?['face']?['rectangle']?['vertices'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e).map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0)))
              .toList() ?? [],
          ),
          trackId: json['applet']?['face']?['track_id'] ?? 0,
          angle: Angle(
            yaw: (json['applet']?['face']?['angle']?['yaw'] ?? 0).toDouble(),
            pitch: (json['applet']?['face']?['angle']?['pitch'] ?? 0).toDouble(),
            roll: (json['applet']?['face']?['angle']?['roll'] ?? 0).toDouble(),
          ),
          landmarks: (json['applet']?['face']?['landmarks'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e).map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0)))
              .toList() ?? [],
          attributesWithScore: (json['applet']?['face']?['attributes_with_score'] is Map
              ? (json['applet']?['face']?['attributes_with_score'] as Map).cast<String, dynamic>()
              : {}),
          faceScore: (json['applet']?['face']?['face_score'] ?? 0).toDouble(),
          faceId: json['applet']?['face']?['faceId'] ?? '',
        ),
        portraitImageLocation: PortraitImageLocation(
          panoramicImageSize: PanoramicImageSize(
            width: json['applet']?['portrait_image_location']?['panoramic_image_size']?['width'] ?? 0,
            height: json['applet']?['portrait_image_location']?['panoramic_image_size']?['height'] ?? 0,
          ),
          portraitImageInPanoramic: PortraitImageInPanoramic(
                      vertices: (json['applet']?['portrait_image_location']?['portrait_image_in_panoramic']?['vertices'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e).map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0)))
              .toList() ?? [],
          ),
          portraitInPanoramic: PortraitInPanoramic(
                      vertices: (json['applet']?['portrait_image_location']?['portrait_in_panoramic']?['vertices'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e).map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0)))
              .toList() ?? [],
          ),
        ),
        objectId: json['applet']?['object_id'] ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'imgUrl': imgUrl, 'name': name};
  }
}
