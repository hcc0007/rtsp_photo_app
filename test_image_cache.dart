import 'dart:io';
import 'dart:convert';

void main() async {
  print('开始测试图片缓存逻辑...');
  
  // 模拟两个不同的objectId使用相同图片URL的情况
  final testData1 = {
    'objectId': 'test_object_001',
    'createTime': DateTime.now().millisecondsSinceEpoch,
    'recordType': 'portrait_stranger',
    'name': 'Test Stranger 1',
    'serialNumber': 'test_serial_001',
    'eventId': 'test_event_001',
    'dataType': 'portrait',
    'platformType': 'test_platform',
    'portraitImage': {
      'url': 'video_face_cropped/test_image_001',
      'format': 'jpeg'
    },
    'panoramicImage': {
      'url': 'video_face_panoramic/test_panoramic_001',
      'format': 'jpeg'
    },
    'capturedTime': DateTime.now().millisecondsSinceEpoch,
    'receivedTime': DateTime.now().millisecondsSinceEpoch,
    'viewInfo': {
      'viewed': 0,
      'confirmed': 0,
      'username': null,
      'operateTime': null
    },
    'score': 0.95,
    'deviceInfo': {
      'device': {
        'identifierId': 'test_device_001',
        'deviceName': 'Test Device',
        'deviceCode': 'TEST001',
        'platformIdentifierId': 'test_platform_001',
        'platformType': 'test',
        'deviceType': 'camera',
        'position': 'Test Position',
        'rtspAddress': 'rtsp://test.com/stream',
        'rtspDeputyAddress': null
      },
      'deviceGroup': {
        'identifierId': 'test_group_001',
        'name': 'Test Device Group',
        'mapUrl': null,
        'mapWidth': 0,
        'mapHeight': 0
      }
    },
    'taskInfo': {
      'task': {
        'taskId': 'test_task_001',
        'taskName': 'Test Task',
        'taskType': 'portrait',
        'detectType': 'portrait_detect'
      },
      'roi': {
        'ruleId': 'test_rule_001',
        'roiId': null,
        'roiNum': '',
        'roiName': '',
        'roiType': null,
        'extendJson': null,
        'verticeList': []
      }
    },
    'stackeds': [],
    'attrs': {},
    'particular': {
      'score': 0.95,
      'mask': '',
      'helmet': '',
      'associationId': '',
      'portraitDb': {
        'portraitDbId': 0,
        'identifierId': '',
        'libId': '',
        'libImportType': '',
        'featureDbId': '',
        'type': 0,
        'name': '',
        'enableState': 0,
        'activeState': 0,
        'activationTime': 0,
        'expirationTime': 0,
        'createTime': 0
      },
      'portrait': {
        'portraitId': null,
        'identifierId': null,
        'identity': null,
        'name': null,
        'gender': null,
        'phone': null,
        'company': null,
        'dept': null,
        'employeeNumber': null,
        'idNumber': null,
        'remark': null,
        'picUrl': null,
        'activationTime': null,
        'expirationTime': null,
        'activeState': null
      }
    },
    'applet': {
      'face': {
        'faceId': 'test_face_001',
        'attributes_with_score': {}
      }
    }
  };

  final testData2 = {
    'objectId': 'test_object_002',
    'createTime': DateTime.now().millisecondsSinceEpoch,
    'recordType': 'portrait_stranger',
    'name': 'Test Stranger 2',
    'serialNumber': 'test_serial_002',
    'eventId': 'test_event_002',
    'dataType': 'portrait',
    'platformType': 'test_platform',
    'portraitImage': {
      'url': 'video_face_cropped/test_image_002', // 不同的图片URL
      'format': 'jpeg'
    },
    'panoramicImage': {
      'url': 'video_face_panoramic/test_panoramic_002',
      'format': 'jpeg'
    },
    'capturedTime': DateTime.now().millisecondsSinceEpoch,
    'receivedTime': DateTime.now().millisecondsSinceEpoch,
    'viewInfo': {
      'viewed': 0,
      'confirmed': 0,
      'username': null,
      'operateTime': null
    },
    'score': 0.85,
    'deviceInfo': {
      'device': {
        'identifierId': 'test_device_002',
        'deviceName': 'Test Device 2',
        'deviceCode': 'TEST002',
        'platformIdentifierId': 'test_platform_002',
        'platformType': 'test',
        'deviceType': 'camera',
        'position': 'Test Position 2',
        'rtspAddress': 'rtsp://test.com/stream2',
        'rtspDeputyAddress': null
      },
      'deviceGroup': {
        'identifierId': 'test_group_002',
        'name': 'Test Device Group 2',
        'mapUrl': null,
        'mapWidth': 0,
        'mapHeight': 0
      }
    },
    'taskInfo': {
      'task': {
        'taskId': 'test_task_002',
        'taskName': 'Test Task 2',
        'taskType': 'portrait',
        'detectType': 'portrait_detect'
      },
      'roi': {
        'ruleId': 'test_rule_002',
        'roiId': null,
        'roiNum': '',
        'roiName': '',
        'roiType': null,
        'extendJson': null,
        'verticeList': []
      }
    },
    'stackeds': [],
    'attrs': {},
    'particular': {
      'score': 0.85,
      'mask': '',
      'helmet': '',
      'associationId': '',
      'portraitDb': {
        'portraitDbId': 0,
        'identifierId': '',
        'libId': '',
        'libImportType': '',
        'featureDbId': '',
        'type': 0,
        'name': '',
        'enableState': 0,
        'activeState': 0,
        'activationTime': 0,
        'expirationTime': 0,
        'createTime': 0
      },
      'portrait': {
        'portraitId': null,
        'identifierId': null,
        'identity': null,
        'name': null,
        'gender': null,
        'phone': null,
        'company': null,
        'dept': null,
        'employeeNumber': null,
        'idNumber': null,
        'remark': null,
        'picUrl': null,
        'activationTime': null,
        'expirationTime': null,
        'activeState': null
      }
    },
    'applet': {
      'face': {
        'faceId': 'test_face_002',
        'attributes_with_score': {}
      }
    }
  };

  try {
    // 发送第一个测试数据
    print('发送第一个测试数据: ${testData1['objectId']}');
    await _sendTestData(testData1);
    
    // 等待一秒
    await Future.delayed(Duration(seconds: 1));
    
    // 发送第二个测试数据
    print('发送第二个测试数据: ${testData2['objectId']}');
    await _sendTestData(testData2);
    
    print('✅ 测试数据发送完成');
    print('请检查应用日志，确认：');
    print('1. 两个不同的objectId是否正确解析');
    print('2. 两个不同的图片URL是否正确加载');
    print('3. SenseImage组件是否正确处理缓存');
    
  } catch (e) {
    print('❌ 发送测试数据时出错: $e');
  }
  
  print('测试完成');
}

Future<void> _sendTestData(Map<String, dynamic> testData) async {
  final client = HttpClient();
  final request = await client.postUrl(Uri.parse('http://localhost:8080/front/push'));
  request.headers.set('Content-Type', 'application/json; charset=utf-8');
  request.write(utf8.encode(jsonEncode(testData)));
  
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  
  print('响应状态码: ${response.statusCode}');
  print('响应内容: $responseBody');
  
  if (response.statusCode == 200) {
    print('✅ 测试数据发送成功');
  } else {
    print('❌ 测试数据发送失败');
  }
  
  client.close();
} 