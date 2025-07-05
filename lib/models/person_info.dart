import 'dart:ui';

import 'package:flutter/material.dart';

class PersonInfo {
  final String serialNumber;
  final String objectId;
  final String eventId;
  final String dataType;
  final String recordType;
  final String platformType;
  final PortraitImage portraitImage;
  final PanoramicImage panoramicImage;
  final int capturedTime;
  final int receivedTime;
  final int createTime;
  final ViewInfo viewInfo;
  final double score;
  final DeviceInfo deviceInfo;
  final TaskInfo taskInfo;
  final List<Stacked> stackeds;
  final Map<String, dynamic> attrs;
  final Particular particular;
  final dynamic biz;
  final Applet applet;

  PersonInfo({
    required this.serialNumber,
    required this.objectId,
    required this.eventId,
    required this.dataType,
    required this.recordType,
    required this.platformType,
    required this.portraitImage,
    required this.panoramicImage,
    required this.capturedTime,
    required this.receivedTime,
    required this.createTime,
    required this.viewInfo,
    required this.score,
    required this.deviceInfo,
    required this.taskInfo,
    required this.stackeds,
    required this.attrs,
    required this.particular,
    this.biz,
    required this.applet,
  });

  factory PersonInfo.fromJson(Map<String, dynamic> json) {
    return PersonInfo(
      serialNumber: json['serialNumber']?.toString() ?? '',
      objectId: json['objectId']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      dataType: json['dataType']?.toString() ?? '',
      recordType: json['recordType']?.toString() ?? '',
      platformType: json['platformType']?.toString() ?? '',
      portraitImage: PortraitImage.fromJson(json['portraitImage'] ?? {}),
      panoramicImage: PanoramicImage.fromJson(json['panoramicImage'] ?? {}),
      capturedTime: int.tryParse(json['capturedTime']?.toString() ?? '0') ?? 0,
      receivedTime: int.tryParse(json['receivedTime']?.toString() ?? '0') ?? 0,
      createTime: int.tryParse(json['createTime']?.toString() ?? '0') ?? 0,
      viewInfo: ViewInfo.fromJson(json['viewInfo'] ?? {}),
      score: double.tryParse(json['score']?.toString() ?? '0') ?? 0.0,
      deviceInfo: DeviceInfo.fromJson(json['deviceInfo'] ?? {}),
      taskInfo: TaskInfo.fromJson(json['taskInfo'] ?? {}),
      stackeds:
          (json['stackeds'] as List<dynamic>?)
              ?.map((e) => Stacked.fromJson(e))
              .toList() ??
          [],
      attrs: json['attrs'] ?? {},
      particular: Particular.fromJson(json['particular'] ?? {}),
      biz: json['biz'],
      applet: Applet.fromJson(json['applet'] ?? {}),
    );
  }

  static String getRecordTypeText(String recordType) {
    switch (recordType) {
      case 'portrait_stranger':
        return '陌生人';
      case 'portrait_known':
        return '已知人员';
      case 'portrait_normal':
        return '普通人员';
      default:
        return '未知';
    }
  }

  static Color getRecordTypeColor(String recordType) {
    switch (recordType) {
      case 'portrait_stranger':
        return Colors.grey;
      case 'portrait_known':
        return Colors.blue;
      case 'portrait_normal':
        return Colors.yellow;
      default:
        return Colors.white.withValues(alpha: 0.5);
    }
  }

  static Color getRecordTypeTextColor(String recordType) {
    switch (recordType) {
      case 'portrait_stranger':
        return Colors.white;
      case 'portrait_known':
        return Colors.white;
      case 'portrait_normal':
        return Colors.white;
      default:
        return Colors.black;
    }
  }

  static String getGenderText(String? genderCode) {
    switch (genderCode) {
      case 'MALE':
        return '男';
      case 'FEMALE':
        return '女';
      default:
        return '未知';
    }
  }

  static String getAgeText(Map<String, dynamic> attrs) {
    final ageLower = attrs['age_lower_limit']?['value'] as String?;
    final ageUpper = attrs['age_up_limit']?['value'] as String?;

    if (ageLower != null && ageUpper != null) {
      final lower = double.tryParse(ageLower)?.toInt();
      final upper = double.tryParse(ageUpper)?.toInt();
      if (lower != null && upper != null) {
        return '$lower-$upper岁';
      }
    }
    return '未知';
  }

  static String formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class PortraitImage {
  final String url;
  final String? format;

  PortraitImage({required this.url, this.format});

  factory PortraitImage.fromJson(Map<String, dynamic> json) {
    return PortraitImage(url: json['url'] ?? '', format: json['format']);
  }
}

class PanoramicImage {
  final String url;
  final String? format;

  PanoramicImage({required this.url, this.format});

  factory PanoramicImage.fromJson(Map<String, dynamic> json) {
    return PanoramicImage(url: json['url'] ?? '', format: json['format']);
  }
}

class ViewInfo {
  final int viewed;
  final int confirmed;
  final String? username;
  final String? operateTime;

  ViewInfo({
    required this.viewed,
    required this.confirmed,
    this.username,
    this.operateTime,
  });

  factory ViewInfo.fromJson(Map<String, dynamic> json) {
    return ViewInfo(
      viewed: json['viewed'] ?? 0,
      confirmed: json['confirmed'] ?? 0,
      username: json['username'],
      operateTime: json['operateTime'],
    );
  }
}

class DeviceInfo {
  final Device device;
  final DeviceGroup deviceGroup;

  DeviceInfo({required this.device, required this.deviceGroup});

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      device: Device.fromJson(json['device'] ?? {}),
      deviceGroup: DeviceGroup.fromJson(json['deviceGroup'] ?? {}),
    );
  }
}

class Device {
  final String identifierId;
  final String deviceName;
  final String deviceCode;
  final String platformIdentifierId;
  final String platformType;
  final String deviceType;
  final String position;
  final String rtspAddress;
  final String rtspDeputyAddress;

  Device({
    required this.identifierId,
    required this.deviceName,
    required this.deviceCode,
    required this.platformIdentifierId,
    required this.platformType,
    required this.deviceType,
    required this.position,
    required this.rtspAddress,
    required this.rtspDeputyAddress,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      identifierId: json['identifierId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? '',
      deviceCode: json['deviceCode']?.toString() ?? '',
      platformIdentifierId: json['platformIdentifierId']?.toString() ?? '',
      platformType: json['platformType']?.toString() ?? '',
      deviceType: json['deviceType']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      rtspAddress: json['rtspAddress']?.toString() ?? '',
      rtspDeputyAddress: json['rtspDeputyAddress']?.toString() ?? '',
    );
  }
}

class DeviceGroup {
  final String identifierId;
  final String name;
  final String mapUrl;
  final int mapWidth;
  final int mapHeight;

  DeviceGroup({
    required this.identifierId,
    required this.name,
    required this.mapUrl,
    required this.mapWidth,
    required this.mapHeight,
  });

  factory DeviceGroup.fromJson(Map<String, dynamic> json) {
    return DeviceGroup(
      identifierId: json['identifierId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mapUrl: json['mapUrl']?.toString() ?? '',
      mapWidth: int.tryParse(json['mapWidth']?.toString() ?? '0') ?? 0,
      mapHeight: int.tryParse(json['mapHeight']?.toString() ?? '0') ?? 0,
    );
  }
}

class TaskInfo {
  final Task task;
  final Roi roi;

  TaskInfo({required this.task, required this.roi});

  factory TaskInfo.fromJson(Map<String, dynamic> json) {
    return TaskInfo(
      task: Task.fromJson(json['task'] ?? {}),
      roi: Roi.fromJson(json['roi'] ?? {}),
    );
  }
}

class Task {
  final String taskId;
  final String taskName;
  final String taskType;
  final String detectType;

  Task({
    required this.taskId,
    required this.taskName,
    required this.taskType,
    required this.detectType,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId']?.toString() ?? '',
      taskName: json['taskName']?.toString() ?? '',
      taskType: json['taskType']?.toString() ?? '',
      detectType: json['detectType']?.toString() ?? '',
    );
  }
}

class Roi {
  final String ruleId;
  final String? roiId;
  final String roiNum;
  final String roiName;
  final String? roiType;
  final String? extendJson;
  final List<Map<String, int>> verticeList;

  Roi({
    required this.ruleId,
    this.roiId,
    required this.roiNum,
    required this.roiName,
    this.roiType,
    this.extendJson,
    required this.verticeList,
  });

  factory Roi.fromJson(Map<String, dynamic> json) {
    return Roi(
      ruleId: json['ruleId']?.toString() ?? '',
      roiId: json['roiId']?.toString(),
      roiNum: json['roiNum']?.toString() ?? '',
      roiName: json['roiName']?.toString() ?? '',
      roiType: json['roiType']?.toString(),
      extendJson: json['extendJson']?.toString(),
      verticeList:
          (json['verticeList'] as List<dynamic>?)
              ?.map(
                (e) => Map<String, dynamic>.from(e).map(
                  (k, v) => MapEntry(
                    k,
                    v is int ? v : int.tryParse(v.toString()) ?? 0,
                  ),
                ),
              )
              .toList() ??
          [],
    );
  }
}

class Stacked {
  final int width;
  final int top;
  final int left;
  final int height;

  Stacked({
    required this.width,
    required this.top,
    required this.left,
    required this.height,
  });

  factory Stacked.fromJson(Map<String, dynamic> json) {
    return Stacked(
      width: int.tryParse(json['width']?.toString() ?? '0') ?? 0,
      top: int.tryParse(json['top']?.toString() ?? '0') ?? 0,
      left: int.tryParse(json['left']?.toString() ?? '0') ?? 0,
      height: int.tryParse(json['height']?.toString() ?? '0') ?? 0,
    );
  }
}

class Particular {
  final double score;
  final String mask;
  final String helmet;
  final String associationId;
  final PortraitDb portraitDb;
  final Portrait portrait;

  Particular({
    required this.score,
    required this.mask,
    required this.helmet,
    required this.associationId,
    required this.portraitDb,
    required this.portrait,
  });

  factory Particular.fromJson(Map<String, dynamic> json) {
    return Particular(
      score: double.tryParse(json['score']?.toString() ?? '0') ?? 0.0,
      mask: json['mask']?.toString() ?? '',
      helmet: json['helmet']?.toString() ?? '',
      associationId: json['associationId']?.toString() ?? '',
      portraitDb: PortraitDb.fromJson(json['portraitDb'] ?? {}),
      portrait: Portrait.fromJson(json['portrait'] ?? {}),
    );
  }
}

class PortraitDb {
  final int portraitDbId;
  final String identifierId;
  final String libId;
  final String libImportType;
  final String featureDbId;
  final int type;
  final String name;
  final int enableState;
  final int activeState;
  final int activationTime;
  final int expirationTime;
  final int createTime;

  PortraitDb({
    required this.portraitDbId,
    required this.identifierId,
    required this.libId,
    required this.libImportType,
    required this.featureDbId,
    required this.type,
    required this.name,
    required this.enableState,
    required this.activeState,
    required this.activationTime,
    required this.expirationTime,
    required this.createTime,
  });

  factory PortraitDb.fromJson(Map<String, dynamic> json) {
    return PortraitDb(
      portraitDbId: int.tryParse(json['portraitDbId']?.toString() ?? '0') ?? 0,
      identifierId: json['identifierId'] ?? '',
      libId: json['libId'] ?? '',
      libImportType: json['libImportType'] ?? '',
      featureDbId: json['featureDbId'] ?? '',
      type: int.tryParse(json['type']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      enableState: int.tryParse(json['enableState']?.toString() ?? '0') ?? 0,
      activeState: int.tryParse(json['activeState']?.toString() ?? '0') ?? 0,
      activationTime:
          int.tryParse(json['activationTime']?.toString() ?? '0') ?? 0,
      expirationTime:
          int.tryParse(json['expirationTime']?.toString() ?? '0') ?? 0,
      createTime: int.tryParse(json['createTime']?.toString() ?? '0') ?? 0,
    );
  }
}

class Portrait {
  final int? portraitId;
  final String? identifierId;
  final String? identity;
  final String? name;
  final String? gender;
  final String? phone;
  final String? company;
  final String? dept;
  final String? employeeNumber;
  final String? idNumber;
  final String? remark;
  final String? picUrl;
  final String? activationTime;
  final String? expirationTime;
  final String? activeState;

  Portrait({
    this.portraitId,
    this.identifierId,
    this.identity,
    this.name,
    this.gender,
    this.phone,
    this.company,
    this.dept,
    this.employeeNumber,
    this.idNumber,
    this.remark,
    this.picUrl,
    this.activationTime,
    this.expirationTime,
    this.activeState,
  });

  factory Portrait.fromJson(Map<String, dynamic> json) {
    return Portrait(
      portraitId: json['portraitId'],
      identifierId: json['identifierId']?.toString(),
      identity: json['identity']?.toString(),
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      phone: json['phone']?.toString(),
      company: json['company']?.toString(),
      dept: json['dept']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      idNumber: json['idNumber']?.toString(),
      remark: json['remark']?.toString(),
      picUrl: json['picUrl']?.toString(),
      activationTime: json['activationTime']?.toString(),
      expirationTime: json['expirationTime']?.toString(),
      activeState: json['activeState']?.toString(),
    );
  }
}

class Applet {
  final int type;
  final Face face;
  final PortraitImageLocation portraitImageLocation;
  final String objectId;

  Applet({
    required this.type,
    required this.face,
    required this.portraitImageLocation,
    required this.objectId,
  });

  factory Applet.fromJson(Map<String, dynamic> json) {
    return Applet(
      type: json['type'] ?? 0,
      face: Face.fromJson(json['face'] ?? {}),
      portraitImageLocation: PortraitImageLocation.fromJson(
        json['portrait_image_location'] ?? {},
      ),
      objectId: json['object_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'face': face.toJson(),
      'portrait_image_location': portraitImageLocation.toJson(),
      'object_id': objectId,
    };
  }
}

class Face {
  final double quality;
  final Rectangle rectangle;
  final int trackId;
  final Angle angle;
  final List<Map<String, int>> landmarks;
  final Map<String, dynamic> attributesWithScore;
  final double faceScore;
  final String faceId;

  Face({
    required this.quality,
    required this.rectangle,
    required this.trackId,
    required this.angle,
    required this.landmarks,
    required this.attributesWithScore,
    required this.faceScore,
    required this.faceId,
  });

  factory Face.fromJson(Map<String, dynamic> json) {
    return Face(
      quality: (json['quality'] ?? 0).toDouble(),
      rectangle: Rectangle.fromJson(json['rectangle'] ?? {}),
      trackId: json['track_id'] ?? 0,
      angle: Angle.fromJson(json['angle'] ?? {}),
      landmarks:
          (json['landmarks'] as List<dynamic>?)
              ?.map(
                (e) => Map<String, dynamic>.from(e).map(
                  (k, v) => MapEntry(
                    k,
                    v is int ? v : int.tryParse(v.toString()) ?? 0,
                  ),
                ),
              )
              .toList() ??
          [],
      attributesWithScore: (json['attributes_with_score'] is Map
          ? (json['attributes_with_score'] as Map).cast<String, dynamic>()
          : {}),
      faceScore: (json['face_score'] ?? 0).toDouble(),
      faceId: json['faceId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality': quality,
      'rectangle': rectangle.toJson(),
      'track_id': trackId,
      'angle': angle.toJson(),
      'landmarks': landmarks,
      'attributes_with_score': attributesWithScore,
      'face_score': faceScore,
      'faceId': faceId,
    };
  }
}

class Rectangle {
  final List<Map<String, int>> vertices;

  Rectangle({required this.vertices});

  factory Rectangle.fromJson(Map<String, dynamic> json) {
    return Rectangle(
      vertices:
          (json['vertices'] as List<dynamic>?)
              ?.map(
                (e) => Map<String, dynamic>.from(e).map(
                  (k, v) => MapEntry(
                    k,
                    v is int ? v : int.tryParse(v.toString()) ?? 0,
                  ),
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'vertices': vertices};
  }
}

class Angle {
  final double yaw;
  final double pitch;
  final double roll;

  Angle({required this.yaw, required this.pitch, required this.roll});

  factory Angle.fromJson(Map<String, dynamic> json) {
    return Angle(
      yaw: (json['yaw'] ?? 0).toDouble(),
      pitch: (json['pitch'] ?? 0).toDouble(),
      roll: (json['roll'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'yaw': yaw, 'pitch': pitch, 'roll': roll};
  }
}

class PortraitImageLocation {
  final PanoramicImageSize panoramicImageSize;
  final PortraitImageInPanoramic portraitImageInPanoramic;
  final PortraitInPanoramic portraitInPanoramic;

  PortraitImageLocation({
    required this.panoramicImageSize,
    required this.portraitImageInPanoramic,
    required this.portraitInPanoramic,
  });

  factory PortraitImageLocation.fromJson(Map<String, dynamic> json) {
    return PortraitImageLocation(
      panoramicImageSize: PanoramicImageSize.fromJson(
        json['panoramic_image_size'] ?? {},
      ),
      portraitImageInPanoramic: PortraitImageInPanoramic.fromJson(
        json['portrait_image_in_panoramic'] ?? {},
      ),
      portraitInPanoramic: PortraitInPanoramic.fromJson(
        json['portrait_in_panoramic'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'panoramic_image_size': panoramicImageSize.toJson(),
      'portrait_image_in_panoramic': portraitImageInPanoramic.toJson(),
      'portrait_in_panoramic': portraitInPanoramic.toJson(),
    };
  }
}

class PanoramicImageSize {
  final int width;
  final int height;

  PanoramicImageSize({required this.width, required this.height});

  factory PanoramicImageSize.fromJson(Map<String, dynamic> json) {
    return PanoramicImageSize(
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height};
  }
}

class PortraitImageInPanoramic {
  final List<Map<String, int>> vertices;

  PortraitImageInPanoramic({required this.vertices});

  factory PortraitImageInPanoramic.fromJson(Map<String, dynamic> json) {
    return PortraitImageInPanoramic(
      vertices:
          (json['vertices'] as List<dynamic>?)
              ?.map(
                (e) => Map<String, dynamic>.from(e).map(
                  (k, v) => MapEntry(
                    k,
                    v is int ? v : int.tryParse(v.toString()) ?? 0,
                  ),
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'vertices': vertices};
  }
}

class PortraitInPanoramic {
  final List<Map<String, int>> vertices;

  PortraitInPanoramic({required this.vertices});

  factory PortraitInPanoramic.fromJson(Map<String, dynamic> json) {
    return PortraitInPanoramic(
      vertices:
          (json['vertices'] as List<dynamic>?)
              ?.map(
                (e) => Map<String, dynamic>.from(e).map(
                  (k, v) => MapEntry(
                    k,
                    v is int ? v : int.tryParse(v.toString()) ?? 0,
                  ),
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'vertices': vertices};
  }
}
