import 'package:rtsp_photo_app/models/person_info.dart';
import 'dart:convert';

class PushData extends PersonInfo {
  final String name;

  PushData({
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
    // 1. 兼容applet字段
    dynamic appletRaw = json['applet'];
    Map<String, dynamic>? appletMap;
    if (appletRaw is String) {
      try {
        appletMap = jsonDecode(appletRaw);
      } catch (e) {
        appletMap = {};
      }
    } else if (appletRaw is Map<String, dynamic>) {
      appletMap = appletRaw;
    } else {
      appletMap = {};
    }

    // 2. 兼容 attributes_with_score 字段
    Map<String, dynamic> attributesWithScore = {};
    if (appletMap != null &&
        appletMap['face'] != null &&
        appletMap['face'] is Map) {
      final faceMap = appletMap['face'] as Map;
      if (faceMap['attributes_with_score'] is Map) {
        (faceMap['attributes_with_score'] as Map).forEach((k, v) {
          attributesWithScore[k] = {...v, 'value': v['value']?.toString()};
        });
        faceMap['attributes_with_score'] = attributesWithScore;
      }
    }

    final recordType = json['recordType'] ?? '';
    String name = '';
    if (recordType == 'portrait_stranger') {
      name = '未知';
    } else {
      name =
          json['particular']?['portrait']?['name']?.toString() ??
          json['name']?.toString() ??
          '未知';
    }

    return PushData(
      name: name,
      serialNumber: json['serialNumber'] ?? '',
      objectId: json['objectId'] ?? '',
      eventId: json['eventId'] ?? '',
      dataType: json['dataType'] ?? '',
      recordType: json['recordType'] ?? '',
      platformType: json['platformType'] ?? '',
      portraitImage: PortraitImage(
        url: json['portraitImage']?['url'] ?? '',
        format: json['portraitImage']?['format'],
      ),
      panoramicImage: PanoramicImage(
        url: json['panoramicImage']?['url'] ?? '',
        format: json['panoramicImage']?['format'],
      ),
      capturedTime: int.tryParse(json['capturedTime']?.toString() ?? '0') ?? 0,
      receivedTime: int.tryParse(json['receivedTime']?.toString() ?? '0') ?? 0,
      createTime: int.tryParse(json['createTime']?.toString() ?? '0') ?? 0,
      viewInfo: ViewInfo(
        viewed:
            int.tryParse(json['viewInfo']?['viewed']?.toString() ?? '0') ?? 0,
        confirmed:
            int.tryParse(json['viewInfo']?['confirmed']?.toString() ?? '0') ??
            0,
        username: json['viewInfo']?['username']?.toString(),
        operateTime: json['viewInfo']?['operateTime']?.toString(),
      ),
      score: (json['score'] ?? 0).toDouble(),
      deviceInfo: DeviceInfo(
        device: Device(
          identifierId: json['deviceInfo']?['device']?['identifierId'] ?? '',
          deviceName: json['deviceInfo']?['device']?['deviceName'] ?? '',
          deviceCode: json['deviceInfo']?['device']?['deviceCode'] ?? '',
          platformIdentifierId:
              json['deviceInfo']?['device']?['platformIdentifierId'] ?? '',
          platformType: json['deviceInfo']?['device']?['platformType'] ?? '',
          deviceType: json['deviceInfo']?['device']?['deviceType'] ?? '',
          position: json['deviceInfo']?['device']?['position'] ?? '',
          rtspAddress: json['deviceInfo']?['device']?['rtspAddress'] ?? '',
          rtspDeputyAddress:
              json['deviceInfo']?['device']?['rtspDeputyAddress'] ?? '',
        ),
        deviceGroup: DeviceGroup(
          identifierId:
              json['deviceInfo']?['deviceGroup']?['identifierId']?.toString() ??
              '',
          name: json['deviceInfo']?['deviceGroup']?['name']?.toString() ?? '',
          mapUrl:
              json['deviceInfo']?['deviceGroup']?['mapUrl']?.toString() ?? '',
          mapWidth:
              int.tryParse(
                json['deviceInfo']?['deviceGroup']?['mapWidth']?.toString() ??
                    '0',
              ) ??
              0,
          mapHeight:
              int.tryParse(
                json['deviceInfo']?['deviceGroup']?['mapHeight']?.toString() ??
                    '0',
              ) ??
              0,
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
          verticeList:
              (json['taskInfo']?['roi']?['verticeList'] as List<dynamic>?)
                  ?.map(
                    (e) {
                      if (e is Map) {
                        return Map<String, dynamic>.from(e).map(
                          (k, v) => MapEntry(
                            k,
                            v is int ? v : int.tryParse(v.toString()) ?? 0,
                          ),
                        );
                      }
                      return <String, int>{};
                    },
                  )
                  .toList() ??
              [],
        ),
      ),
      stackeds:
          (json['stackeds'] as List<dynamic>?)
              ?.map(
                (e) => Stacked(
                  width: int.tryParse(e?['width']?.toString() ?? '0') ?? 0,
                  top: int.tryParse(e?['top']?.toString() ?? '0') ?? 0,
                  left: int.tryParse(e?['left']?.toString() ?? '0') ?? 0,
                  height: int.tryParse(e?['height']?.toString() ?? '0') ?? 0,
                ),
              )
              .toList() ??
          [],
      attrs: json['attrs'] ?? {},
      particular: Particular(
        score: (json['particular']?['score'] ?? 0).toDouble(),
        mask: json['particular']?['mask'] ?? '',
        helmet: json['particular']?['helmet'] ?? '',
        associationId: json['particular']?['associationId'] ?? '',
        portraitDb: PortraitDb(
          portraitDbId:
              int.tryParse(
                json['particular']?['portraitDb']?['portraitDbId']
                        ?.toString() ??
                    '0',
              ) ??
              0,
          identifierId:
              json['particular']?['portraitDb']?['identifierId']?.toString() ??
              '',
          libId: json['particular']?['portraitDb']?['libId']?.toString() ?? '',
          libImportType:
              json['particular']?['portraitDb']?['libImportType']?.toString() ??
              '',
          featureDbId:
              json['particular']?['portraitDb']?['featureDbId']?.toString() ??
              '',
          type:
              int.tryParse(
                json['particular']?['portraitDb']?['type']?.toString() ?? '0',
              ) ??
              0,
          name: json['particular']?['portraitDb']?['name']?.toString() ?? '',
          enableState:
              int.tryParse(
                json['particular']?['portraitDb']?['enableState']?.toString() ??
                    '0',
              ) ??
              0,
          activeState:
              int.tryParse(
                json['particular']?['portraitDb']?['activeState']?.toString() ??
                    '0',
              ) ??
              0,
          activationTime:
              int.tryParse(
                json['particular']?['portraitDb']?['activationTime']
                        ?.toString() ??
                    '0',
              ) ??
              0,
          expirationTime:
              int.tryParse(
                json['particular']?['portraitDb']?['expirationTime']
                        ?.toString() ??
                    '0',
              ) ??
              0,
          createTime:
              int.tryParse(
                json['particular']?['portraitDb']?['createTime']?.toString() ??
                    '0',
              ) ??
              0,
        ),
        portrait: Portrait(
          portraitId: int.tryParse(
            json['particular']?['portrait']?['portraitId']?.toString() ?? '0',
          ),
          identifierId: json['particular']?['portrait']?['identifierId']
              ?.toString(),
          identity: json['particular']?['portrait']?['identity']?.toString(),
          name: json['particular']?['portrait']?['name']?.toString(),
          gender: json['particular']?['portrait']?['gender']?.toString(),
          phone: json['particular']?['portrait']?['phone']?.toString(),
          company: json['particular']?['portrait']?['company']?.toString(),
          dept: json['particular']?['portrait']?['dept']?.toString(),
          employeeNumber: json['particular']?['portrait']?['employeeNumber']
              ?.toString(),
          idNumber: json['particular']?['portrait']?['idNumber']?.toString(),
          remark: json['particular']?['portrait']?['remark']?.toString(),
          picUrl: json['particular']?['portrait']?['picUrl']?.toString(),
          activationTime: json['particular']?['portrait']?['activationTime']
              ?.toString(),
          expirationTime: json['particular']?['portrait']?['expirationTime']
              ?.toString(),
          activeState: json['particular']?['portrait']?['activeState']
              ?.toString(),
        ),
      ),
      applet: Applet(
        type: appletMap?['type'] ?? 0,
        face: Face(
          quality: (appletMap?['face']?['quality'] ?? 0).toDouble(),
          rectangle: Rectangle(
            vertices:
                (appletMap?['face']?['rectangle']?['vertices']
                        as List<dynamic>?)
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
          ),
          trackId: appletMap?['face']?['track_id'] ?? 0,
          angle: Angle(
            yaw: (appletMap?['face']?['angle']?['yaw'] ?? 0).toDouble(),
            pitch: (appletMap?['face']?['pitch'] ?? 0).toDouble(),
            roll: (appletMap?['face']?['roll'] ?? 0).toDouble(),
          ),
          landmarks:
              (appletMap?['face']?['landmarks'] as List<dynamic>?)
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
          attributesWithScore: attributesWithScore,
          faceScore: (appletMap?['face']?['face_score'] ?? 0).toDouble(),
          faceId: appletMap?['face']?['faceId'] ?? '',
        ),
        portraitImageLocation: PortraitImageLocation(
          panoramicImageSize: PanoramicImageSize(
            width:
                appletMap?['portrait_image_location']?['panoramic_image_size']?['width'] ??
                0,
            height:
                appletMap?['portrait_image_location']?['panoramic_image_size']?['height'] ??
                0,
          ),
          portraitImageInPanoramic: PortraitImageInPanoramic(
            vertices:
                (appletMap?['portrait_image_location']?['portrait_image_in_panoramic']?['vertices']
                        as List<dynamic>?)
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
          ),
          portraitInPanoramic: PortraitInPanoramic(
            vertices:
                (appletMap?['portrait_image_location']?['portrait_in_panoramic']?['vertices']
                        as List<dynamic>?)
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
          ),
        ),
        objectId: appletMap?['object_id'] ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {};
  }
}
