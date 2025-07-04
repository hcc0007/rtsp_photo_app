import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/person_info.dart';

class PhotoProvider with ChangeNotifier {
  List<String> _photos = [];
  List<PersonInfo> _personInfos = [];
  bool _isLoading = false;
  String? _error;
  Timer? _timer;
  
  // 配置
  static const String apiUrl = 'https://your-api-endpoint.com/photos'; // 请替换为实际的API地址
  static const String personInfoApiUrl = 'https://your-api-endpoint.com/person-infos'; // 请替换为实际的人群信息API地址
  static const int refreshInterval = 5000; // 5秒刷新一次
  
  List<String> get photos => _photos;
  List<PersonInfo> get personInfos => _personInfos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  PhotoProvider() {
    _startPeriodicFetch();
  }
  
  void _startPeriodicFetch() {
    // 立即获取一次
    fetchPhotos();
    fetchPersonInfos();
    
    // 设置定时器，定期获取
    _timer = Timer.periodic(const Duration(milliseconds: refreshInterval), (timer) {
      fetchPhotos();
      fetchPersonInfos();
    });
  }
  
  // 获取模拟照片数据
  List<String> _getMockPhotos() {
    return [
      'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}',
      'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch + 1}',
      'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch + 2}',
      'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch + 3}',
      'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch + 4}',
      'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch + 5}',
    ];
  }

  // 获取模拟人群信息数据
  List<PersonInfo> _getMockPersonInfos() {
    final now = DateTime.now();
    return [
      PersonInfo.fromJson({
        "serialNumber": "f384eb7a-de91-4d41-bf43-dcfecc5b9b44",
        "objectId": "173a8b02-d866-11ed-e4b0-000105005879",
        "eventId": "",
        "dataType": "OBJECT_FACE",
        "recordType": "portrait_stranger",
        "platformType": "LOCAL",
        "portraitImage": {
          "url": "https://picsum.photos/80/100?random=1",
          "format": null
        },
        "panoramicImage": {
          "url": "https://picsum.photos/400/300?random=1",
          "format": null
        },
        "capturedTime": now.millisecondsSinceEpoch,
        "receivedTime": now.millisecondsSinceEpoch,
        "createTime": now.millisecondsSinceEpoch + 2000,
        "viewInfo": {
          "viewed": 0,
          "confirmed": 0,
          "username": null,
          "operateTime": null
        },
        "score": 0,
        "deviceInfo": {
          "device": {
            "identifierId": "0215185185988598050816",
            "deviceName": "车辆视频2",
            "deviceCode": "车辆视频",
            "platformIdentifierId": "118384891302982070272",
            "platformType": "LOCAL",
            "deviceType": "CAMERA",
            "position": "[890.1875,120]",
            "rtspAddress": "rtsp://10.151.3.74:9185/32012",
            "rtspDeputyAddress": ""
          },
          "deviceGroup": {
            "identifierId": "06123928025590149120",
            "name": "i18n.menu.default.device.group",
            "mapUrl": "OTHER/20230209-083455a9-2920480c905d-00000000-0000a660",
            "mapWidth": 450,
            "mapHeight": 300
          }
        },
        "taskInfo": {
          "task": {
            "taskId": "12023041120195052617",
            "taskName": "人员",
            "taskType": "portrait",
            "detectType": "portrait_tailing"
          },
          "roi": {
            "ruleId": "",
            "roiId": null,
            "roiNum": "",
            "roiName": "",
            "roiType": null,
            "extendJson": null,
            "verticeList": [
              {"x": 0, "y": 0},
              {"x": 1, "y": 0},
              {"x": 1, "y": 1},
              {"x": 0, "y": 1},
              {"x": 0, "y": 0}
            ]
          }
        },
        "stackeds": [
          {
            "width": 62,
            "top": 1040,
            "left": 721,
            "height": 40
          }
        ],
        "attrs": {
          "age_lower_limit": {"value": "35.0", "score": 1},
          "age_up_limit": {"value": "45.0", "score": 1},
          "gender_code": {"value": "MALE", "score": 0.99981314}
        },
        "particular": {
          "score": 0,
          "mask": "NONE",
          "helmet": "NONE",
          "associationId": "",
          "portraitDb": {
            "portraitDbId": 0,
            "identifierId": "",
            "libId": "",
            "libImportType": "",
            "featureDbId": "",
            "type": 0,
            "name": ""
          },
          "portrait": {
            "identifierId": null,
            "identity": null,
            "name": null,
            "gender": null,
            "phone": null,
            "company": null,
            "dept": null,
            "employeeNumber": null,
            "idNumber": null,
            "remark": null,
            "picUrl": null,
            "activationTime": null,
            "expirationTime": null,
            "activeState": null
          }
        },
        "biz": null,
        "applet": {
          "type": 1,
          "face": {
            "quality": 0.95155376,
            "rectangle": {
              "vertices": [
                {"x": 31, "y": 20},
                {"x": 93, "y": 60}
              ]
            },
            "track_id": 2977,
            "angle": {
              "yaw": -5.4852967,
              "pitch": 10.742178,
              "roll": -0.8645517
            },
            "landmarks": [],
            "attributes_with_score": {},
            "face_score": 0.6319155
          },
          "portrait_image_location": {
            "panoramic_image_size": {"width": 1920, "height": 1080},
            "portrait_image_in_panoramic": {"vertices": []},
            "portrait_in_panoramic": {"vertices": []}
          },
          "object_id": "173a8b02-d866-11ed-e4b0-000105005879"
        }
      }),
      PersonInfo.fromJson({
        "serialNumber": "f384eb7a-de91-4d41-bf43-dcfecc5b9b45",
        "objectId": "173a8b02-d866-11ed-e4b0-000105005880",
        "eventId": "",
        "dataType": "OBJECT_FACE",
        "recordType": "portrait_known",
        "platformType": "LOCAL",
        "portraitImage": {
          "url": "https://picsum.photos/80/100?random=2",
          "format": null
        },
        "panoramicImage": {
          "url": "https://picsum.photos/400/300?random=2",
          "format": null
        },
        "capturedTime": now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
        "receivedTime": now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
        "createTime": now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch + 2000,
        "viewInfo": {
          "viewed": 0,
          "confirmed": 0,
          "username": null,
          "operateTime": null
        },
        "score": 0,
        "deviceInfo": {
          "device": {
            "identifierId": "0215185185988598050816",
            "deviceName": "车辆视频2",
            "deviceCode": "车辆视频",
            "platformIdentifierId": "118384891302982070272",
            "platformType": "LOCAL",
            "deviceType": "CAMERA",
            "position": "[890.1875,120]",
            "rtspAddress": "rtsp://10.151.3.74:9185/32012",
            "rtspDeputyAddress": ""
          },
          "deviceGroup": {
            "identifierId": "06123928025590149120",
            "name": "i18n.menu.default.device.group",
            "mapUrl": "OTHER/20230209-083455a9-2920480c905d-00000000-0000a660",
            "mapWidth": 450,
            "mapHeight": 300
          }
        },
        "taskInfo": {
          "task": {
            "taskId": "12023041120195052617",
            "taskName": "人员",
            "taskType": "portrait",
            "detectType": "portrait_tailing"
          },
          "roi": {
            "ruleId": "",
            "roiId": null,
            "roiNum": "",
            "roiName": "",
            "roiType": null,
            "extendJson": null,
            "verticeList": [
              {"x": 0, "y": 0},
              {"x": 1, "y": 0},
              {"x": 1, "y": 1},
              {"x": 0, "y": 1},
              {"x": 0, "y": 0}
            ]
          }
        },
        "stackeds": [
          {
            "width": 62,
            "top": 1040,
            "left": 721,
            "height": 40
          }
        ],
        "attrs": {
          "age_lower_limit": {"value": "25.0", "score": 1},
          "age_up_limit": {"value": "35.0", "score": 1},
          "gender_code": {"value": "FEMALE", "score": 0.99981314}
        },
        "particular": {
          "score": 0,
          "mask": "NONE",
          "helmet": "NONE",
          "associationId": "",
          "portraitDb": {
            "portraitDbId": 0,
            "identifierId": "",
            "libId": "",
            "libImportType": "",
            "featureDbId": "",
            "type": 0,
            "name": ""
          },
          "portrait": {
            "identifierId": null,
            "identity": null,
            "name": null,
            "gender": null,
            "phone": null,
            "company": null,
            "dept": null,
            "employeeNumber": null,
            "idNumber": null,
            "remark": null,
            "picUrl": null,
            "activationTime": null,
            "expirationTime": null,
            "activeState": null
          }
        },
        "biz": null,
        "applet": {
          "type": 1,
          "face": {
            "quality": 0.95155376,
            "rectangle": {
              "vertices": [
                {"x": 31, "y": 20},
                {"x": 93, "y": 60}
              ]
            },
            "track_id": 2978,
            "angle": {
              "yaw": -5.4852967,
              "pitch": 10.742178,
              "roll": -0.8645517
            },
            "landmarks": [],
            "attributes_with_score": {},
            "face_score": 0.6319155
          },
          "portrait_image_location": {
            "panoramic_image_size": {"width": 1920, "height": 1080},
            "portrait_image_in_panoramic": {"vertices": []},
            "portrait_in_panoramic": {"vertices": []}
          },
          "object_id": "173a8b02-d866-11ed-e4b0-000105005880"
        }
      }),
      PersonInfo.fromJson({
        "serialNumber": "f384eb7a-de91-4d41-bf43-dcfecc5b9b46",
        "objectId": "173a8b02-d866-11ed-e4b0-000105005881",
        "eventId": "",
        "dataType": "OBJECT_FACE",
        "recordType": "portrait_stranger",
        "platformType": "LOCAL",
        "portraitImage": {
          "url": "https://picsum.photos/80/100?random=3",
          "format": null
        },
        "panoramicImage": {
          "url": "https://picsum.photos/400/300?random=3",
          "format": null
        },
        "capturedTime": now.subtract(const Duration(minutes: 15)).millisecondsSinceEpoch,
        "receivedTime": now.subtract(const Duration(minutes: 15)).millisecondsSinceEpoch,
        "createTime": now.subtract(const Duration(minutes: 15)).millisecondsSinceEpoch + 2000,
        "viewInfo": {
          "viewed": 0,
          "confirmed": 0,
          "username": null,
          "operateTime": null
        },
        "score": 0,
        "deviceInfo": {
          "device": {
            "identifierId": "0215185185988598050816",
            "deviceName": "车辆视频2",
            "deviceCode": "车辆视频",
            "platformIdentifierId": "118384891302982070272",
            "platformType": "LOCAL",
            "deviceType": "CAMERA",
            "position": "[890.1875,120]",
            "rtspAddress": "rtsp://10.151.3.74:9185/32012",
            "rtspDeputyAddress": ""
          },
          "deviceGroup": {
            "identifierId": "06123928025590149120",
            "name": "i18n.menu.default.device.group",
            "mapUrl": "OTHER/20230209-083455a9-2920480c905d-00000000-0000a660",
            "mapWidth": 450,
            "mapHeight": 300
          }
        },
        "taskInfo": {
          "task": {
            "taskId": "12023041120195052617",
            "taskName": "人员",
            "taskType": "portrait",
            "detectType": "portrait_tailing"
          },
          "roi": {
            "ruleId": "",
            "roiId": null,
            "roiNum": "",
            "roiName": "",
            "roiType": null,
            "extendJson": null,
            "verticeList": [
              {"x": 0, "y": 0},
              {"x": 1, "y": 0},
              {"x": 1, "y": 1},
              {"x": 0, "y": 1},
              {"x": 0, "y": 0}
            ]
          }
        },
        "stackeds": [
          {
            "width": 62,
            "top": 1040,
            "left": 721,
            "height": 40
          }
        ],
        "attrs": {
          "age_lower_limit": {"value": "40.0", "score": 1},
          "age_up_limit": {"value": "50.0", "score": 1},
          "gender_code": {"value": "MALE", "score": 0.99981314}
        },
        "particular": {
          "score": 0,
          "mask": "NONE",
          "helmet": "NONE",
          "associationId": "",
          "portraitDb": {
            "portraitDbId": 0,
            "identifierId": "",
            "libId": "",
            "libImportType": "",
            "featureDbId": "",
            "type": 0,
            "name": ""
          },
          "portrait": {
            "identifierId": null,
            "identity": null,
            "name": null,
            "gender": null,
            "phone": null,
            "company": null,
            "dept": null,
            "employeeNumber": null,
            "idNumber": null,
            "remark": null,
            "picUrl": null,
            "activationTime": null,
            "expirationTime": null,
            "activeState": null
          }
        },
        "biz": null,
        "applet": {
          "type": 1,
          "face": {
            "quality": 0.95155376,
            "rectangle": {
              "vertices": [
                {"x": 31, "y": 20},
                {"x": 93, "y": 60}
              ]
            },
            "track_id": 2979,
            "angle": {
              "yaw": -5.4852967,
              "pitch": 10.742178,
              "roll": -0.8645517
            },
            "landmarks": [],
            "attributes_with_score": {},
            "face_score": 0.6319155
          },
          "portrait_image_location": {
            "panoramic_image_size": {"width": 1920, "height": 1080},
            "portrait_image_in_panoramic": {"vertices": []},
            "portrait_in_panoramic": {"vertices": []}
          },
          "object_id": "173a8b02-d866-11ed-e4b0-000105005881"
        }
      }),
    ];
  }
  
  Future<void> fetchPhotos() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    // 如果使用mock数据，直接返回模拟数据
    if (AppConfig.showMockData) {
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟
      _photos = _getMockPhotos();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _photos = data.cast<String>();
        _error = null;
      } else {
        _error = '获取照片失败: ${response.statusCode}';
        // 如果API失败，使用模拟数据
        _photos = _getMockPhotos();
      }
    } catch (e) {
      _error = '网络错误: $e';
      // 如果网络错误，使用模拟数据
      _photos = _getMockPhotos();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPersonInfos() async {
    // 如果使用mock数据，直接返回模拟数据
    if (AppConfig.showMockData) {
      await Future.delayed(const Duration(milliseconds: 300)); // 模拟网络延迟
      _personInfos = _getMockPersonInfos();
      // 按capturedTime倒序排列，最新的在前面
      _personInfos.sort((a, b) => b.capturedTime.compareTo(a.capturedTime));
      notifyListeners();
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse(personInfoApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _personInfos = data.map((json) => PersonInfo.fromJson(json)).toList();
        // 按capturedTime倒序排列，最新的在前面
        _personInfos.sort((a, b) => b.capturedTime.compareTo(a.capturedTime));
      } else {
        // 如果API失败，使用模拟数据
        _personInfos = _getMockPersonInfos();
        // 按capturedTime倒序排列，最新的在前面
        _personInfos.sort((a, b) => b.capturedTime.compareTo(a.capturedTime));
      }
    } catch (e) {
      // 如果网络错误，使用模拟数据
      _personInfos = _getMockPersonInfos();
      // 按capturedTime倒序排列，最新的在前面
      _personInfos.sort((a, b) => b.capturedTime.compareTo(a.capturedTime));
    } finally {
      notifyListeners();
    }
  }
  
  void updateApiUrl(String newUrl) {
    // 这里可以添加更新API地址的逻辑
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 